# 게임 서비스 — 로그인·업적·리더보드

게임은 `App.initialize()` 이후 `App.game_services`만 사용한다. 네이티브 플러그인에 직접 접근하지 않는다.
현재 공통 Service, Desktop/모바일 Debug Mock, Android/iOS Adapter 연결 코드가 있다.
**Android v3.4.0 AAR가 설치됐고 Godot 4.7.2 Debug/Release 기기 로딩을 확인했다.
실제 Google/Apple 계정 연결은 미검증이며 iOS 바이너리는 미설치다.**

## 사용

결과 신호를 먼저 연결한다. `OK`는 서비스가 요청을 받아 Adapter에 전달했다는 뜻이다.
SDK의 즉시 오류도 신호로 전달될 수 있으므로 반환값만으로 성공을 판단하지 않는다.

```gdscript
func _ready() -> void:
	App.game_services.request_completed.connect(_on_game_services_completed)
	App.game_services.request_failed.connect(_on_game_services_failed)

func sign_in() -> void:
	App.game_services.authenticate()

func _on_game_services_completed(operation: String, details: Dictionary) -> void:
	print(operation, details)
	if operation == "authenticate":
		App.game_services.submit_score("MY_SCORE", 100)

func _on_game_services_failed(operation: String, reason: String) -> void:
	print(operation, reason)
```

| 메서드 | 의미 |
| --- | --- |
| `authenticate() -> Error` | 사용자 요청에 따라 로그인 |
| `is_authenticated() -> bool` | 현재 Adapter가 확인한 인증 상태 |
| `submit_score(leaderboard_id: String, score: int) -> Error` | 논리 리더보드 ID에 점수 제출 |
| `unlock_achievement(achievement_id: String) -> Error` | 일반 업적 완료; iOS는 진행률 100% 제출 |
| `show_leaderboard(leaderboard_id: String) -> Error` | 지정 리더보드 화면 요청 |
| `show_achievements() -> Error` | 업적 화면 요청 |
| `set_mock_result(result: String)` | Debug Mock에서 `success`, `cancel`, `error` 선택 |

`request_completed(operation: String, details: Dictionary)`에 `logical_id`가 포함된다.
Mock 결과에는 반드시 `mock=true`가 포함되며 실제 계정/점수/업적이 아니다.
`request_failed(operation: String, reason: String)`은 `disabled`, `unavailable`, `busy`,
`not_authenticated`, `invalid_id`, `unconfigured_id`, `cancelled`, `authentication_failed`,
`mock_error`, `native_error` / `native_error:<코드>`, `score_out_of_range`, `timeout` 등을 전달한다.
요청 거절은 반환 Error와 실패 신호로 알리고, 완료/실패 신호 안에서 다음 요청을 시작할 수 있다.

## 설정과 논리 ID

`config/game.cfg`의 `features/game_services_enabled`와 기존 `services/mode`를 사용한다.
App은 활성 기능에서 `GameConfig.use_mocks()`가 허용한 Debug 환경에만 Mock을 선택한다.
release에서는 Mock을 선택하지 않으며 Mock Adapter 자체에도 release 차단이 있다.
각 플랫폼 ID는 `[game_services]`에 설정한다. 게임의 업적 규칙·보상·저장 schema는 `game/` 소유다.

```ini
[game_services]
android_game_id=""
android_mode="inherit"
android_native_verified=false
ios_native_verified=false
timeout_seconds=120.0
leaderboard_ids={"MY_SCORE": {"android": "", "ios": ""}}
achievement_ids={"MY_WIN": {"android": "", "ios": ""}}
```

키는 게임이 사용하는 논리 ID, `android`/`ios` 값은 플랫폼 콘솔의 ID다.
정의하지 않은 키는 `invalid_id`, 네이티브 ID가 비어 있으면 `unconfigured_id`다.
Mock은 등록된 논리 ID로 동작하며 플랫폼 ID가 비어 있어도 연습할 수 있다.
데모 키 `DEMO_SCORE`, `DEMO_FIRST_WIN`은 실제 스토어 ID가 아니다.

## 네이티브 선택과 남은 작업

네이티브 요청은 `mode="native"`와 해당 플랫폼의 `*_native_verified=true`가 모두 필요하다.
Android는 `android_mode="native"`로 게임 서비스만 native를 선택할 수 있다. `inherit`는 공통 mode를 따른다.
플래그는 초기화 gate일 뿐 검증 증거가 아니다. 현재 값은 양쪽 모두 false다.
후속 통합 검증용 로컬 빌드에서만 해당 gate를 열고, 검증 기록이 완료되기 전에는 배포 설정에서 열지 않는다.
SDK가 없거나 API가 다르면 Adapter는 unavailable을 유지한다. Desktop native mode도 unavailable이다.
기능 off일 때는 플러그인 검색/초기화를 수행하지 않는다.

### Android

