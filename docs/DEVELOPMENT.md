# 개발 상세 안내

처음 실행하는 방법은 [README](../README.md)를 먼저 읽으세요.
이 문서는 설정, API, 모바일 빌드와 배포를 수정할 때 참고하는 상세 안내입니다. 파일 경로와 명령의 실행 위치는 저장소 루트 기준입니다.

## Purpose

게임별 로직을 `game/`에 추가해서 여러 모바일 게임을 시작할 수 있는 공통 scaffolding입니다.
광고·결제 SDK를 게임에서 직접 호출하지 않고 Service → Adapter로 분리합니다.
장르별 시스템, DI framework, 범용 EventBus는 포함하지 않습니다.

**현재 상태:** 템플릿 0.4.0은 Android GPGS·Google Play Billing·AdMob·UMP를 고정 버전으로 연결합니다.
Desktop 통합, Android Debug/Release 기기 JNI 로딩·샘플 광고·Release Mock 차단을 검사했습니다(0.3.0 기기 기록).
0.4.0은 Google Play AAB·ONE store 배포 preset, 시작 시 미완료 구매 동기화, ONE store 결제 플러그인 소스(기기 미검증)를 추가했습니다.
실제 Play Console 상품·계정 기능, ONE store 결제와 iOS는 후속 검증입니다. 스토어별 요건은 [STORE_RELEASE.md](STORE_RELEASE.md)를 따릅니다. [Android 연결 계약](ANDROID_SERVICES.md), [실제 검증 기록](template/VALIDATION.md)을 따릅니다.

## Requirements

- Godot **4.7.2 Standard** (GDScript). 설치 검증값: `4.7.2.stable.official.ed1daf0bf`.
- 모바일 export: **4.7.2** export templates. 다른 버전과 혼용하지 않습니다.
- Android 및 iOS별 도구는 아래 Setup 절을 따릅니다.
- 명령 예시는 `godot`가 PATH에 있는 환경을 기준으로 합니다. macOS 앱은 `/Applications/Godot.app/Contents/MacOS/Godot`로 대체할 수 있습니다.
- 명령은 저장소 루트에서 실행합니다. 테스트 framework, Python package, 외부 Godot addon 설치는 필요하지 않습니다.

## Technology Stack

| Category | Name | Version | Platform | Godot Compatibility | Status |
| --- | --- | ---: | --- | --- | --- |
| Engine | Godot Engine | 4.7.2 | All | 기준 버전 | Locked |
| Language | GDScript | 4.7.2 내장 | All | 엔진 내장 | Locked |
| Framework | 자체 Service / Mock / 공통 관리자 | 0.4.0 | All | 실행 결과는 VALIDATION 참고 | In-repo |
| Game services | Godot Play Game Services | v3.4.0 | Android | Debug/Release 기기 로딩, 계정 미검증 | Installed, export opt-in |
| Billing | GodotGooglePlayBilling | 3.3.0 | Android | JNI·조회 응답 확인, 실제 구매 미검증 | Installed, export opt-in |
| Billing | GodotOneStoreIap (템플릿 소스) + ONE store IAP SDK | 21.04.00 | Android (ONE store) | 컴파일·가짜 SDK 계약만 확인 | Source, 로컬 빌드 |
| Ads / Privacy | Poing AdMob | 5.1.0 | Android | UMP 갱신·샘플 광고 기기 검사 | Installed, export opt-in |
| Analytics / Review | 자체 Mock | 0.4.0 | All | 4.7.2 Desktop 실행 검증 | Mock |
| iOS native | 바이너리 없음 | N/A | iOS | Unverified | Not installed |

