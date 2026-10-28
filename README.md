# godot-mobile-template

Project: godot-mobile-template  
Godot: 4.7.2  
Language: GDScript  
Targets: Android / iOS  
Template Version: 0.3.0

모바일 게임을 만들 때 쓰는 **시작용 프로젝트**다.
저장, 소리, 화면 이동 기능이 들어 있다. `game/` 폴더에 게임을 만들면 된다.

Android 실행과 Mock 연습 기능을 제공한다. Android 네이티브 GPGS·결제·AdMob·UMP도 고정 버전으로 연결했다.
실제 검증 범위와 남은 스토어 계정 검사는 [검증 기록](docs/template/VALIDATION.md)을 따른다. iOS 네이티브 바이너리는 미설치다.

## 1. 먼저 실행해 보기

1. [Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/)를 설치한다. **Standard 버전**을 선택한다.
2. 이 프로젝트 폴더를 컴퓨터에 준비한다. ZIP으로 받았다면 압축을 푼다.
3. Godot를 열고 **Import**를 누른 뒤, 폴더 안의 `project.godot`를 선택한다.
4. 프로젝트가 열리면 오른쪽 위 **▶ 실행 버튼** 또는 **F5**를 누른다.

`MOBILE TEMPLATE` 화면이 나오면 성공이다.

## 2. 버튼을 눌러 확인하기

화면 아래쪽 버튼은 스크롤하면 보인다.
**Mock은 실제 광고를 보거나 돈을 내지 않고 연습하는 기능**이다.

| 해 볼 것 | 누를 버튼 | 성공하면 |
| --- | --- | --- |
| 저장하고 읽기 | `Save Test` → `Load Test` | 같은 저장값이 보인다 |
| 소리 듣기 | `Play BGM`, `Play SFX` | 소리가 난다 |
| 광고 연습 | `Grant Mock Consent` → `Show Mock Rewarded Ad` | `rewarded_completed`가 나온다 |
| 구매 연습 | `Mock Purchase Success` | `purchase_completed`가 나온다 |
| 취소·오류 연습 | `Mock Purchase Cancel`, `Mock Purchase Error` | `purchase_cancelled`, `purchase_failed`가 각각 나온다 |
| 구매 복원 연습 | 구매 성공 후 `Restore Mock Purchases` | `1 item(s)`가 나온다 |
| 화면 바꾸기 | `Scene Transition` | 다른 화면으로 이동한다 |
| 게임 서비스 로그인 연습 | `Game Services Sign In` | `authenticate`와 `mock: true`가 나온다 |
| 업적·점수 연습 | 로그인 후 `Unlock Demo Achievement`, `Submit Demo Score` | 각 요청의 Mock 완료 결과가 나온다 |
| 업적·리더보드 화면 요청 연습 | 로그인 후 `Show Achievements`, `Show Leaderboard` | `ui_status: requested`가 나온다. 실제 스토어 화면은 열리지 않는다 |

복원 연습은 앱을 끄지 않은 상태에서 진행한다. 실제 구매 내역은 아니다.

## 3. 내 게임 만들기

1. 새 게임 폴더를 준비한다. 어떤 파일을 가져오고 어디에 출처를 적는지는 [템플릿 적용 절차](docs/template/APPLYING.md)를 따른다. AI에게 맡길 때도 이 문서를 따르게 한다.
2. Godot에서 **Scene → New Scene → 2D Scene**을 선택하고 `game/main.tscn`으로 저장한다.
3. [config/game.cfg](config/game.cfg)를 텍스트 편집기로 연다. 기존 `[app]` 안에서 다음 값만 바꾼다.

```ini
name="내 첫 게임"
main_scene="res://game/main.tscn"
orientation="portrait"
```

`portrait`는 세로, `landscape`는 가로, `sensor`는 휴대폰을 돌리는 방향이다.

