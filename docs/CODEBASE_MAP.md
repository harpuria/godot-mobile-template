# Codebase Map

새 작업을 시작하는 AI Agent를 위한 코드 진입 안내서입니다. 규칙은 [AGENTS.md](../AGENTS.md)(Claude Code는 `CLAUDE.md`의 import로 읽음), 설치·실행은 [README.md](../README.md)가 기준입니다. 아래에서 작업 대상을 찾고 관련 파일부터 읽으세요.

## 실행 흐름과 소유권

```text
project.godot
  ├─ Autoload 준비: GameConfig → Settings → SaveManager → AudioManager → SceneManager → App
  └─ scenes/bootstrap.tscn → scenes/bootstrap.gd
       ├─ android_services_probe export feature → scenes/android_services_probe.tscn (결제·광고·UMP 기기 진단)
       ├─ pgs_probe export feature → scenes/android_game_services_probe.tscn (기기 진단)
       ├─ config의 app/init_script → before_app_initialize() (게임 hook, 기본 비어 있음)
       ├─ App.initialize()
       │    ├─ 방향 설정 및 서비스/Adapter 생성
       │    └─ SaveManager.load_slot() → initialized 신호
       └─ SceneManager.change_scene(config의 app/main_scene)
            └─ 기본값: scenes/main.tscn → scenes/demo.gd
```

- Autoload는 [project.godot](../project.godot)에 등록된 앱 수명의 인스턴스입니다. `SaveManager`, `Settings`, `AudioManager`, `SceneManager`를 직접 사용합니다.
- `AdsService`, `BillingService` 등은 클래스 이름입니다. [App](../autoload/app.gd)이 서비스 인스턴스를 소유하며 게임은 `App.ads`, `App.billing`, `App.analytics`, `App.privacy`, `App.review`, `App.game_services`로 접근합니다. 서비스는 `App.initialize()` 이후 사용할 수 있습니다.
- `App.initialize()`는 중복 실행을 방지합니다. 새 게임의 진입점은 `app/main_scene`으로 지정하고 bootstrap부터 실행합니다.
- `core/`와 `ui/`의 클래스는 필요할 때 생성·사용하는 공통 코드입니다. 별도 singleton으로 등록되어 있지 않습니다.

## 작업별 시작 위치

경로는 저장소 루트 기준입니다. 게임 규칙·데이터는 `game/`에 두고, 공통 동작을 바꿔야 할 때만 관리자를 수정합니다.

| 작업 | 먼저 읽을 파일 / 수정 위치 |
| --- | --- |
| 템플릿을 새 게임에 적용·업데이트 | `docs/template/APPLYING.md`, `docs/template/CHANGELOG.md` |
| 게임 장면·규칙 추가 | `game/README.md`, `game/`; 첫 장면 연결은 `config/game.cfg`의 `app/main_scene` |
| 초기화 순서·게임 hook·서비스 선택 변경 | `scenes/bootstrap.gd`, `autoload/app.gd`, `autoload/game_config.gd` |
| 게임 진행 저장·migration | `autoload/save_manager.gd`; 게임별 schema·변환 함수는 `game/`의 init script, `app/init_script`로 연결 |
| 저장 파일 입출력 자체 변경 | `core/storage/json_store.gd` |
| 사용자 설정·설정 화면 | `autoload/settings.gd`, `ui/settings/settings_panel.gd` |
| BGM·SFX·UI 사운드 | `autoload/audio_manager.gd`; 게임 음원은 `game/` 아래에 배치 |
| 장면 이동·로딩 화면 | `autoload/scene_manager.gd`, `ui/loading/loading.tscn` |
| 광고·결제 등 서비스 동작 | `services/<기능>/`의 Service → 기본 Adapter → Mock 순서로 읽기 |
| 게임 로그인·업적·리더보드 | `docs/GAME_SERVICES.md`, `services/game_services/`; 검증은 `tests/game_services_checks.gd`와 `tests/integration.tscn` |
| 네이티브 SDK 연결 | 해당 서비스의 새 Adapter + `autoload/app.gd`의 선택 코드; dependency 조사 문서 먼저 읽기 |
| Android 결제·광고·동의 | `docs/ANDROID_SERVICES.md`, `services/billing/android_billing_adapter.gd`, `services/ads/android_admob_adapter.gd`, `services/privacy/android_admob_privacy_adapter.gd` |
| Android 결제·광고 export | `addons/android_services/plugin.gd`, `addons/android_services/manifest.json`; JNI 계약 검사는 `core/platform/android_plugin.gd` |
| Android Play Games export·기기 진단 | `docs/ANDROID_PLAY_GAMES.md`, `addons/play_game_services/plugin.gd`, `scenes/android_game_services_probe.gd` |
| 상품 ID·타입 변경 | `config/products.json`; 매핑 로직은 `services/billing/billing_service.gd` |
| pause/resume·Android back | `autoload/app.gd`의 신호를 게임/UI에서 구독 |
| 플랫폼·진동·안전 영역 | `core/platform/mobile_platform.gd`, `ui/common/safe_area.gd` |
| 앱 이름·버전·패키지·방향 | `config/game.cfg`, `tools/configure.gd` |
| 동작 예제·회귀 검사 | `scenes/demo.gd`, `scenes/transition_demo.gd`, `tests/integration.gd`, `tests/fixtures/` |