엔진 공식 이름은 **Godot Engine**, License는 **MIT**입니다.
[Repository](https://github.com/godotengine/godot), [고정 버전 설치](https://godotengine.org/download/archive/4.7.2-stable/), [라이선스 및 배포 고지](https://godotengine.org/license/).
4.7.2 Standard를 내려받아 열고 동일 버전 export templates를 설치합니다.
선택 이유는 이 템플릿의 고정 기술 기준입니다. 2026-11-04에 4.7.2가 최신 안정판(4.8은 beta)임을 확인했습니다.
엔진에 포함된 제3자 라이선스 고지는 배포 시 보존해야 합니다.
데모 WAV는 이 저장소에서 생성한 단순 사인파이며 외부 음원 라이브러리가 아닙니다.

## Dependency BOM

현재 정확한 버전·라이선스·SDK 조합은 [README BOM](../README.md#dependency-bom)과 [DEPENDENCIES.md](DEPENDENCIES.md#채택-bom--mobile-template-bom-v040)를 기준으로 합니다.
기본 Android preset의 세 SDK 포함 옵션과 native gate는 false입니다.
GPGS는 v3.4.0 / games-v2 22.1.0 / Gson 2.14.0, 결제는 3.3.0 / Billing 9.1.0,
광고는 Poing 5.1.0 / Next-Gen Ads 1.4.0 / UMP 4.0.0, ONE store는 IAP SDK 21.04.00입니다.
iOS StoreKit 2·Game Center·광고, 외부 Analytics·Review는 아직 미설치입니다.
실제 스토어 구매·계정 기능과 빌드·샘플 광고 검증 범위는 구분합니다.

## Architecture

```text
Game (game/)
    ↓
Service (App.ads / App.billing / App.analytics / App.privacy / App.review / App.game_services)
    ↓
Adapter (Mock / unavailable / Android native / ONE store)
    ↓
Godot Plugin / Native SDK (Android export opt-in)
```

`AdsService`는 클래스이고 `App.ads`는 그 인스턴스입니다. 서비스마다 autoload를 중복 등록하지 않습니다.
앱이 소유한 서비스는 장면이 바뀌어도 유지됩니다.

> Game code must never directly depend on a mobile platform plugin.

상세 책임과 확장 지점은 [ARCHITECTURE.md](ARCHITECTURE.md)를 참고하세요.
AI Agent가 처음 작업할 때는 [AGENTS.md](../AGENTS.md)와 [CODEBASE_MAP.md](CODEBASE_MAP.md)에서 진입 흐름, 작업별 수정 위치 및 검증 경로를 확인하세요.

## Directory Structure

```text
addons/                 고정 Android GPGS / Billing / AdMob AAR와 export 연결, ONE store AAR 로컬 출력 위치
autoload/               App, GameConfig, SaveManager, Settings, AudioManager, SceneManager
core/
  events/               예약 디렉터리, 범용 EventBus 없음
  logging/              개발 로그
  platform/             플랫폼 구분, 기본 진동
  storage/              JSON 파일 입출력
  utils/                예약 디렉터리
services/
  ads/ billing/         Service, Android·ONE store Adapter, Mock
  game_services/        로그인·업적·리더보드 Service, Android/iOS Adapter, Mock
  analytics/ privacy/ review/
ui/
  common/               SafeArea
  loading/              전환 overlay
  settings/             재사용 SettingsPanel
  popup/                저장 복구 팝업(SaveRecoveryPopup)
scenes/                 bootstrap(게임 초기화 hook), main 검증 화면, 전환 검증 화면, Android 진단
game/                   게임별 코드 및 저장 구조 (현재 README만 존재)
examples/               game/으로 복사해 쓰는 레퍼런스(게임 스켈레톤, 구매 처리). export 제외
native/                 템플릿이 소유한 native 플러그인 소스(ONE store). export 제외
config/                 game.cfg, products.json
assets/demo/            자체 생성 테스트 음원
tests/                  실제 SceneTree 통합 검사, fixtures/ 검사용 script
tools/                  설정 동기화(configure.gd), 문서 링크 검사(check_docs.py)
.github/workflows/      headless 통합 검사 CI
docs/                   설계, BOM, 개발 안내
  template/             템플릿 적용 절차, 변경 기록, 템플릿 자체 구현 계획·검증 기록
```

## Getting Started

1. Godot 4.7.2에서 `project.godot`를 Import합니다.
2. F6 대신 **F5**로 bootstrap부터 실행합니다. main scene의 F6도 초기화를 보완합니다.
3. Save/Load, 오디오, Mock 서비스를 순서대로 눌러 봅니다.
4. 광고 전에 `Request Mock Consent` 또는 `Grant Mock Consent`를 누릅니다.
5. 화면을 아래로 스크롤하면 구매 복원, 분석, 리뷰, 전환, 설정을 확인할 수 있습니다.

```bash
godot --headless --path . --editor --import --quit
godot --headless --path . --scene res://tests/integration.tscn
godot --headless --path . --scene res://tests/integration.tscn -- --disabled
godot --headless --path . --scene res://tests/integration.tscn -- --native
godot --headless --path . --scene res://examples/game_skeleton/tests/game_tests.tscn
python3 tools/check_docs.py
```

통합 검사는 고유 임시 디렉터리에 저장하여 개발자의 `user://save.json`을 변경하지 않습니다.
모든 결과가 `PASS`, 마지막 `failures=0`인지 확인합니다. CI에서는 종료 코드뿐 아니라 `SCRIPT ERROR`, `Parse Error` 로그와 완료 요약도 검사하세요.
`.github/workflows/ci.yml`이 push·PR마다 공식 Godot 4.7.2 Linux 빌드(SHA-256 확인)로 위 명령과 configure 동기화 diff를 검사합니다.

## Creating a New Game

1. 프로젝트를 복제하고 `config/game.cfg`의 이름, 버전, build_number, package/bundle, orientation을 바꿉니다.
2. [examples/game_skeleton](../examples/game_skeleton/README.md)을 `game/`으로 복사해 타이틀·플레이·결과 구조에서 시작하거나, `game/main.tscn` 등 첫 장면을 직접 만들고 `app/main_scene`을 지정합니다.
3. `config/products.json`에서 logical ID / 상품 타입 / Android·iOS ID를 편집합니다.
4. 사용하지 않는 feature flag를 `false`로 지정합니다.
5. 아래 설정 동기화 도구를 실행합니다.
6. 저장 schema와 migration이 필요하면 `game/` 아래 초기화 script를 만들고 `app/init_script`에 지정합니다. bootstrap이 `App.initialize()` **이전**에 호출합니다. ([Save / Settings](#save--settings))
7. 게임 장면에서는 아래 공개 API만 사용합니다. demo 장면과 `assets/demo`는 통합 검사가 사용하므로 유지합니다(배포 preset에서는 자동 제외).
8. 결제를 쓰면 [examples/purchase_ledger](../examples/purchase_ledger/README.md)를 `game/`으로 복사해 지급 규칙을 정합니다.

기존 프로젝트로 가져오는 방법, 유지·교체할 파일, 출처 기록은 [템플릿 적용 절차](template/APPLYING.md)를 따릅니다.

```gdscript
func _ready() -> void:
    App.ads.rewarded_completed.connect(_on_rewarded)
    App.billing.purchase_completed.connect(_on_purchase)

func _on_rewarded(placement_id: String) -> void:
    # game/ 안에서 게임별 보상을 정의한다.
    print(placement_id)

func _on_purchase(product_id: String, transaction: Dictionary) -> void:
    # transaction_id 기준 중복 지급 방지 정책은 게임이 정의한다.
    print(product_id, transaction.get("mock", false))
```

## Configuration

`config/game.cfg`는 **공개 설정**입니다. 런타임 파일은 export preset의 include filter에 포함됩니다.
비밀 API key나 signing password를 넣지 않습니다. local 파일은 자동 merge되지 않습니다.

| 위치 | 설정 |
| --- | --- |
| `app` | name, version(게임 앱 버전), build_number(스토어 제출 번호), android_package, ios_bundle, orientation, main_scene, init_script |
| `features` | ads_enabled, iap_enabled, analytics_enabled, review_enabled, privacy_enabled, game_services_enabled |
| `services` | mode=`mock` 또는 `native`, allow_mobile_debug_mocks |
| `save` | autosave_seconds(기본 30초), recovery_popup(기본 true) |
| `ads` | android_mode, android_native_verified, use_test_ads, test_device_ids, retry_seconds, Android/iOS App ID, rewarded/interstitial/banner unit ID |
| `billing` | android_mode, android_native_verified, timeout_seconds, android_product_ids, onestore_product_ids, onestore_public_key |
| `privacy` | tag_for_under_age_of_consent |
| `game_services` | android_game_id, android_mode, android/ios_native_verified, timeout_seconds, leaderboard_ids, achievement_ids |
| `products.json` | logical ID → type, android, onestore, ios |

운영 ID·공개 키는 Git 제외 `config/android.local.cfg`, `config/game_services.local.cfg`에 둡니다. exporter가 허용한 키만 빌드에 주입합니다.

orientation: `sensor`, `portrait`, `landscape`, `sensor_portrait`, `sensor_landscape`.
템플릿 기본은 sensor이며 특정 방향을 고정하지 않습니다. 실제 launch orientation도 맞추려면 동기화가 필요합니다.

```bash
godot --headless --path . --script res://tools/configure.gd
```

이 도구는 이름·버전·orientation을 `project.godot`에, package/bundle/version/build_number를 모든 Android·iOS preset에 반영합니다.
`Android Google Play`(AAB)·`Android ONE store`(APK) preset이 없으면 만들고, Gradle·SDK 포함 옵션을 기능 플래그와 스토어 규칙에 맞춥니다.
signing 설정과 진단(`probe`) preset은 유지합니다. 스토어 제출마다 `build_number`를 올리고 다시 실행합니다. 자세한 내용은 [STORE_RELEASE.md](STORE_RELEASE.md).
플래그는 시작 시 적용되므로 변경 후 앱을 재시작하세요.

## Android Setup

아래 값은 [Godot 4.7 공식 export 안내](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html)의 최소 요구사항입니다.
네이티브 SDK·Gradle export는 실제로 **compile/target SDK 36, Build-Tools 36.1.0, min SDK 24**로 검증했으므로 Platform 36과 Build-Tools 36.1.0도 설치합니다.

| 도구 | 문서 기준 |
| --- | --- |
| JDK | OpenJDK 17 권장 |
| Android SDK Platform | 35 |
| Build-Tools | 35.0.1 |
| Platform-Tools | 35.0.0 이상; 검증용 exact revision 미고정 |
| CMake | 3.10.2.4988404 |
| NDK | r28b / 28.1.13356709 |
| Command-line tools | exact revision Unknown; 설치 시 BOM에 기록 |

Editor Settings에 Java SDK Path와 Android SDK Path를 지정합니다.
기본 SDK 없는 debug APK는 `Use Gradle Build=false`이므로 Custom Build Template이 필요하지 않습니다.
**Play Store AAB 또는 Android plugin 통합 시 Gradle build와 4.7.2 Android build template을 사용합니다.**
Gradle build template은 **Project 메뉴**에서 설치합니다. 일반 export templates 설치는 **Editor → Manage Export Templates…**이며, Export 창 왼쪽 아래의 같은 이름 링크로도 열 수 있습니다. [공식 Gradle 설정](https://docs.godotengine.org/en/4.7/tutorials/export/android_gradle_build.html)

처음 준비할 때는 다음 순서로 진행합니다.

1. Godot 4.7.2 export templates를 설치합니다.
2. OpenJDK 17과 Android SDK를 설치합니다. Android Studio의 SDK Manager에서 위 표의 패키지를 선택합니다.
3. macOS 상단 Godot → Editor Settings… → Export → Android에서 Java SDK Path와 Android SDK Path를 지정합니다.
4. Project → Export… → Android를 엽니다. ETC2/ASTC 오류가 보이면 옆의 Show Project Setting을 눌러 Import ETC2 ASTC를 켭니다.
5. 휴대폰의 USB 디버깅을 켜고 USB로 연결한 뒤, 휴대폰에서 연결을 허용합니다.
6. Godot에 표시되는 Android 실행 버튼으로 debug 앱을 설치합니다. 기기가 안 보이면 SDK의 `adb devices`에서 연결 상태를 확인합니다.

기본 preset은 진동용 `VIBRATE`를 사용합니다. 네이티브 SDK 포함 시 AAR manifest의 네트워크·광고·Billing 권한이 병합됩니다.
실제 배포 권한은 최종 merged manifest로 확인합니다. Android 세 SDK 동시 export 절차는 [ANDROID_SERVICES.md](ANDROID_SERVICES.md)를 따릅니다.

Billing·AdMob·Play Games AAR는 `addons/android_services/`, `addons/play_game_services/`에 설치돼 있습니다. 설정과 계약은 [ANDROID_SERVICES.md](ANDROID_SERVICES.md)를 따릅니다.
Play Console 상품을 `products.json`과 연결하고 내부 테스트 트랙·테스터로 구매/복원을 검증합니다.
AdMob은 Google 샘플 ID(`use_test_ads=true`)로 시작하며 production ID는 Git 제외 로컬 설정에만 둡니다.

Signing 키는 저장소 밖에서 관리합니다. release는 debug 키를 쓰지 않습니다.
Godot의 `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `GODOT_ANDROID_KEYSTORE_RELEASE_USER`,
`GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD` 환경변수로 주입할 수 있습니다.
`export_credentials.cfg`, keystore, 인증서는 `.gitignore`에 포함됩니다.

## iOS Setup

[Godot 4.7 공식 iOS export 안내](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_ios.html)에 따라 macOS, 전체 Xcode와 4.7.2 export templates가 필요합니다.
해당 안내에서 특정 macOS/Xcode 최소 숫자는 고정하지 않으므로 임의의 숫자를 적지 않습니다.
첫 기기 검증 시 macOS·Xcode·iOS SDK·deployment target의 정확한 버전을 BOM에 기록합니다.
2026-09-16 최초 검증 환경에는 전체 Xcode가 없었으며 CommandLineTools만 있었습니다. 이후 iOS 검증 기록은 아직 없습니다.

1. `config/game.cfg`의 ios_bundle을 지정하고 동기화합니다.
2. iOS export preset에 Apple Team ID와 signing/provisioning을 로컬에서 설정합니다.
3. 비어 있는 `build/ios/` 아래로 export하고 생성된 Xcode 프로젝트를 엽니다.
4. Xcode의 Signing & Capabilities에서 Team과 provisioning을 확인합니다.
5. 실제 iPhone에서 debug 실행 후 Archive로 release를 검증합니다.

StoreKit/IAP는 App Store Connect 상품, capability와 sandbox 계정, entitlement 검증이 필요합니다.
StoreKit2 0.2는 Experimental이므로 현재 설치하지 않습니다.
AdMob·UMP·ATT는 선정한 광고 adapter에서 연동합니다. ATT 목적 문구 및 실제 SDK privacy manifest를 최종 빌드 기준으로 작성하고, 이미 포함된 UMP/ATT SDK를 중복 설치하지 않습니다.
Mock consent는 실제 ATT 권한을 요청하지 않습니다.

인증서, p12, p8, provisioning profile, password를 commit하지 않습니다.
Compatibility renderer를 사용하지만 iOS simulator 및 실기기 동작은 아직 Unverified입니다.

## Ads

```gdscript
if App.ads.is_rewarded_ready():
    App.ads.show_rewarded("revive")
App.ads.show_interstitial("between_rounds")
```

- `rewarded_completed(placement_id)`: 이 신호에서만 보상을 지급합니다.
- `rewarded_failed(placement_id, reason)`: 비활성, 동의 부족, busy/not ready, Mock 오류.
- `interstitial_closed(placement_id)`, `ad_failed(placement_id, reason)`.
- Mock은 0.3초 후 결과를 내고 화면 상태/개발 로그에서 Mock 실행을 확인할 수 있습니다.
- 배너는 API만 준비되어 `banner_not_implemented`로 실패합니다. App Open/Native Ads는 범위 밖입니다.

## In-App Purchase

```gdscript
App.billing.purchase("REMOVE_ADS")
App.billing.restore_purchases()
```

상품 타입은 `consumable`, `non_consumable`, `subscription`입니다.
게임은 logical ID만 전달하고 서비스가 현재 스토어(`GameConfig.store()`: google_play / onestore / app_store)의 Store ID를 조회합니다.
구매/복원은 한 번에 하나만 허용하며 누락 상품은 `invalid_product`로 실패합니다.

- `purchase_completed(product_id, transaction)`
- `purchase_cancelled(product_id)`
- `purchase_failed(product_id, reason)`
- `restore_completed(transactions)` / `restore_failed(reason)`

Mock transaction 필드: `transaction_id`, `product_id`, `store_id`, `type`, `mock=true`.
Mock 복원은 **현재 실행 세션**의 비소모성/구독 상품만 포함합니다. 소모성 상품은 제외합니다.
Android native는 가격·offer 조회, pending, 취소, 복원과 acknowledge/consume을 연결합니다.
`transaction_received`는 미검증 수신입니다. 게임/서버가 검증·중복 지급 방지·저장을 마친 뒤 `finish_purchase(token)`을 호출합니다.
Android native는 앱 시작·재개 때 보유 구매를 조용히 다시 조회해 미완료 거래를 `transaction_received`로 다시 보냅니다(restore 신호 없음).
신호를 연결하기 전에 도착한 거래는 `App.billing.get_unfinished_transactions()`로 확인합니다. 예제: [examples/purchase_ledger](../examples/purchase_ledger/README.md).
자동 영수증 검증 서버와 게임별 보상·구독 갱신/만료 정책은 포함하지 않습니다. [구매 API 계약](ANDROID_SERVICES.md#google-play-billing-계약)을 따릅니다.
게임의 보상·영구 권한은 게임 저장 구조에서 관리하며 같은 transaction을 재수신해도 중복 지급하지 않도록 구현합니다.

## Mock Services

기본 Desktop debug는 `mode="mock"`입니다. 실행 중인 게임은 `Engine.is_editor_hint()`가 false여도 Mock을 사용할 수 있습니다.
모바일 debug에서 Mock을 쓰려면 `allow_mobile_debug_mocks=true`를 명시해야 합니다.
**release에서는 설정과 관계없이 Mock이 선택되지 않습니다.** MockBillingAdapter 직접 호출도 구매·복원이 차단됩니다.
Android native는 SDK 포함·mode·검증 gate가 맞을 때 선택하며 미설정 경로는 unavailable입니다.

```gdscript
App.billing.set_mock_result("cancel") # success / cancel / error, 다음 요청에만 적용
App.billing.purchase("REMOVE_ADS")
App.ads.set_mock_result("error")
App.privacy.set_mock_status("denied")
App.privacy.request_consent()
App.analytics.track_event("level_started", {"level": 1})
App.analytics.set_user_property("language", "ko")
App.review.request_review()
```

Privacy 초기 상태는 unknown입니다. 광고는 `can_request_ads()`, 분석은 `can_use_services()`로 확인합니다.
Native UMP의 `ads_allowed`는 광고 요청 자격이며 분석·개인화 동의를 뜻하지 않습니다.
`privacy_enabled=false`일 때도 광고/분석은 차단됩니다. 이 초기 정책을 변경하려면 실제 SDK의 동의 상태 모델에 맞춰 서비스와 테스트를 함께 변경합니다.
Analytics Mock은 이벤트/속성 이름만 개발 로그에 남기고 속성 값은 출력하지 않습니다.
Review의 `mock_requested`는 실제 표시 또는 리뷰 작성 완료를 의미하지 않습니다.

## Save / Settings

```gdscript
SaveManager.set_value("progress", {"level": 2})
var error := SaveManager.save_slot()
SaveManager.load_slot()
Settings.set_setting("bgm_volume", 0.7)
Settings.set_setting("haptics_enabled", true)
```

- Save: `user://save.json`, envelope `{ "version": 1, "data": {...} }`.
- 기본 슬롯 한 개. 게임 데이터는 JSON 호환 Dictionary/Array/String/number/bool/null만 사용합니다.
- JSON 숫자는 load 후 float가 될 수 있습니다. 정수 게임 값은 `int(...)`로 읽습니다.
- `set_value()`는 dirty를 표시하며 30초 타이머, 앱 pause 및 종료 시 변경분을 저장합니다.
- `data`를 직접 수정하면 `mark_dirty()`가 필요합니다. 단순 문자열 키 단위 API를 우선합니다.
- 쓰기는 `.tmp` 후 rename하며 직전 파일을 `save.json.bak`으로 남깁니다. 암호화, cloud save, 완전한 정전 내구성, 다중 프로세스 동시 쓰기는 제공하지 않습니다.
- 원본이 없거나 JSON으로 읽히지 않으면 `.bak`으로 복구하고 `recovered_from_backup(error)`을 보냅니다. 직전 저장 이후의 진행은 잃을 수 있습니다. 버전·migration 오류는 백업으로 되돌리지 않습니다.
- 복구도 실패하면 기존 메모리/파일을 보존하고 쓰기를 차단합니다. bootstrap이 `SaveRecoveryPopup`(다시 시도 / 두 번 눌러 새로 시작)을 띄우고 첫 장면 진입을 기다립니다. 새로 시작하면 읽지 못한 원본을 `save.json.unreadable`로 남깁니다.
- 팝업 문구는 영어 기본값이며 번역에 `SAVE_RECOVERY_*` 키를 추가하면 바뀝니다. `[save] recovery_popup=false`면 게임이 직접 `reset_slot()` 흐름을 만듭니다.
- 저장 실패는 반환값과 `save_failed`/`load_failed` 신호로 전달됩니다. 종료 저장 실패 시 자동 종료를 보류합니다.

게임별 schema와 migration은 `config/game.cfg`의 `app/init_script`로 지정한 script에서 등록합니다.
bootstrap은 `App.initialize()`(저장 load 포함) **이전**에 `before_app_initialize()`를 한 번 호출합니다.
script는 `RefCounted`를 상속해야 하며, 빈 값이면 생략합니다. 경로 오류·잘못된 script는 오류를 기록하고 hook 없이 초기화를 계속합니다.
이때 schema가 등록되지 않으므로 더 높은 버전의 저장은 load 실패로 처리되고 쓰기가 차단됩니다.

```gdscript
# game/game_init.gd — config: init_script="res://game/game_init.gd"
extends RefCounted

func before_app_initialize() -> void:
    SaveManager.schema_version = 2
    SaveManager.register_migration(1, func(old: Dictionary) -> Dictionary:
        old["new_field"] = 0
        return old)
```

F6으로 게임 장면을 직접 실행하면 bootstrap을 거치지 않으므로 hook도 호출되지 않습니다. 저장을 확인할 때는 F5로 실행합니다.

Settings는 **별도 `user://settings.cfg` ConfigFile**이며 변경 즉시 저장합니다.
BGM/SFX/UI 볼륨, haptics_enabled, language와 임의 게임 옵션을 지원합니다.
`language`의 기본값은 빈 값이며 기기 언어를 따릅니다. 값을 지정하면 그 locale을 쓰고, 빈 값으로 되돌리면 다시 기기 언어를 따릅니다.
번역이 없는 언어는 프로젝트 fallback(`en`)으로 표시됩니다. 번역 리소스는 게임이 추가합니다. `.po` 등록 예시는 [game_skeleton](../examples/game_skeleton/README.md)의 `game_init.gd`입니다.
`SettingsPanel`의 언어 목록은 `SettingsPanel.languages`(코드 → 표시 이름)로 바꿉니다.
AudioManager는 BGM 한 개, SFX/UI 최대 16개를 재생합니다. 반복은 AudioStream 리소스에서 지정합니다.

## Export

```bash
mkdir -p build/android build/ios
godot --headless --path . --script res://tools/configure.gd
godot --headless --path . --export-debug Android build/android/game.apk
godot --headless --path . --export-release 'Android Google Play' build/android/game-google-play.aab
godot --headless --path . --export-release 'Android ONE store' build/android/game-onestore.apk
godot --headless --path . --export-debug iOS build/ios/game.zip
```

`Android`는 개발용 APK preset(Gradle 없음)입니다. 스토어 업로드는 `Android Google Play`(AAB)와 `Android ONE store`(APK)를 사용하며, 두 preset 모두 Android Build Template이 필요합니다.
iOS release는 Xcode signing/archive까지 수행해야 완료입니다.
`config/game.cfg`, `products.json`은 패키지에 포함되고 `tests/`, `tools/`, `docs/`, `examples/`, `native/`, 로컬 설정은 제외됩니다.
`main_scene`이 데모가 아니면 iOS·스토어 preset에서 데모 장면·진단 장면·`assets/demo/`가 자동 제외됩니다. 파일 자체를 삭제하면 통합 검사가 실패합니다.

2026-09-16 최초 export는 SDK/template 부재로 실패했습니다. 이후 Android 실기기 실행과 Mock 테스트는 사용자 확인을 받았습니다.
2026-10-21 Android 네이티브 export·기기 결과는 [검증 기록](template/VALIDATION.md)을 따릅니다. 실제 스토어 구매·계정 기능과 iOS는 미검증입니다.

## Dependency Upgrade Policy

엔진과 plugin을 자동으로 업그레이드하지 않습니다. `latest` 다운로드를 코드에 넣지 않습니다.
새 dependency는 Godot 기본 기능으로 해결할 수 없는 경우에만 선택하고 source/license/정확 버전/native SDK를 BOM에 기록합니다.

```text
태그 및 Compatibility Test
    → Android Test
    → iOS Test
    → BOM Update
    → Template Version Update
```

검증된 조합 전체를 대상으로 재검증하며, upstream 지원 주장과 이 프로젝트의 실기기 검증을 구분합니다.
Template는 SemVer를 사용합니다. 템플릿 버전은 `GameConfig.TEMPLATE_VERSION`, README와 [변경 기록](template/CHANGELOG.md)에 함께 기록합니다.
`config/game.cfg`의 `app/version`은 게임 앱 버전이며 템플릿 버전과 별개입니다.
release 절차: 버전·변경 기록 갱신 → 통합 검사 → 기본 브랜치 merge → merge commit에 `vX.Y.Z` annotated tag push.
태그 없는 commit을 적용할 때는 commit hash를 출처로 기록합니다.

## Known Limitations

- Android native 검증 범위는 VALIDATION을 따릅니다. 실제 스토어·계정 기능과 iOS native, 전체 safe area/back/rotation/haptic/lifecycle 조합은 미검증입니다.
- SafeArea는 전체화면 모바일 canvas 기준입니다. 다중 창/특수 viewport는 게임에서 보완해야 합니다.
- SceneManager는 두 프레임 뒤 메인 스레드에서 로드합니다. 큰 장면은 일시 정지가 있을 수 있으며 streaming은 범위 밖입니다.
- UMP 광고 자격과 분석 동의를 분리합니다. 실제 앱의 required 동의 UI·거부·개인정보 선택 변경은 추가 기기 검증이 필요합니다. iOS ATT는 미설치입니다.
- 배너·미디에이션, 서버 결제 검증과 구독 갱신·만료 정책은 후속 작업입니다. 로컬 지급 기록은 예제로만 제공합니다.
- ONE store 결제는 플러그인 소스·컴파일·가짜 SDK 검사까지입니다. iOS 결제·광고·Game Center native는 미설치입니다.
- 언어 선택과 기기 언어 적용만 제공합니다. 데모 화면 번역은 없고, 번역 예시는 game_skeleton의 `en`·`ko`뿐입니다.
- 저장 백업은 직전 저장 한 세대뿐입니다. 복구 팝업의 실제 기기 표시(safe area, 회전)는 미검증입니다.
- 프레임워크는 게임별 데이터·보상·entitlement를 정의하지 않습니다.

## Troubleshooting

| 증상 | 확인할 내용 |
| --- | --- |
| class not found | 4.7.2 Editor로 한 번 import한 뒤 실행 |
| 광고가 not ready | 기능 플래그, 어댑터 선택, can_request_ads(), native loaded 상태 |
| 모바일에서 unavailable | Mock은 debug/mode/allow_mobile_debug_mocks, native는 SDK 포함 옵션·기능별 mode·검증 gate·로컬 설정 확인 |
| 구매 disabled/invalid_product | iap 플래그와 logical ID/type/플랫폼 ID |
| 소리가 없음 | BGM/SFX/UI 볼륨, OS 음량, stream 값; headless는 소리가 출력되지 않음 |
| 저장이 계속 실패 | `write_blocked`, 쓰기 권한, 디스크, schema/migration과 오류 신호 |
| 이름/방향이 안 바뀜 | configure.gd 실행 후 프로젝트 재시작 |
| Android build-tools 오류 | SDK Path, adb/apksigner 및 4.7.2 templates 설치 |
| iOS export 실패 | ios.zip, 전체 Xcode, Team ID, provisioning 확인 |

정확한 dependency 조사 기록은 [DEPENDENCIES.md](DEPENDENCIES.md), 검증 범위와 남은 항목은 [VALIDATION.md](template/VALIDATION.md)에 있습니다.
