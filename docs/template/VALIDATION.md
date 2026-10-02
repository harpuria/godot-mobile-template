# Validation — 2026-09-16

## 템플릿 적용성 개선 0.2.0 — 2026-10-02 Agent 검증

Linux x86_64 cloud container, Godot `4.7.2.stable.official.ed1daf0bf`(공식 Linux 빌드)에서 headless로 검사했다.
문서의 검증 명령을 그대로 실행했다. Desktop 검사이며 export·기기 검증은 하지 않았다.

| 검사 | 실제 결과 |
| --- | --- |
| 변경 전 기준 headless 통합 / `--disabled` / `--native` | 103 / 13 / 13 checks, 0 failures, exit 0 |
| Editor import | exit 0, script/parse error 없음 |
| 최종 headless 통합 | **109 checks, 0 failures**, exit 0, `ERROR`·`SCRIPT ERROR`·`Parse Error` 로그 0줄 |
| 최종 `--disabled` / `--native` | **13 / 13 checks, 0 failures**, exit 0 |
| bootstrap 실제 실행(임시 `game/` hook, 확인 후 삭제) | hook이 `App.ready_for_game=false` 상태에서 호출되고 `schema_version` 설정 반영 |
| bootstrap 실제 실행(없는 hook 경로) | `Game init script failed (File not found)` 오류 기록 후 초기화 계속 |
| 문서 상대 링크 검사 | 깨진 링크 0 |

추가된 6개 검사: 설정된 hook 실행, 빈 경로 생략, hook 1회 호출, 없는 파일·Node script·hook 메서드 없는 script 거절.
`tools/configure.gd` 실행 시 `export_presets.cfg`에 `runnable=true`가 추가되고 `project.godot` 섹션 순서가 바뀌는 기존 차이를 확인했다.
이번 변경 범위가 아니므로 해당 결과는 commit하지 않았다.
`v0.2.0` 태그는 기본 브랜치 merge 후 생성해야 하며 이 검증 시점에는 없다.

## Android Play Games 네이티브 후속 검증 — 2026-10-01

사용자 요청으로 v3.4.0 debug/release AAR를 연결하고 USB Android 기기에서 직접 검사했다.
**네이티브 바이너리의 export·등록·미설정 경로는 통과했다. Google 계정 기능 전체는 아직 Unverified다.**
사용자가 Game ID·업적·리더보드·Console 테스터 설정이 아직 없다고 답했으므로 가짜 ID로 로그인하지 않았다.

| 검사 | 실제 결과 |
| --- | --- |
| 기기 | Samsung SM_F966N, Android 16 / API 36, USB adb authorized |
| Debug native Gradle export·설치·실행 | 성공; `com.example.mobiletemplate.pgsprobe`, **21 checks, 0 failures**, debug=true |
| Release native Gradle export·설치·실행 | 성공; `com.example.mobiletemplate.pgsprobe.release`, **23 checks, 0 failures**, debug=false |
| 최종 Desktop headless 통합 | **103 checks, 0 failures**, exit 0 |
| 전체 feature off (`--disabled`) | **13 checks, 0 failures**, exit 0 |
| SDK 없는 Desktop native (`--native`) | **13 checks, 0 failures**, exit 0 |
| Play Games Game ID / 계정 로그인·서버 점수·업적 | Console 설정 미제공으로 미실행 |
| iOS Game Center | 이전 상태 유지; 바이너리/전체 Xcode/Team ID/기기 검증 미완료 |

Toolchain: Godot `4.7.2.stable.official.ed1daf0bf`, 정확히 일치하는 `4.7.2.stable/android_source.zip`.
Temurin JDK **17.0.20.1+1**, Gradle **8.11.1**, AGP **8.6.1**, Kotlin **2.1.21**,
compile/target SDK **36**, Build-Tools **36.1.0**, min SDK **24**, arm64-v8a.
Template에는 NDK **29.0.14206865**가 지정돼 있으나 Godot engine은 prebuilt AAR를 사용했고 새 C++ 빌드를 하지 않았다.
기존 JDK 25와 전역 Godot 편집기 설정은 바꾸지 않았다. `/tmp`의 격리된 프로젝트·편집기 설정으로 export했다.

실기기에서 확인한 것:

