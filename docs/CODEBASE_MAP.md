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
       │    ├─ 방향 설정 및 서비스/Adapter 생성 (스토어: GameConfig.store() — custom feature onestore)
       │    ├─ Android native 결제는 시작 시 미완료 구매를 조용히 sync
       │    └─ SaveManager.load_slot() → initialized 신호
       ├─ 저장 load 실패 시 ui/popup/save_recovery_popup.gd (다시 시도 / 새로 시작) 대기
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
| 새 게임의 첫 구조 만들기 | `examples/game_skeleton/README.md`를 따라 `game/`으로 복사 (타이틀·플레이·결과, 일시정지, 저장, 번역, 게임 검사) |
| 게임 장면·규칙 추가 | `game/README.md`, `game/`; 첫 장면 연결은 `config/game.cfg`의 `app/main_scene` |
| 게임 전용 검사 | `game/tests/`(export 제외); 실행기 예시는 `examples/game_skeleton/tests/game_tests.gd` |
| 초기화 순서·게임 hook·서비스 선택 변경 | `scenes/bootstrap.gd`, `autoload/app.gd`, `autoload/game_config.gd` |
| 게임 진행 저장·migration·백업 복구 | `autoload/save_manager.gd`, `ui/popup/save_recovery_popup.gd`; 게임별 schema·변환 함수는 `game/`의 init script, `app/init_script`로 연결 |
| 저장 파일 입출력 자체 변경 | `core/storage/json_store.gd` |
| 사용자 설정·설정 화면 | `autoload/settings.gd`, `ui/settings/settings_panel.gd` |
| 언어·번역 | `autoload/settings.gd`의 `language`(빈 값은 기기 언어); 번역 등록 예시는 `examples/game_skeleton/game_init.gd`, `locale/*.po` |
| BGM·SFX·UI 사운드 | `autoload/audio_manager.gd`; 게임 음원은 `game/` 아래에 배치 |
| 장면 이동·로딩 화면 | `autoload/scene_manager.gd`, `ui/loading/loading.tscn` |
| 광고·결제 등 서비스 동작 | `services/<기능>/`의 Service → 기본 Adapter → Mock 순서로 읽기 |
| 게임 로그인·업적·리더보드 | `docs/GAME_SERVICES.md`, `services/game_services/`; 검증은 `tests/game_services_checks.gd`와 `tests/integration.tscn` |
| 네이티브 SDK 연결 | 해당 서비스의 새 Adapter + `autoload/app.gd`의 선택 코드; dependency 조사 문서 먼저 읽기 |
| Android 결제·광고·동의 | `docs/ANDROID_SERVICES.md`, `services/billing/android_billing_adapter.gd`, `services/ads/android_admob_adapter.gd`, `services/privacy/android_admob_privacy_adapter.gd` |
| Android 결제·광고 export | `addons/android_services/plugin.gd`, `addons/android_services/manifest.json`; JNI 계약 검사는 `core/platform/android_plugin.gd` |
| Android Play Games export·기기 진단 | `docs/ANDROID_PLAY_GAMES.md`, `addons/play_game_services/plugin.gd`, `scenes/android_game_services_probe.gd` |
| 상품 ID·타입 변경 | `config/products.json`(`android`, `onestore`, `ios`); 매핑은 `GameConfig.store_product_id()` |
| 구매 지급·중복 방지 구현 | `examples/purchase_ledger/`를 `game/`으로 복사; 검사는 `tests/purchase_ledger_checks.gd` |
| ONE store 결제 | `docs/ONESTORE.md`, `services/billing/onestore_billing_adapter.gd`, `native/android/onestore_iap/` |
| 스토어 배포·export preset | `docs/STORE_RELEASE.md`, `tools/configure.gd`, `export_presets.cfg` |
| AI 편집기 연결·MCP 교체 | `addons/godot_ai/`, `.codex/config.toml`, `.mcp.json` 및 [연결 절차](DEVELOPMENT.md#godot-mcp) |
| CI·문서 링크 검사 | `.github/workflows/ci.yml`, `tools/check_docs.py` |
| pause/resume·Android back | `autoload/app.gd`의 신호를 게임/UI에서 구독 |
| 플랫폼·진동·안전 영역 | `core/platform/mobile_platform.gd`, `ui/common/safe_area.gd` |
| 앱 이름·버전·패키지·방향 | `config/game.cfg`, `tools/configure.gd` |
| 동작 예제·회귀 검사 | `scenes/demo.gd`, `scenes/transition_demo.gd`, `tests/integration.gd`, `tests/fixtures/` |

`scenes/`와 `assets/demo/`는 프레임워크 검증 예제이며 통합 검사가 사용하므로 새 게임에서도 유지합니다. `docs/template/`은 템플릿 자체의 적용 절차·변경 기록·구현 계획·검증 기록이며 게임 문서가 아닙니다. `addons/play_game_services/`와 `addons/android_services/`는 고정 Android AAR·라이선스·export 연결을 소유합니다. `examples/`는 게임이 복사해 쓰는 레퍼런스, `native/`는 템플릿이 소유한 native 플러그인 소스이며 둘 다 export에서 제외됩니다. `core/events/`, `core/utils/`는 예약 디렉터리입니다.

## 설정을 바꿀 때

- **런타임 설정:** `GameConfig`가 `config/game.cfg`와 `config/products.json`을 시작 시 읽습니다. feature flag와 서비스 mode를 바꾼 후 앱을 재시작하세요.
- **게임 서비스:** `features/game_services_enabled`, `game_services`의 논리 ID Dictionary·timeout·플랫폼별 `*_native_verified`가 App → Service/Adapter에 전달됩니다. Android AAR는 export opt-in이며 플랫폼 gate는 기본 false입니다. ID의 플랫폼 키는 소문자 `android`, `ios`입니다.
- **Android 설정 전파:** exporter가 `config/game_services.local.cfg`의 허용된 ID·mode·gate만 `config/game_services.build.cfg`로 주입하고 GameConfig가 이를 읽습니다. `android_mode=native`로 다른 서비스 mode와 독립적으로 native를 선택합니다. Android Gradle preset의 `game_services/include_sdk=true`가 필요합니다.
- **Android 결제·광고 설정 전파:** `addons/android_services/plugin.gd`가 `config/android.local.cfg`의 billing/ads/privacy whitelist만 `android_services.build.cfg`로 주입합니다. App이 기능별 `android_mode`와 `android_native_verified`로 어댑터를 선택합니다. SDK 포함은 `billing/include_sdk`, `billing/onestore_include_sdk`, `ads/include_sdk`이며 개발용 preset은 모두 false입니다. 두 결제 SDK는 한 preset에 함께 넣을 수 없습니다.
- **스토어 구분:** `GameConfig.store()`는 iOS면 `app_store`, export custom feature `onestore`가 있으면 `onestore`, 그 외 `google_play`입니다. App은 ONE store에서 `OneStoreBillingAdapter`를 선택하고 BillingService는 해당 스토어의 상품 ID를 씁니다.
- **추가 공개 API:** `App.billing.query_products()`, `transaction_received`, `purchase_pending`, `finish_purchase(token)`, `get_unfinished_transactions()`는 수신·검증·스토어 완료를 분리합니다. `App.privacy.can_request_ads()`는 광고 자격이며 분석 동의인 `can_use_services()`와 별도입니다. 계약은 `docs/ANDROID_SERVICES.md`를 따릅니다.
- **프로젝트·export 설정:** 앱 이름·버전·build_number·package/bundle·orientation·main_scene·기능 플래그를 바꾸면 `tools/configure.gd`를 실행해 `project.godot`와 모든 Android/iOS preset에 반영합니다. 스토어 preset(`Android Google Play`, `Android ONE store`)이 없으면 만들고 Gradle·SDK 포함·데모 제외 filter를 맞춥니다. 기본·스토어 preset은 이름과 플랫폼으로 찾고, 진단(`probe`) preset은 보존합니다. 실행 후 diff를 확인하세요. CI가 커밋된 결과와 재실행 결과의 차이를 검사합니다.

- **로컬 빌드 환경:** JDK/SDK 경로는 Godot Editor Settings, signing은 로컬 export 자격 증명에서 관리합니다. 로컬 파일은 해당 exporter가 허용한 키만 빌드에 주입합니다. 일반 실행에서 임의의 local 파일을 자동 병합하지 않습니다.

```bash
godot --headless --path . --script res://tools/configure.gd
```

`godot`가 PATH에 없으면 실행 파일 경로로 대체합니다. macOS 기본 설치 경로는 `/Applications/Godot.app/Contents/MacOS/Godot`입니다.

## 코드를 연결하기 전에 확인할 계약

- **저장:** 게임별 `schema_version`과 migration은 `App.initialize()` 전에 등록해야 합니다. `game/`에 `RefCounted` script를 만들어 `before_app_initialize()`에서 등록하고 `app/init_script`에 경로를 지정합니다. bootstrap(F5)만 hook을 호출하며 실패 시 오류를 기록하고 초기화를 계속합니다. `set_value()`는 자동 저장 대상을 표시하지만 `data`를 직접 수정하면 `mark_dirty()`가 필요합니다. 사용자 설정은 별도 `Settings`로 저장합니다. 저장할 때마다 직전 파일을 `save.json.bak`으로 남기고, 원본이 없거나 JSON으로 읽히지 않으면 백업으로 복구한 뒤 `recovered_from_backup`을 보냅니다. 버전·migration 오류는 백업으로 되돌리지 않습니다.
- **초기화 실패:** App은 저장 load 실패 후에도 초기화 완료를 알리고 SaveManager는 쓰기를 차단합니다. bootstrap은 첫 장면 전에 `SaveRecoveryPopup`을 띄워 다시 시도 또는 확인 후 새로 시작을 기다립니다. 읽지 못한 원본은 `save.json.unreadable`로 남습니다. `[save] recovery_popup=false`면 팝업 없이 진행하므로 게임이 `SaveManager.write_blocked`를 처리해야 합니다. bootstrap을 거치지 않는 실행(F6, 검사)에서는 팝업이 없으므로 `ready_for_game`을 저장 성공의 증거로 사용하지 마세요.
- **언어:** `Settings`의 `language` 기본값은 빈 값이며 기기 locale을 적용합니다. 번역이 없는 언어는 프로젝트 fallback(`en`)으로 표시됩니다. 번역 리소스는 게임이 init script에서 등록합니다.
- **광고·동의:** 보상은 `rewarded_completed`에서 지급합니다. 광고는 privacy.can_request_ads(), 분석은 privacy.can_use_services()가 필요하며 `privacy_enabled=false`도 허용 상태가 아닙니다.
- **결제:** 게임은 logical 상품 ID를 전달합니다. Native는 transaction_received를 검증·저장한 뒤 finish_purchase를 호출하고 purchase_token으로 중복 지급을 방지합니다. Android native는 시작·재개 때 미완료 구매를 다시 보내므로 게임은 첫 장면에서 신호를 연결하고 `get_unfinished_transactions()`도 처리합니다. Native 복원 목록에는 스토어가 보유 중으로 반환한 완료 토큰도 포함됩니다. Mock은 transaction_id를 사용합니다. Mock 복원은 같은 실행 세션의 비소모성·구독 거래만 반환합니다.
- **Mock 선택:** `mode="mock"`인 debug 빌드에서 사용합니다. 모바일은 `allow_mobile_debug_mocks=true`도 필요합니다. release는 Mock을 선택하지 않습니다. Android 결제·광고·UMP는 기능별 native gate와 SDK 포함 옵션이 필요합니다.
- **일시정지·전환:** 모바일 pause 시 오디오가 멈추고, `App.paused` 동기 구독자가 기록한 변경까지 저장합니다. 게임 전체의 일시정지 정책은 게임이 정합니다. SceneManager는 메인 스레드에서 로드하고 `_process`를 사용합니다. `SceneTree.paused=true` 상태에서 장면 이동이 필요하면 process mode와 복귀 정책을 함께 검증하세요.

## 변경 후 검증

| 변경 범위 | 확인할 경로 |
| --- | --- |
| 게임 로직·UI | bootstrap부터 해당 게임 장면 실행, 변경한 입력·상태 전환 확인 |
| 저장·설정·오디오·장면·Mock | 아래 기본 통합 검사와 영향받는 데모 동작 |
| 초기화·feature flag·Adapter 선택 | 기본 검사 + `--disabled` + `--native` |
| Safe Area·터치·방향·lifecycle·export·native SDK | 대상 플랫폼 빌드와 실기기 확인; Desktop 검사로 대체하지 않음 |
| 문서만 변경 | 코드·경로 대조와 `python3 tools/check_docs.py`; 런타임 재검사 불필요 |
| export preset·configure 변경 | `python3 tests/test_configure.py`로 손상 파일 보존·최초 생성·preset 재정렬과 이름 충돌을 검사하고, configure 재실행 후 `project.godot`·`export_presets.cfg` diff가 없는지 확인 |

```bash
godot --headless --path . --editor --import --quit
godot --headless --path . --scene res://tests/integration.tscn
godot --headless --path . --scene res://tests/integration.tscn -- --disabled
godot --headless --path . --scene res://tests/integration.tscn -- --native
godot --headless --path . --scene res://examples/game_skeleton/tests/game_tests.tscn
python3 tools/check_docs.py
```

기본 통합 검사는 기본 상품 구성을 사용하는 Desktop debug Mock 시나리오입니다. 상품·설정을 게임에 맞춰 바꿨다면 테스트 입력도 검토하세요. 테스트 저장은 임시 경로에 격리됩니다. 종료 코드, `INTEGRATION` 완료 요약의 실패 0건, script/parse error 부재를 함께 확인합니다. `--native`는 SDK 미설치 실패 경로를 검사하며 실제 스토어 테스트가 아닙니다. 게임 스켈레톤 검사는 `GAME TESTS` 요약의 실패 0건을 확인합니다. 게임이 복사한 검사는 `res://game/tests/game_tests.tscn`으로 실행합니다.

Android 결제·광고·UMP·ONE store의 가짜 SDK 계약은 `tests/android_services_checks.gd`, 구매 지급 예제는 `tests/purchase_ledger_checks.gd`가 기본 검사에 포함됩니다. 세 SDK 동시 기기 검사는 `android_services_probe` feature와 `scenes/android_services_probe.tscn`을 사용합니다. 빌드·기기 절차는 `docs/ANDROID_SERVICES.md`, 실제 증거는 `docs/template/VALIDATION.md`를 따릅니다.

## 필요한 문서만 추가로 읽기

- 계층·초기화·저장·서비스 계약 변경: [ARCHITECTURE.md](ARCHITECTURE.md).
- dependency 선정·설치·버전 변경: [DEPENDENCIES.md](DEPENDENCIES.md), [README의 BOM](../README.md#dependency-bom).
- 템플릿 기능의 기존 검증 범위 판단·새 결과 기록: [template/VALIDATION.md](template/VALIDATION.md). 실행 환경·날짜와 직접 검증/사용자 보고를 구분하세요. 파생 게임의 검증은 게임 프로젝트의 문서(예: `docs/VALIDATION.md`, `docs/PLAYTEST_NOTES.md`)에 따로 기록합니다.
- 새 게임에 적용·버전 업데이트: [template/APPLYING.md](template/APPLYING.md), [template/CHANGELOG.md](template/CHANGELOG.md).
- 처음 실행·새 게임 생성: [README.md](../README.md). 상세 설정·API·플랫폼 export: [DEVELOPMENT.md](DEVELOPMENT.md).
- 스토어 제출 준비: [STORE_RELEASE.md](STORE_RELEASE.md). ONE store 결제: [ONESTORE.md](ONESTORE.md).

파일 이동, 진입 흐름, 공개 접근 API, 설정 반영 방식 또는 검증 명령을 바꾸면 같은 변경에서 이 지도를 갱신합니다. 정책과 dependency 버전, 테스트 결과 전문은 각 담당 문서에 유지합니다.