`scenes/`와 `assets/demo/`는 프레임워크 검증 예제이며 통합 검사가 사용하므로 새 게임에서도 유지합니다. `docs/template/`은 템플릿 자체의 적용 절차·변경 기록·구현 계획·검증 기록이며 게임 문서가 아닙니다. `addons/play_game_services/`와 `addons/android_services/`는 고정 Android AAR·라이선스·export 연결을 소유합니다. `core/events/`, `core/utils/`, `ui/popup/`은 예약 디렉터리입니다.

## 설정을 바꿀 때

- **런타임 설정:** `GameConfig`가 `config/game.cfg`와 `config/products.json`을 시작 시 읽습니다. feature flag와 서비스 mode를 바꾼 후 앱을 재시작하세요.
- **게임 서비스:** `features/game_services_enabled`, `game_services`의 논리 ID Dictionary·timeout·플랫폼별 `*_native_verified`가 App → Service/Adapter에 전달됩니다. Android AAR는 export opt-in이며 플랫폼 gate는 기본 false입니다. ID의 플랫폼 키는 소문자 `android`, `ios`입니다.
- **Android 설정 전파:** exporter가 `config/game_services.local.cfg`의 허용된 ID·mode·gate만 `config/game_services.build.cfg`로 주입하고 GameConfig가 이를 읽습니다. `android_mode=native`로 다른 서비스 mode와 독립적으로 native를 선택합니다. Android Gradle preset의 `game_services/include_sdk=true`가 필요합니다.
- **Android 결제·광고 설정 전파:** `addons/android_services/plugin.gd`가 `config/android.local.cfg`의 billing/ads/privacy whitelist만 `android_services.build.cfg`로 주입합니다. App이 기능별 `android_mode`와 `android_native_verified`로 어댑터를 선택합니다. SDK 포함은 `billing/include_sdk`, `ads/include_sdk`이며 기본 false입니다.
- **추가 공개 API:** `App.billing.query_products()`, `transaction_received`, `purchase_pending`, `finish_purchase(token)`은 수신·검증·스토어 완료를 분리합니다. `App.privacy.can_request_ads()`는 광고 자격이며 분석 동의인 `can_use_services()`와 별도입니다. 계약은 `docs/ANDROID_SERVICES.md`를 따릅니다.
- **프로젝트·export 설정:** 앱 이름·버전·package/bundle·orientation을 바꾸면 `tools/configure.gd`를 실행해 `project.godot`와 `export_presets.cfg`에 반영합니다. 이 도구는 export 경로와 include/exclude filter도 기록하므로 실행 후 diff를 확인하세요.

- **로컬 빌드 환경:** JDK/SDK 경로는 Godot Editor Settings, signing은 로컬 export 자격 증명에서 관리합니다. 로컬 파일은 해당 exporter가 허용한 키만 빌드에 주입합니다. 일반 실행에서 임의의 local 파일을 자동 병합하지 않습니다.

```bash
godot --headless --path . --script res://tools/configure.gd
```

`godot`가 PATH에 없으면 실행 파일 경로로 대체합니다. macOS 기본 설치 경로는 `/Applications/Godot.app/Contents/MacOS/Godot`입니다.

## 코드를 연결하기 전에 확인할 계약