- `GodotPlayGameServices` singleton, 실제 Java 메서드 7개와 신호 3개 등록.
- 기존 App 소유 Android adapter 선택, 다른 서비스가 Mock mode여도 Android override로 native 선택.
- Game ID가 없으면 Adapter의 SDK `initialize` 호출 생략, 로그인/점수/업적 `unavailable`, 가짜 인증 없음.
- disabled Service의 Adapter 초기화 생략. native 진단 앱에 Mock billing adapter 없음.
- release 엔진에서 config의 mock mode 및 직접 만든 MockGameServicesAdapter가 차단됨.
- 앱 PID에 한정한 logcat에 script/parser error 또는 Java Exception/FATAL crash 없음.
- 기기의 진단 화면 PNG를 열어 Debug=false 표시와 23개 검사 통과를 확인함.

첫 기기 검사에서 Object.has_method가 JNI Java 메서드를 보고하지 않아 7개 실패가 있었다.
Godot 4.7.2의 `has_java_method()` 계약에 맞춰 Adapter와 probe를 수정하고 JNI 전용 조회 회귀 검사 2개를 추가했다.
최종 Debug/Release를 다시 export·설치·실행해 모두 통과했다. ConfigFile 주석도 `#`에서 `;`로 수정했다.

두 AAR에는 중복 Godot 클래스가 없고 export와 동일한 dependency 파라미터의
[Gradle graph](../PGS_ANDROID_DEPENDENCIES.txt)는 games-v2 **21.0.0**, Gson **2.11.0**을 해결했다.
Maven Godot 4.5.1은 도입하지 않았다. APK에는 build config가 주입되고 APP_ID는 미설정 상태로 생성하지 않았다.
기존 설치 앱을 덮어쓰지 않고 별도 진단 패키지를 사용했다.

Release APK는 테스트용 debug 인증서로 서명했다. release 엔진/Mock 차단 검증이며 스토어 signing 검증은 아니다.
Debug APK 인증서 SHA-1: `6A:5E:87:F5:11:D6:71:FA:51:82:33:C0:B7:D6:FD:5C:BE:F5:E2:62`.
Release 진단 APK 인증서 SHA-1: `27:3D:81:5A:2C:F9:46:9E:17:DD:AF:6A:80:A2:4C:6F:21:B4:B4:2A`.
빌드 산출물(모두 Git 제외):

- `build/android/pgs-probe-debug.apk`, SHA-256 `aeb1766a9e3fad05b93f336e7ae5b11ab6daa99e52b4043f9b72452dd7791118`.
- `build/android/pgs-probe-release.apk`, SHA-256 `9668a8ff4ceb3a676b4cef5e68b20bb2f3cffbfe31c583f8264baa427f94b985`.

로그: `/tmp/pgs-gradle-debug.log`, `/tmp/pgs-gradle-release.log`, `/tmp/pgs-device-debug.log`, `/tmp/pgs-device-release.log`.
계정 설정 절차와 재현은 [ANDROID_PLAY_GAMES.md](../ANDROID_PLAY_GAMES.md)에 기록했다.
`wizard` 스킬로 `/tmp/playgames-console-setup.sh`를 준비하고 `bash -n`으로 문법을 확인했다.
이 wizard는 사용자 브라우저에서 Console ID/OAuth/테스터를 설정하고 Git 제외 local config에 저장하도록 안내한다.
wizard를 실행하거나 Console을 변경하지 않았다.

남은 검사: 실제 SDK 초기화·로그인 성공/취소/오프라인, Google 서버 점수/업적,
실제 native UI, pause/resume·인증 변경, Play App Signing 인증서 조합.
현재 기기 로딩 검증만으로 배포용 `android_native_verified`를 true로 바꾸지 않았다.

## 게임 서비스 확장 — 2026-10-01 Agent 검증

아래는 **같은 날 AAR 도입 전에 실행한 최초 확장 검증**이다. 후속 Android 결과는 위 기록을 따른다.

Godot `4.7.2.stable.official.ed1daf0bf`, macOS / Apple M1에서 검사했다.
`App.game_services`, Debug Mock, SDK 미설치 상태의 Android/iOS Adapter 연결 코드가 추가되었다.
**네이티브 Google Play Games / Game Center 지원은 Unverified다.**

| 검사 | 실제 결과 |
| --- | --- |
| 최종 headless 통합 | **101 checks, 0 failures**, exit 0 |
| 전체 feature off (`--disabled`) | **13 checks, 0 failures**, exit 0 |
| SDK 없는 native mode (`--native`) | **13 checks, 0 failures**, exit 0 |
| 최종 macOS 실제 Compatibility 렌더러 + 데모 버튼 + PNG | **102 checks, 0 failures**, exit 0 |
| Android 기본 Debug APK export | 성공, exit 0; `build/android/game-services-template.apk` |
| iOS 기본 Debug export | 실패, exit 1: `App Store Team ID not specified.` |
| Android 연결 기기 조회 (`adb devices -l`) | 연결 기기 없음 |
| 전체 Xcode | `xcode-select -p`는 `/Library/Developer/CommandLineTools`; 전체 Xcode 빌드 미검증 |

