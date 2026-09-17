# 개발 상세 안내

처음 실행하는 방법은 [README](../README.md)를 먼저 읽으세요.
이 문서는 설정, API, 모바일 빌드와 배포를 수정할 때 참고하는 상세 안내입니다. 파일 경로와 명령의 실행 위치는 저장소 루트 기준입니다.

## Purpose

게임별 로직을 `game/`에 추가해서 여러 모바일 게임을 시작할 수 있는 공통 scaffolding입니다.
광고·결제 SDK를 게임에서 직접 호출하지 않고 Service → Adapter로 분리합니다.
장르별 시스템, DI framework, 범용 EventBus는 포함하지 않습니다.

**현재 상태:** Godot 4.7.2 Desktop에서 Foundation·Mock 구현 검증 완료.
이후 사용자가 Android 실기기 실행과 Mock 광고·결제·복원 성공을 확인했습니다. iOS 실행은 아직 확인하지 않았습니다.
네이티브 광고·결제·동의는 아직 통합하지 않았습니다. 배포 가능한 SDK 통합 완료 상태가 아닙니다.
최초 환경에서의 export 실패 기록과 이후 사용자 확인 결과는 [검증 기록](VALIDATION.md)을 참고하세요.

## Requirements

- Godot **4.7.2 Standard** (GDScript). 설치 검증값: `4.7.2.stable.official.ed1daf0bf`.
- 모바일 export: **4.7.2** export templates. 다른 버전과 혼용하지 않습니다.
- Android 및 iOS별 도구는 아래 Setup 절을 따릅니다.
- 명령 예시는 `godot`가 PATH에 있는 환경을 기준으로 합니다. macOS 앱은 `/Applications/Godot.app/Contents/MacOS/Godot`로 대체할 수 있습니다.
- 저장소 shell 작업은 RTK를 사용합니다. 테스트 framework, Python package, 외부 Godot addon 설치는 필요하지 않습니다.

## Technology Stack

| Category | Name | Version | Platform | Godot Compatibility | Status |
| --- | --- | ---: | --- | --- | --- |
| Engine | Godot Engine | 4.7.2 | All | 기준 버전 | Locked |
| Language | GDScript | 4.7.2 내장 | All | 엔진 내장 | Locked |
| Framework | 자체 Service / Mock / 공통 관리자 | 0.1.0 | All | 4.7.2 Desktop 실행 검증 | In-repo |
| Billing | 외부 플러그인 없음 | N/A | Android / iOS | Native Unverified | Deferred |
| Ads / Privacy | 외부 플러그인 없음 | N/A | Android / iOS | Native Unverified | Deferred |
| Analytics / Review | 자체 Mock | 0.1.0 | All | 4.7.2 Desktop 실행 검증 | Mock |
| Native SDK | 추가 SDK 없음 | N/A | Android / iOS | Native Unverified | Not installed |

