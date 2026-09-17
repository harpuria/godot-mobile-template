# Codebase Map

새 작업을 시작하는 AI Agent를 위한 코드 진입 안내서입니다. 규칙은 [AGENTS.md](../AGENTS.md), 설치·실행은 [README.md](../README.md)가 기준입니다. 아래에서 작업 대상을 찾고 관련 파일부터 읽으세요.

## 실행 흐름과 소유권

```text
project.godot
  ├─ Autoload 준비: GameConfig → Settings → SaveManager → AudioManager → SceneManager → App
  └─ scenes/bootstrap.tscn → scenes/bootstrap.gd
       ├─ App.initialize()
       │    ├─ 방향 설정 및 서비스/Adapter 생성
       │    └─ SaveManager.load_slot() → initialized 신호
       └─ SceneManager.change_scene(config의 app/main_scene)
            └─ 기본값: scenes/main.tscn → scenes/demo.gd
```

- Autoload는 [project.godot](../project.godot)에 등록된 앱 수명의 인스턴스입니다. `SaveManager`, `Settings`, `AudioManager`, `SceneManager`를 직접 사용합니다.
- `AdsService`, `BillingService` 등은 클래스 이름입니다. [App](../autoload/app.gd)이 서비스 인스턴스를 소유하며 게임은 `App.ads`, `App.billing`, `App.analytics`, `App.privacy`, `App.review`로 접근합니다. 서비스는 `App.initialize()` 이후 사용할 수 있습니다.
- `App.initialize()`는 중복 실행을 방지합니다. 새 게임의 진입점은 `app/main_scene`으로 지정하고 bootstrap부터 실행합니다.
- `core/`와 `ui/`의 클래스는 필요할 때 생성·사용하는 공통 코드입니다. 별도 singleton으로 등록되어 있지 않습니다.

## 작업별 시작 위치

경로는 저장소 루트 기준입니다. 게임 규칙·데이터는 `game/`에 두고, 공통 동작을 바꿔야 할 때만 관리자를 수정합니다.

| 작업 | 먼저 읽을 파일 / 수정 위치 |
| --- | --- |
| 게임 장면·규칙 추가 | `game/README.md`, `game/`; 첫 장면 연결은 `config/game.cfg`의 `app/main_scene` |
| 초기화 순서·서비스 선택 변경 | `scenes/bootstrap.gd`, `autoload/app.gd`, `autoload/game_config.gd` |
| 게임 진행 저장·migration | `autoload/save_manager.gd`; 게임별 schema·변환 함수는 `game/`, 등록 시점은 아래 계약 참고 |
| 저장 파일 입출력 자체 변경 | `core/storage/json_store.gd` |
| 사용자 설정·설정 화면 | `autoload/settings.gd`, `ui/settings/settings_panel.gd` |
| BGM·SFX·UI 사운드 | `autoload/audio_manager.gd`; 게임 음원은 `game/` 아래에 배치 |
| 장면 이동·로딩 화면 | `autoload/scene_manager.gd`, `ui/loading/loading.tscn` |
| 광고·결제 등 서비스 동작 | `services/<기능>/`의 Service → 기본 Adapter → Mock 순서로 읽기 |
| 네이티브 SDK 연결 | 해당 서비스의 새 Adapter + `autoload/app.gd`의 선택 코드; dependency 조사 문서 먼저 읽기 |
| 상품 ID·타입 변경 | `config/products.json`; 매핑 로직은 `services/billing/billing_service.gd` |
| pause/resume·Android back | `autoload/app.gd`의 신호를 게임/UI에서 구독 |
| 플랫폼·진동·안전 영역 | `core/platform/mobile_platform.gd`, `ui/common/safe_area.gd` |
| 앱 이름·버전·패키지·방향 | `config/game.cfg`, `tools/configure.gd` |
| 동작 예제·회귀 검사 | `scenes/demo.gd`, `scenes/transition_demo.gd`, `tests/integration.gd` |

`scenes/`와 `assets/demo/`는 프레임워크 검증 예제입니다. `addons/`는 현재 외부 SDK가 없는 자리이며, `core/events/`, `core/utils/`, `ui/popup/`은 예약 디렉터리입니다.

## 설정을 바꿀 때