최종 headless/disabled/native 합계 **127 검사, 실패 0**이다.
실제 렌더러 102 검사는 최종 101개 동작 검사와 PNG 1개다.
PNG `/tmp/mobile-template-demo.png`를 열어 게임 서비스 로그인 버튼·텍스트·스크롤 배치를 확인했다.
데모의 로그인/점수/업적/화면 요청 버튼은 실제 버튼 Callable로 실행하고 결과 신호를 확인했다.
최종 통합 로그에는 parser/script error나 ObjectDB/resource 누수 경고가 없다.
초기 sandbox 실행의 CA/log 쓰기·Editor Settings 권한 오류는 일반 실행으로 재검사해 사라졌음을 확인했다.

게임 서비스 검사 내용:

- Mock 선택, 로그인 전 요청 거절, 로그인 성공/취소/오류, 점수·업적 결과의 Mock 표시.
- 논리 ID의 플랫폼 ID 매핑, 알 수 없는 ID와 빈 native ID 거절.
- 중복 로그인/작업 차단, 타임아웃 실패, 늦게 도착한 콜백 무시 및 기존 native 작업 해제 후 재요청.
- **가짜 SDK**로 Android 실제 메서드/신호 매핑, 요청 전 현재 인증 상태 재확인, 오류·잘못된 ID·중복 콜백 처리.
- **가짜 SDK**로 iOS pending event queue, 즉시/비동기 오류, UI 닫힘, float32 점수 범위와 int64 최소값 처리.
- iOS 이전 큐의 중복 이벤트가 완료 신호에서 시작한 다음 요청을 완료하지 못하는 회귀 검사.
- 기능 off에서 SDK 초기화 생략, 실제 플랫폼 Adapter를 Desktop에서 실행할 때 unavailable.
- release Mock 금지는 App의 기존 `GameConfig.use_mocks()`와 Mock Adapter 자체의 `OS.is_debug_build()` guard로 구현했다.
  **실제 release binary를 기기에서 실행한 검증은 아니다.**

Android APK는 외부 SDK 없는 기본 preset의 Debug export다. Google Play Games 플러그인 AAR,
Gradle/native ABI, 실제 OAuth/테스트 계정 및 Google 서버의 점수·업적 결과를 검증한 것이 아니다.
export 로그에는 build-tools **35.0.1** fallback과 Java native-access 경고가 있었으며 signing/verification은 성공했다.
iOS entitlement는 계속 false다. Team ID, 전체 Xcode, 4.7.2용 GameCenter xcframework와 signing을 준비해야 한다.