4. 이름과 방향을 적용한다. **Mac에서는 프로젝트 폴더에서 터미널을 열고** 아래 명령을 실행한다.

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tools/configure.gd
```

명령이 어렵다면 AI에게 **“config/game.cfg의 설정을 프로젝트에 반영해 줘”**라고 요청해도 된다.

5. 프로젝트를 다시 열고 **F5**를 누른다. 이제 `game/main.tscn`이 열린다. 처음에는 빈 화면이 정상이다. 이 장면부터 게임을 만든다.

게임 파일은 `game/`, 게임 설정은 `config/`에 둔다. 저장 데이터 구조(버전·변환)가 필요해지면 [game/README.md](game/README.md)의 초기화 script 예시를 따른다. 공통 기능을 고칠 때는 [코드 안내서](docs/CODEBASE_MAP.md)를 참고한다.

## 4. 휴대폰에서 실행하기

**Android:** [Android 준비 방법](docs/DEVELOPMENT.md#android-setup)을 따라 필요한 도구를 설치한다. 휴대폰에서 **USB 디버깅**을 켜고 컴퓨터에 연결한 뒤, Godot의 Android 실행 버튼을 누른다.

휴대폰에서도 광고·결제를 연습하려면 `config/game.cfg`의 기존 `[services]` 값을 아래처럼 맞추고 **Debug 빌드(개발용 앱)**로 설치한다.

```ini
[services]
mode="mock"
allow_mobile_debug_mocks=true
```

**iPhone:** Mac과 Xcode가 필요하다. [iPhone 준비 방법](docs/DEVELOPMENT.md#ios-setup)을 따라 설정한다.

Android 결제·AdMob·UMP는 설치돼 있으며 별도 Gradle preset에서 SDK를 포함한다.
기본값은 Mock이고, 네이티브 사용은 기능별 mode·검증 gate·게임별 설정이 필요하다.
[Android 결제·광고 안내](docs/ANDROID_SERVICES.md)에서 설정과 구매 검증 계약을 확인한다.
Google Play Games / Game Center는 공통 API와 Mock, 플랫폼 Adapter 연결 코드가 있다.
Android Play Games v3.4.0 플러그인을 설치했고 Android 16에서 Debug·Release 로딩을 확인했다.
실제 계정·업적·리더보드는 Play Console 설정 후 검증해야 한다. iOS 플러그인은 아직 미설치다.
[게임 서비스 안내](docs/GAME_SERVICES.md)에서 설정과 네이티브 통합 요건을 확인한다.

## 잘 안 될 때

| 문제 | 먼저 해 볼 것 |
| --- | --- |
| 광고 실패 | `Grant Mock Consent`를 먼저 누른다 |
| 휴대폰에서 `Unavailable` 표시 | 위의 Mock 설정을 확인하고 Debug 빌드로 다시 설치한다 |
| 소리가 나지 않음 | 휴대폰·컴퓨터 음량과 데모 아래쪽 Volume 설정을 확인한다 |
| 새 게임 대신 데모 실행 | `main_scene` 경로와 파일 저장 여부를 확인한다 |
| 앱 내보내기 실패 | [Android](docs/DEVELOPMENT.md#android-setup) 또는 [iPhone](docs/DEVELOPMENT.md#ios-setup) 준비 방법을 확인한다 |

## Dependency BOM

사용 중인 도구의 버전이다. 버전은 자동으로 바꾸지 않는다.

| 구성 | 버전 |
| --- | --- |
| Godot / 내장 GDScript | 4.7.2 |
| 이 템플릿 | 0.3.0 ([변경 기록](docs/template/CHANGELOG.md)) |
| Android 결제 플러그인 | [GodotGooglePlayBilling 3.3.0](https://github.com/godot-sdk-integrations/godot-google-play-billing/releases/tag/3.3.0), MIT; Google Billing `9.1.0`; Gradle export opt-in, 스토어 구매 미검증 |
| Android 광고 플러그인 | [Poing AdMob 5.1.0](https://github.com/poingstudios/godot-admob-plugin/releases/tag/v5.1.0), MIT; Google Next-Gen Ads `1.4.0`, UMP `4.0.0`, ConstraintLayout `2.2.0` (Apache-2.0); Gradle export opt-in |
| 게임 서비스 Service / Mock / Adapter | 템플릿 내 GDScript 구현, 실제 계정 기능 미검증 |
| Android Play Games plugin | [v3.4.0](https://github.com/godot-sdk-integrations/godot-play-game-services/releases/tag/v3.4.0), MIT; 4.7.2 Debug·Release 기기 로딩 통과, 계정 미검증 |
| Android native SDK | Google `play-services-games-v2:22.1.0` ([약관](https://developers.google.com/terms)), `gson:2.14.0` (Apache-2.0); Gradle export opt-in |
| iOS Game Center | 바이너리 미설치; [고정 소스·호환성 기록](docs/DEPENDENCIES.md#게임-서비스-최초-도입-기록--2026-10-01) |

간접 의존성의 정확한 해결 버전은 [Android Gradle graph](docs/ANDROID_SERVICES_DEPENDENCIES.txt)에 기록한다.
Billing SDK가 요구하는 Kotlin runtime은 `2.2.10`(Apache-2.0)으로 해결됐고, 기준 template의 Kotlin Gradle plugin `2.1.21`은 유지한다.

## 더 자세히 보기

- [개발 상세 안내](docs/DEVELOPMENT.md): 설정, 코드 사용 예제, Android·iPhone 빌드 방법
- [게임 서비스 안내](docs/GAME_SERVICES.md): 로그인·업적·리더보드 API, Mock 및 네이티브 연결 요건
- [Android Play Games 설정](docs/ANDROID_PLAY_GAMES.md): Gradle 진단 빌드, Console ID·OAuth·테스터, 실기기 검증 절차
- [Android 결제·광고·동의](docs/ANDROID_SERVICES.md): 고정 SDK, 로컬 설정, 구매 수신·검증·완료 계약, 샘플 광고 진단
- [도구·라이선스 기록](docs/DEPENDENCIES.md): 정확한 버전과 사용 조건
- [템플릿 적용 절차](docs/template/APPLYING.md): 새 게임에 가져오기, 출처 기록, 버전 업데이트
- [변경 기록](docs/template/CHANGELOG.md): 템플릿 버전별 변경 내용
- [검증 기록](docs/template/VALIDATION.md): 어디까지 확인했는지
- [AI 작업 규칙](AGENTS.md) · [코드 안내서](docs/CODEBASE_MAP.md) · [설계 설명](docs/ARCHITECTURE.md)