- **런타임 설정:** `GameConfig`가 `config/game.cfg`와 `config/products.json`을 시작 시 읽습니다. feature flag와 서비스 mode를 바꾼 후 앱을 재시작하세요.
- **프로젝트·export 설정:** 앱 이름·버전·package/bundle·orientation을 바꾸면 `tools/configure.gd`를 실행해 `project.godot`와 `export_presets.cfg`에 반영합니다. 이 도구는 export 경로와 include/exclude filter도 기록하므로 실행 후 diff를 확인하세요.
- **로컬 빌드 환경:** JDK/SDK 경로는 Godot Editor Settings, signing은 로컬 export 자격 증명에서 관리합니다. `config/*.local.*` 파일을 만드는 것만으로 설정이 자동 합쳐지지는 않습니다.

```bash
rtk proxy godot --headless --path . --script res://tools/configure.gd
```

`godot`가 PATH에 없으면 실행 파일 경로로 대체합니다. macOS 기본 설치 경로는 `/Applications/Godot.app/Contents/MacOS/Godot`입니다.

## 코드를 연결하기 전에 확인할 계약

- **저장:** 게임별 `schema_version`과 migration은 bootstrap의 `App.initialize()` 전에 등록해야 합니다. 현재 전용 게임 초기화 hook은 없습니다. `set_value()`는 자동 저장 대상을 표시하지만 `data`를 직접 수정하면 `mark_dirty()`가 필요합니다. 사용자 설정은 별도 `Settings`로 저장합니다.
- **초기화 실패:** 현재 App은 저장 load 실패 후에도 초기화 완료를 알립니다. SaveManager는 쓰기를 차단하지만 복구 UI는 제공하지 않습니다. `ready_for_game`을 저장 성공의 증거로 사용하지 마세요.
- **광고·동의:** 보상은 `rewarded_completed`에서 지급합니다. 광고·분석은 privacy의 granted 상태가 필요하며 `privacy_enabled=false`도 허용 상태가 아닙니다.
- **결제:** 게임은 logical 상품 ID를 전달하고 `transaction_id` 기준 중복 지급 방지를 담당합니다. Mock 복원은 같은 실행 세션의 비소모성·구독 거래만 반환합니다.
- **Mock 선택:** `mode="mock"`인 debug 빌드에서 사용합니다. 모바일은 `allow_mobile_debug_mocks=true`도 필요합니다. release는 Mock을 선택하지 않으며 현재 native Adapter는 미구현입니다.
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
rtk proxy godot --headless --path . --editor --import --quit
rtk proxy godot --headless --path . --scene res://tests/integration.tscn
rtk proxy godot --headless --path . --scene res://tests/integration.tscn -- --disabled
rtk proxy godot --headless --path . --scene res://tests/integration.tscn -- --native
```

기본 통합 검사는 기본 상품 구성을 사용하는 Desktop debug Mock 시나리오입니다. 상품·설정을 게임에 맞춰 바꿨다면 테스트 입력도 검토하세요. 테스트 저장은 임시 경로에 격리됩니다. 종료 코드, `INTEGRATION` 완료 요약의 실패 0건, script/parse error 부재를 함께 확인합니다. `--native`는 SDK 미설치 실패 경로를 검사하며 실제 스토어 테스트가 아닙니다.

## 필요한 문서만 추가로 읽기

- 계층·초기화·저장·서비스 계약 변경: [ARCHITECTURE.md](ARCHITECTURE.md).
- dependency 선정·설치·버전 변경: [DEPENDENCIES.md](DEPENDENCIES.md), [README의 BOM](../README.md#dependency-bom).
- 기존 검증 범위 판단·새 결과 기록: [VALIDATION.md](VALIDATION.md). 실행 환경·날짜와 직접 검증/사용자 보고를 구분하세요.
- 처음 실행·새 게임 생성: [README.md](../README.md). 상세 설정·API·플랫폼 export: [DEVELOPMENT.md](DEVELOPMENT.md).

파일 이동, 진입 흐름, 공개 접근 API, 설정 반영 방식 또는 검증 명령을 바꾸면 같은 변경에서 이 지도를 갱신합니다. 정책과 dependency 버전, 테스트 결과 전문은 각 담당 문서에 유지합니다.