- 대상: [Godot Play Game Services v3.4.0](https://github.com/godot-sdk-integrations/godot-play-game-services/releases/tag/v3.4.0).
- `AndroidGameServicesAdapter`는 `GodotPlayGameServices` native singleton을 직접 감싼다.
  게임 코드와 별도 관리자에서 플러그인의 GDScript singleton을 호출하지 않는다.
- 실제 메서드 `initialize`, `signIn`, `isAuthenticated`, `submitScore`, `unlockAchievement`,
  `showLeaderboard`, `showAchievements`와 `userAuthenticated`, `scoreSubmitted`, `achievementUnlocked` 신호를 사용한다.
- 네이티브 요청 전 `isAuthenticated`의 비동기 결과를 재확인한다. 실패 시 게임이 다시 로그인을 요청한다.
- `addons/play_game_services/`에 고정 AAR와 MIT 고지를 보존했다. upstream GDScript autoload를 추가하지 않는다.
  Android export의 `game_services/include_sdk`는 기본 false이며 Gradle 빌드에서만 true로 선택한다.
- Godot 4.7.2 JNI singleton 메서드는 `has_java_method()`로 확인한다.
  일반 `Object.has_method()`는 Java 메서드를 보고하지 않아 사용할 수 없다.
  [고정 엔진 구현](https://github.com/godotengine/godot/blob/4.7.2-stable/platform/android/api/jni_singleton.cpp).
- Game ID는 `config/game_services.local.cfg`의 `android_game_id`에 설정한다.
  exporter가 whitelist 설정을 `game_services.build.cfg`로 주입하고 Android APP_ID 리소스를 만든다.
  두 파일은 Git에서 제외되며 local 원본은 APK에서 제외한다. 공개 ID는 최종 APK에는 포함된다.
  Game ID가 비어 있거나 유효한 양의 정수가 아니면 Adapter가 SDK initialize를 호출하지 않는다.
- OAuth의 package name/서명 SHA-1/테스터 설정 및 Play App Signing 인증서를 확인한다.
  구체적인 재현·설정 절차는 [ANDROID_PLAY_GAMES.md](ANDROID_PLAY_GAMES.md)를 따른다.
- 네이티브 UI 메서드는 표시/실패/닫힘 콜백이 없다. 완료 결과의 `ui_status="requested"`는 호출 전달만 의미한다.
  화면이 표시되거나 닫혔다고 해석하지 않는다.

### iOS

- 대상: [기존 Godot iOS Plugins의 GameCenter 소스](https://github.com/godot-sdk-integrations/godot-ios-plugins/tree/caafb2c7fbfb5c72a64f163c76449274fa49abaa/plugins/gamecenter).
- `IOSGameServicesAdapter`는 `GameCenter` singleton의 `authenticate`, `post_score`,
  `award_achievement`, `show_game_center` 및 pending event queue를 사용한다.
- Godot **4.7.2-stable** 헤더로 release/debug xcframework를 빌드하고
  `res://ios/plugins/`에 `.gdip`와 바이너리를 배치한 뒤 iOS export plugin을 활성화한다.
  엔진 3.x용 바이너리를 사용하지 않는다. App Store Connect 업적/리더보드와 Game Center entitlement/signing이 필요하다.
- SDK 화면의 닫힘 이벤트를 받은 경우 `ui_status="closed"`를 반환한다. 업적 보상 여부와 관계없다.
- 고정 소스의 `post_score`는 점수를 float32로 변환한다. 정밀도 손실 방지를 위해 현재 Adapter는
  **-16,777,216 ~ 16,777,216** 밖의 정수를 `score_out_of_range`로 거절한다.
  더 큰 점수가 필요하면 upstream int64 변환 수정과 재빌드를 먼저 검증한다.
- 이 Adapter는 **GodotApplePlugins API용이 아니다**. iOS 17+ 및 매치메이킹이 필요하면 별도 Adapter 계약으로 조사한다.

## 동시 요청과 타임아웃

서비스와 Adapter는 한 번에 한 요청을 처리한다. 기본 제한 시간은 120초다.
완료 전에 중복 요청하면 `busy`다. Service는 요청 ID가 다른 콜백과 중복 완료를 무시한다.
타임아웃 시 게임에는 `timeout`을 전달한다. 취소할 수 없는 네이티브 작업은 기존 콜백이 도착할 때까지
Adapter 잠금을 유지한다. 그 콜백은 성공으로 전달하지 않고 잠금만 해제한다.
콜백이 영원히 도착하지 않으면 같은 앱 세션에서 해당 Adapter의 다음 요청도 `busy`이며 앱 재시작이 필요하다.
이는 ID 없는 기존 OS 콜백을 새 요청의 성공으로 잘못 처리하지 않기 위한 제한이다.

현재 범위에 클라우드 저장, Android 증분 업적, 서버 인증 토큰, 플레이어 프로필, 매치메이킹은 포함되지 않는다.
화면 표시 요청의 연속 실행은 upstream Android UI 상태를 확인할 수 없어 이 계약으로 제어하지 않는다.
업적 완료 콜백에서 게임 보상을 지급한다면 중복 지급 정책과 저장은 게임이 구현한다.

## 검증

`tests/integration.tscn`은 Mock과 가짜 SDK를 이용해 API 매핑, 오류, 로그인 gate, 중복 요청,
타임아웃/늦은 콜백, 데모 버튼을 검사한다. `--disabled`, `--native`도 실행한다.
실제 결과와 export/device 한계는 [VALIDATION.md](template/VALIDATION.md)에 기록한다.
Android 네이티브 로딩용 `pgs_probe` feature는 bootstrap을 별도 진단 장면으로 연결한다.
다음 단계는 Play Console 설정 후 등록한 테스트 계정으로 로그인·점수·업적·화면 동작을 확인하는 것이다.