엔진 공식 이름은 **Godot Engine**, License는 **MIT**입니다.
[Repository](https://github.com/godotengine/godot), [고정 버전 설치](https://godotengine.org/download/archive/4.7.2-stable/), [라이선스 및 배포 고지](https://godotengine.org/license/).
4.7.2 Standard를 내려받아 열고 동일 버전 export templates를 설치합니다.
선택 이유는 이 템플릿의 고정 기술 기준이며, 마지막 로컬 확인일은 **2026-09-16**입니다.
엔진에 포함된 제3자 라이선스 고지는 배포 시 보존해야 합니다.
데모 WAV는 이 저장소에서 생성한 단순 사인파이며 외부 음원 라이브러리가 아닙니다.

## Dependency BOM

```text
Mobile Template BOM v0.1.0
Godot Engine                  4.7.2
GDScript                      bundled with Godot 4.7.2
In-repo framework / mocks     0.1.0
Installed mobile plugins      none
Additional native SDKs        none
```

이 BOM은 **외부 SDK 없는 scaffold 조합**입니다. Android Mock에 대한 사용자 확인은 실제 광고·스토어 SDK 조합 검증과 구분합니다.

조사한 후보는 아래와 같으며 **설치된 dependency가 아닙니다**.

| 후보 | 조사된 정식 release | Native dependency | 4.7.2 상태 / 보류 이유 |
| --- | --- | --- | --- |
| GodotGooglePlayBilling | 3.3.0 | Google Play Billing Library 9.1.0 | Upstream 4.2+ / 프로젝트 Unverified |
| Poing Studios AdMob | 5.1.0 | Android Next-Gen Ads 1.4.0 / iOS Ads 13.9.0 | Upstream 4.7.2 테스트 명시 / 문서 요건 충돌, 프로젝트 Unverified |
| Godot Admob 대안 | 7.0 | 정확한 native 조합 Unknown | Upstream 4.7 / 4.7.2 Unverified |
| Godot StoreKit 2 | 0.2 | Apple StoreKit 2 OS framework | Experimental / 4.7.2 Unverified |
| Godot In-app Review | 5.3 | Android 정확 버전 Unknown / iOS OS API | Upstream 4.7 / 4.7.2 Unverified |

**각 후보의 source, MIT license, 설치 방법, 유지보수, 지원 플랫폼, native SDK, 확인 날짜 및 제약은 [DEPENDENCIES.md](DEPENDENCIES.md)에 기록했습니다.**
불명확한 버전은 Unknown으로 유지하며 이전 release 값을 추측해서 승계하지 않습니다.

## Architecture

```text
Game (game/)
    ↓
Service (App.ads / App.billing / App.analytics / App.privacy / App.review)
    ↓
Adapter (Mock 또는 unavailable 기본 구현)
    ↓
Godot Plugin / Native SDK (현재 미설치)
```

`AdsService`는 클래스이고 `App.ads`는 그 인스턴스입니다. 서비스마다 autoload를 중복 등록하지 않습니다.
앱이 소유한 서비스는 장면이 바뀌어도 유지됩니다.

> Game code must never directly depend on a mobile platform plugin.

상세 책임과 확장 지점은 [ARCHITECTURE.md](ARCHITECTURE.md)를 참고하세요.
AI Agent가 처음 작업할 때는 [AGENTS.md](../AGENTS.md)와 [CODEBASE_MAP.md](CODEBASE_MAP.md)에서 진입 흐름, 작업별 수정 위치 및 검증 경로를 확인하세요.

## Directory Structure

```text
addons/                 검증된 native plugin 설치 위치 (현재 비어 있음)
autoload/               App, GameConfig, SaveManager, Settings, AudioManager, SceneManager
core/
  events/               예약 디렉터리, 범용 EventBus 없음
  logging/              개발 로그
  platform/             플랫폼 구분, 기본 진동
  storage/              JSON 파일 입출력
  utils/                예약 디렉터리
services/
  ads/ billing/         Service, Adapter, Mock
  analytics/ privacy/ review/
ui/
  common/               SafeArea
  loading/              전환 overlay
  settings/             재사용 SettingsPanel
  popup/                예약 디렉터리
scenes/                 bootstrap, main 검증 화면, 전환 검증 화면
game/                   게임별 코드 및 저장 구조 (현재 README만 존재)
config/                 game.cfg, products.json
assets/demo/            자체 생성 테스트 음원
tests/                  실제 SceneTree 통합 검사
tools/                  공개 설정 동기화 도구
docs/                   설계, BOM, 구현 계획, 검증 기록
```

## Getting Started

1. Godot 4.7.2에서 `project.godot`를 Import합니다.
2. F6 대신 **F5**로 bootstrap부터 실행합니다. main scene의 F6도 초기화를 보완합니다.
3. Save/Load, 오디오, Mock 서비스를 순서대로 눌러 봅니다.
4. 광고 전에 `Request Mock Consent` 또는 `Grant Mock Consent`를 누릅니다.
5. 화면을 아래로 스크롤하면 구매 복원, 분석, 리뷰, 전환, 설정을 확인할 수 있습니다.

```bash
rtk godot --headless --path . --editor --import --quit
rtk godot --headless --path . --scene res://tests/integration.tscn
rtk godot --headless --path . --scene res://tests/integration.tscn -- --disabled
rtk godot --headless --path . --scene res://tests/integration.tscn -- --native
```

통합 검사는 고유 임시 디렉터리에 저장하여 개발자의 `user://save.json`을 변경하지 않습니다.
모든 결과가 `PASS`, 마지막 `failures=0`인지 확인합니다. CI에서는 종료 코드뿐 아니라 `SCRIPT ERROR`, `Parse Error` 로그와 완료 요약도 검사하세요.

## Creating a New Game

1. 프로젝트를 복제하고 `config/game.cfg`의 이름, 버전, package/bundle, orientation을 바꿉니다.
2. `game/main.tscn` 등 게임 첫 장면을 만들고 `app/main_scene`을 지정합니다.
3. `config/products.json`에서 logical ID / 상품 타입 / Android·iOS ID를 편집합니다.
4. 사용하지 않는 feature flag를 `false`로 지정합니다.
5. 아래 설정 동기화 도구를 실행합니다.
6. 저장 schema와 migration이 필요하면 bootstrap에서 `App.initialize()` **이전**에 등록합니다.
7. 게임 장면에서는 아래 공개 API만 사용합니다. 새 게임에서 demo 장면과 `assets/demo`는 제거 가능합니다.

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
| `app` | name, version, android_package, ios_bundle, orientation, main_scene |
| `features` | ads_enabled, iap_enabled, analytics_enabled, review_enabled, privacy_enabled |
| `services` | mode=`mock` 또는 `native`, allow_mobile_debug_mocks |
| `save` | autosave_seconds, 기본 30초 |
| `ads` | Android/iOS App ID, rewarded/interstitial/banner unit ID (현재 빈 값) |
| `products.json` | logical ID → type, android, ios |

orientation: `sensor`, `portrait`, `landscape`, `sensor_portrait`, `sensor_landscape`.
템플릿 기본은 sensor이며 특정 방향을 고정하지 않습니다. 실제 launch orientation도 맞추려면 동기화가 필요합니다.

```bash
rtk godot --headless --path . --script res://tools/configure.gd
```

이 도구는 이름·버전·orientation을 `project.godot`에, package/bundle/version을 `export_presets.cfg`에 반영합니다.
기존 signing, Gradle 선택 및 build number는 유지합니다. Android version code와 iOS build number는 스토어 제출마다 별도 증가시킵니다.
플래그는 시작 시 적용되므로 변경 후 앱을 재시작하세요.

## Android Setup

아래 값은 [Godot 4.7 공식 export 안내](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html)의 요구사항입니다.
실제 설치·검증 toolchain BOM과는 구분합니다.

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

현재 permission은 기본 진동용 `VIBRATE`입니다. 광고/분석 네트워크 권한은 아직 넣지 않았습니다.
네이티브 통합 시 검증한 SDK manifest의 INTERNET/광고 관련 권한, Billing 권한 및 최종 merged manifest를 점검합니다.

Billing은 3.3.0 후보를 태그 고정 후 `addons/GodotGooglePlayBilling/`에 설치·활성화하고 Adapter를 추가하는 후속 작업입니다.
해당 후보의 compileSdk 36 요구사항을 기본 SDK35와 별도 조정해야 합니다.
Play Console 상품을 `products.json`과 연결하고 내부 테스트 트랙·테스터로 구매/복원을 검증합니다.
AdMob 역시 후속 adapter에서 테스트 App ID/unit ID를 사용하며 production ID를 여기 포함하지 않습니다.

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
게임은 logical ID만 전달하고 서비스가 플랫폼 Store ID를 조회합니다.
구매/복원은 한 번에 하나만 허용하며 누락 상품은 `invalid_product`로 실패합니다.

- `purchase_completed(product_id, transaction)`
- `purchase_cancelled(product_id)`
- `purchase_failed(product_id, reason)`
- `restore_completed(transactions)` / `restore_failed(reason)`

Mock transaction 필드: `transaction_id`, `product_id`, `store_id`, `type`, `mock=true`.
Mock 복원은 **현재 실행 세션**의 비소모성/구독 상품만 포함합니다. 소모성 상품은 제외합니다.
구독 갱신/만료, 상품 가격 조회, offer, pending, 실제 영수증 검증·acknowledge/consume/finish는 아직 구현하지 않았습니다.
Native adapter는 검증과 거래 정리를 포함하는 계약을 완성한 뒤 연결해야 합니다.
게임의 보상·영구 권한은 게임 저장 구조에서 관리하며 같은 transaction을 재수신해도 중복 지급하지 않도록 구현합니다.

## Mock Services

기본 Desktop debug는 `mode="mock"`입니다. 실행 중인 게임은 `Engine.is_editor_hint()`가 false여도 Mock을 사용할 수 있습니다.
모바일 debug에서 Mock을 쓰려면 `allow_mobile_debug_mocks=true`를 명시해야 합니다.
**release에서는 설정과 관계없이 Mock이 선택되지 않습니다.** Native 구현이 없으므로 unavailable 결과를 반환합니다.

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

Privacy 초기 상태는 unknown이며 명시적 granted 전에는 광고/분석을 차단합니다.
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
- 쓰기는 `.tmp` 후 rename. 암호화, cloud save, 완전한 정전 내구성, 다중 프로세스 동시 쓰기는 제공하지 않습니다.
- load 실패 시 기존 메모리/파일을 보존하고 쓰기를 차단합니다. 사용자 복구/새 게임 결정 후 `reset_slot()`을 호출합니다.
- 저장 실패는 반환값과 `save_failed`/`load_failed` 신호로 전달됩니다. 종료 저장 실패 시 자동 종료를 보류합니다.

```gdscript
# App.initialize() 전에 게임별 schema 설정
SaveManager.schema_version = 2
SaveManager.register_migration(1, func(old: Dictionary) -> Dictionary:
    old["new_field"] = 0
    return old)
```

Settings는 **별도 `user://settings.cfg` ConfigFile**이며 변경 즉시 저장합니다.
BGM/SFX/UI 볼륨, haptics_enabled, language와 임의 게임 옵션을 지원합니다.
언어 선택은 TranslationServer locale을 바꿉니다. 실제 번역 리소스는 게임이 추가합니다.
AudioManager는 BGM 한 개, SFX/UI 최대 16개를 재생합니다. 반복은 AudioStream 리소스에서 지정합니다.

## Export

```bash
rtk mkdir -p build/android build/ios
rtk godot --headless --path . --script res://tools/configure.gd
rtk godot --headless --path . --export-debug Android build/android/game.apk
rtk godot --headless --path . --export-release Android build/android/game.apk
rtk godot --headless --path . --export-debug iOS build/ios/game.zip
```

Android 명령은 기본 APK preset 기준입니다. Play Store용은 Gradle을 켜고 export format을 AAB로 바꾼 뒤 `.aab`로 export합니다.
iOS release는 Xcode signing/archive까지 수행해야 완료입니다.
`config/game.cfg`, `products.json`은 패키지에 포함되고 `tests/`, `tools/`, `docs/`, 로컬 설정은 제외됩니다.
Demo/음원은 기본 검증용이므로 새 게임의 release 전 제거하거나 제외하세요.

2026-09-16 최초 export는 SDK/template 부재로 실패했습니다. 이후 Android 실기기 실행과 Mock 테스트는 사용자 확인을 받았습니다.
기기·도구 버전 및 release 결과는 별도 기록이 필요합니다. iOS와 실제 광고·결제 SDK 통합도 아직 검증하지 않았습니다.

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
Template는 SemVer `0.1.0`에서 시작합니다. Git 저장소 초기화/commit 후 검증한 release에 `v0.1.0` 태그를 붙일 수 있습니다.
GitHub private 저장소와 최초 commit/push는 완료했습니다. release tag 생성은 별도 작업입니다.

## Known Limitations

- Android/iOS native integration 및 실기기 safe area, back, rotation, haptic, pause/resume는 Unverified입니다.
- SafeArea는 전체화면 모바일 canvas 기준입니다. 다중 창/특수 viewport는 게임에서 보완해야 합니다.
- SceneManager는 두 프레임 뒤 메인 스레드에서 로드합니다. 큰 장면은 일시 정지가 있을 수 있으며 streaming은 범위 밖입니다.
- 개인정보 모델은 Mock 검증용 단순 상태입니다. 실제 UMP canRequestAds와 ATT 상태는 같은 개념이 아니므로 native 구현 시 각각 매핑해야 합니다.
- 배너, 실제 SDK init/재시도, 결제 보안/서버 검증, 구독 정책은 후속 작업입니다.
- Settings 언어 선택만 제공하며 데모 전체 번역은 포함하지 않습니다.
- 프레임워크는 게임별 데이터·보상·entitlement를 정의하지 않습니다.

## Troubleshooting

| 증상 | 확인할 내용 |
| --- | --- |
| class not found | 4.7.2 Editor로 한 번 import한 뒤 실행 |
| 광고가 not ready | 기능 플래그, Mock 선택, consent granted 여부 |
| 모바일에서 unavailable | debug 빌드, mode=mock, allow_mobile_debug_mocks=true 확인; native SDK는 미설치 |
| 구매 disabled/invalid_product | iap 플래그와 logical ID/type/플랫폼 ID |
| 소리가 없음 | BGM/SFX/UI 볼륨, OS 음량, stream 값; headless는 소리가 출력되지 않음 |
| 저장이 계속 실패 | `write_blocked`, 쓰기 권한, 디스크, schema/migration과 오류 신호 |
| 이름/방향이 안 바뀜 | configure.gd 실행 후 프로젝트 재시작 |
| Android build-tools 오류 | SDK Path, adb/apksigner 및 4.7.2 templates 설치 |
| iOS export 실패 | ios.zip, 전체 Xcode, Team ID, provisioning 확인 |

정확한 dependency 조사 기록은 [DEPENDENCIES.md](DEPENDENCIES.md), 검증 범위와 남은 항목은 [VALIDATION.md](VALIDATION.md)에 있습니다.