- **저장:** 게임별 `schema_version`과 migration은 `App.initialize()` 전에 등록해야 합니다. `game/`에 `RefCounted` script를 만들어 `before_app_initialize()`에서 등록하고 `app/init_script`에 경로를 지정합니다. bootstrap(F5)만 hook을 호출하며 실패 시 오류를 기록하고 초기화를 계속합니다. `set_value()`는 자동 저장 대상을 표시하지만 `data`를 직접 수정하면 `mark_dirty()`가 필요합니다. 사용자 설정은 별도 `Settings`로 저장합니다.
- **초기화 실패:** 현재 App은 저장 load 실패 후에도 초기화 완료를 알립니다. SaveManager는 쓰기를 차단하지만 복구 UI는 제공하지 않습니다. `ready_for_game`을 저장 성공의 증거로 사용하지 마세요.
- **광고·동의:** 보상은 `rewarded_completed`에서 지급합니다. 광고는 privacy.can_request_ads(), 분석은 privacy.can_use_services()가 필요하며 `privacy_enabled=false`도 허용 상태가 아닙니다.
- **결제:** 게임은 logical 상품 ID를 전달합니다. Native는 transaction_received를 검증·저장한 뒤 finish_purchase를 호출하고 purchase_token으로 중복 지급을 방지합니다. Mock은 transaction_id를 사용합니다. Mock 복원은 같은 실행 세션의 비소모성·구독 거래만 반환합니다.
- **Mock 선택:** `mode="mock"`인 debug 빌드에서 사용합니다. 모바일은 `allow_mobile_debug_mocks=true`도 필요합니다. release는 Mock을 선택하지 않습니다. Android 결제·광고·UMP는 기능별 native gate와 SDK 포함 옵션이 필요합니다.
- **일시정지·전환:** App의 모바일 pause 알림은 저장·오디오를 처리하며 게임 전체의 일시정지 정책을 정하지 않습니다. SceneManager는 메인 스레드에서 로드하고 `_process`를 사용합니다. `SceneTree.paused=true` 상태에서 장면 이동이 필요하면 process mode와 복귀 정책을 함께 검증하세요.

## 변경 후 검증

| 변경 범위 | 확인할 경로 |
| --- | --- |
| 게임 로직·UI | bootstrap부터 해당 게임 장면 실행, 변경한 입력·상태 전환 확인 |
| 저장·설정·오디오·장면·Mock | 아래 기본 통합 검사와 영향받는 데모 동작 |
| 초기화·feature flag·Adapter 선택 | 기본 검사 + `--disabled` + `--native` |
| Safe Area·터치·방향·lifecycle·export·native SDK | 대상 플랫폼 빌드와 실기기 확인; Desktop 검사로 대체하지 않음 |
| 문서만 변경 | 코드·경로·문서 링크 대조; 런타임 재검사 불필요 |

```bash
godot --headless --path . --editor --import --quit
godot --headless --path . --scene res://tests/integration.tscn
godot --headless --path . --scene res://tests/integration.tscn -- --disabled
godot --headless --path . --scene res://tests/integration.tscn -- --native
```

기본 통합 검사는 기본 상품 구성을 사용하는 Desktop debug Mock 시나리오입니다. 상품·설정을 게임에 맞춰 바꿨다면 테스트 입력도 검토하세요. 테스트 저장은 임시 경로에 격리됩니다. 종료 코드, `INTEGRATION` 완료 요약의 실패 0건, script/parse error 부재를 함께 확인합니다. `--native`는 SDK 미설치 실패 경로를 검사하며 실제 스토어 테스트가 아닙니다.

Android 결제·광고·UMP의 가짜 SDK 계약은 `tests/android_services_checks.gd`가 기본 검사에 포함됩니다. 세 SDK 동시 기기 검사는 `android_services_probe` feature와 `scenes/android_services_probe.tscn`을 사용합니다. 빌드·기기 절차는 `docs/ANDROID_SERVICES.md`, 실제 증거는 `docs/template/VALIDATION.md`를 따릅니다.

## 필요한 문서만 추가로 읽기

- 계층·초기화·저장·서비스 계약 변경: [ARCHITECTURE.md](ARCHITECTURE.md).
- dependency 선정·설치·버전 변경: [DEPENDENCIES.md](DEPENDENCIES.md), [README의 BOM](../README.md#dependency-bom).
- 템플릿 기능의 기존 검증 범위 판단·새 결과 기록: [template/VALIDATION.md](template/VALIDATION.md). 실행 환경·날짜와 직접 검증/사용자 보고를 구분하세요. 파생 게임의 검증은 게임 프로젝트의 문서(예: `docs/VALIDATION.md`, `docs/PLAYTEST_NOTES.md`)에 따로 기록합니다.
- 새 게임에 적용·버전 업데이트: [template/APPLYING.md](template/APPLYING.md), [template/CHANGELOG.md](template/CHANGELOG.md).
- 처음 실행·새 게임 생성: [README.md](../README.md). 상세 설정·API·플랫폼 export: [DEVELOPMENT.md](DEVELOPMENT.md).

파일 이동, 진입 흐름, 공개 접근 API, 설정 반영 방식 또는 검증 명령을 바꾸면 같은 변경에서 이 지도를 갱신합니다. 정책과 dependency 버전, 테스트 결과 전문은 각 담당 문서에 유지합니다.