두 플랫폼의 실제 로그인·업적·리더보드, UI 동작, 오프라인/재개/인증 해제, release Mock 차단 및 기기 검증이 남아 있다.
네이티브 플러그인은 저장소 지침에 따라 설치를 보류했고 플랫폼별 native gate는 false다.
설치/검증 대상과 API 제한은 [DEPENDENCIES.md](../DEPENDENCIES.md#게임-서비스-후보--2026-10-01),
[GAME_SERVICES.md](../GAME_SERVICES.md)에 기록했다.

재현 명령의 `godot`가 PATH에 없다면 `/Applications/Godot.app/Contents/MacOS/Godot`를 사용한다.
로그를 임시 위치로 지정하려면 `--log-file /tmp/game-services-test.log`를 옵션에 추가한다.

## 후속 확인 — 2026-09-18 사용자 보고

사용자가 Android 실기기에서 실행과 다음 Mock 결과를 확인했다. 아래는 사용자 보고이며 Agent가 직접 재실행한 결과는 아니다.

| 항목 | 사용자 확인 결과 |
| --- | --- |
| 광고 | 성공 |
| Mock Purchase Success | `purchase_completed : REMOVE_ADS` |
| Mock Purchase Cancel | `purchase_cancelled : REMOVE_ADS` |
| Mock Purchase Error | `purchase_failed : REMOVE_ADS / mock_error` |
| Mock 복원 | `restore_completed : 1 item(s)` |

기기 모델·OS·빌드 도구 버전·테스트한 commit은 보고되지 않았다. 이 확인은 실제 광고 SDK나 스토어 결제 검증을 의미하지 않는다. iOS 실행과 release 빌드 검증도 별도로 남아 있다.

아래 환경과 export 실패 내용은 **2026-09-16 최초 Agent 검증 당시의 기록**이며, 현재 Android 실행 불가를 의미하지 않는다.

## 환경

- Engine: `4.7.2.stable.official.ed1daf0bf`.
- macOS / Apple M1. 실제 화면 검증: OpenGL API 4.1 Metal 90.5, Compatibility renderer.
- 설치 JDK: Temurin 25.0.3. 권장 JDK17과 다른 값이며 Android 검증 toolchain으로 채택하지 않음.
- Android SDK 및 Godot 4.7.2 export templates: 미설치.
- Xcode: 전체 앱 미설치, `/Library/Developer/CommandLineTools` 선택 상태.
- Git 저장소가 없는 시작 폴더. commit/tag 생성 안 함.

## 완료

- [x] Godot 4.7.2 Editor headless import/open 완료.
- [x] Parser / compile error 없음.
- [x] Bootstrap → Demo 실행.
- [x] Save/Load, migration, 자동 저장 타이머, 파일 손상/미래 schema/쓰기 실패 보호.
- [x] Settings 독립 저장 및 게임 옵션 확장.
- [x] AudioManager BGM/SFX/UI, mute, pause/resume, 정리.
- [x] SceneManager 전환/중복 요청/없는 경로.
- [x] Mock 광고 성공/실패, consent gate.
- [x] Mock 결제 success/cancel/error, 상품 ID 매핑, 복원, 중복 요청 차단.
- [x] Mock privacy/analytics/review.
- [x] 전체 feature off 및 native 미설치 초기화.
- [x] 실제 macOS 렌더러에서 Demo 버튼 실행 및 viewport PNG 확인.
- [x] game/ 외부 plugin 직접 의존 없음 (현재 게임 코드는 없음).
- [x] Android/iOS dependency 조사와 exact version/source/license 문서.
- [x] README/BOM/ARCHITECTURE/AGENTS 및 secret ignore 작성.

최종 headless: **51 + 8 + 8 = 67 검사, 실패 0**.
실제 렌더러 실행은 그 이전 49개 동작 검사 + screenshot 1개 = **50 검사, 실패 0**.
이후 추가된 자동 저장 타이머/분수 schema 2개 검사는 headless에서 확인했다.
실제 화면은 `/tmp/mobile-template-demo.png`로 캡처해 텍스트, 버튼, 스크롤 배치를 확인했다.
사운드 재생기와 버스 상태는 검증했지만 사람의 청취 판정 또는 모바일 스피커 검증은 하지 않았다.
OS touch/back/노치/회전은 실제 모바일 기기에서 추가 확인해야 한다.

## Export 시도 — 완료하지 못함

Android:
```text
--export-debug Android build/android/mobile-template.apk
exit 1
Missing: android_debug.apk / android_release.apk (4.7.2.stable)
Invalid Android SDK path: platform-tools, adb, build-tools, apksigner
```

iOS:
```text
--export-debug iOS build/ios/mobile-template.zip
exit 1
Missing: export_templates/4.7.2.stable/ios.zip
```

- [ ] Android debug/release export 및 기기 실행.
- [ ] iOS Xcode export/build/signing 및 기기 실행.
- [ ] 실제 광고/결제/동의/리뷰 SDK 검증.
- [ ] release binary에서 Mock 금지 동작 검증 (코드 guard와 native mode 경로는 검사함).

SDK/template와 전체 Xcode, signing 및 테스트 기기가 준비되어야 완료할 수 있다.
SDK 없는 기본 서비스 구현을 네이티브 지원 완료로 표현하지 않는다.

## 관찰한 환경 이슈

sandbox 내부에서는 macOS 시스템 CA 읽기와 Editor Settings 저장 권한 오류가 있었다.
허용된 일반 실행으로 재검증하여 해당 오류가 사라짐을 확인했다.
threaded PackedScene 로드 경로에서 종료 RefCounted 경고가 나타났고, 메인 스레드 로드로 단순화한 이후 통합/데모 종료에서 경고가 사라졌다.
모바일 export preset이 있는 Editor에서는 SDK가 설치되기 전까지 build-tools 누락 메시지가 예상된다.

## 재현

```bash
godot --headless --path . --editor --import --quit
godot --headless --path . --scene res://tests/integration.tscn
godot --headless --path . --scene res://tests/integration.tscn -- --disabled
godot --headless --path . --scene res://tests/integration.tscn -- --native
```

필요 시 GUI 렌더링과 `/tmp` 캡처:
```bash
godot --path . --scene res://tests/integration.tscn -- --capture
```

통합 검사는 고유 임시 저장 경로를 사용하고 정상 완료 시 정리한다.
런타임 출력의 완료 요약과 종료 코드, script error 부재를 함께 확인한다.
