# 템플릿 적용 절차

이 템플릿을 새 게임 또는 기존 게임 저장소에 가져오고, 이후 템플릿 버전을 올릴 때 따르는 절차다.
사람과 AI Agent 모두 이 문서를 기준으로 한다. 버전별 변경은 [CHANGELOG.md](CHANGELOG.md)를 본다.

## 원칙

- GitHub의 template repository 기능을 전제하지 않는다. 아래의 clone → 복사 방법을 사용한다.
- 템플릿의 Git 이력(`.git/`)과 Editor cache(`.godot/`)는 가져오지 않는다. 게임 저장소의 기존 파일·이력·remote를 보존한다.
- 출처는 **저장소 URL + 태그 + commit hash**로 기록한다. 태그가 없는 commit을 쓰면 hash만 기록한다.
- 템플릿 자체 문서(`docs/template/`)는 출처 참고용이다. 게임의 구현 계획·설계·검증 기록으로 사용하지 않는다.
- scaffold 검증(아래 검증 명령)과 Android/iOS export·네이티브 서비스·실기기 검증은 따로 보고한다.

## 1. 템플릿 받기

저장소가 private이면 인증된 접근이 필요하다. 접근할 수 없으면 적용하지 말고 사용할 버전과 차단 사유만 기록한다.

먼저 원격 태그를 확인하고, 원하는 버전의 태그가 있으면 그 태그로 받는다.

```bash
git ls-remote --tags https://github.com/harpuria/godot-mobile-template
git clone --depth 1 --branch v0.4.0 https://github.com/harpuria/godot-mobile-template /tmp/godot-mobile-template
git -C /tmp/godot-mobile-template rev-parse HEAD
```

`v0.4.0` 대신 원하는 태그를 지정한다. 태그가 목록에 없으면(`Remote branch v0.4.0 not found`) `--branch main`으로 받고,
`autoload/game_config.gd`의 `TEMPLATE_VERSION`과 `rev-parse` 결과를 함께 기록한다. 태그가 없다고 적용을 중단하지 않는다.

## 2. 프로젝트로 복사하기

**새 프로젝트(빈 폴더):** `.git/`, `.godot/`을 제외하고 전부 복사한 뒤, 사용자가 동의하면 Git을 초기화한다.

```bash
rsync -a --exclude .git --exclude .godot /tmp/godot-mobile-template/ ./
```

**기존 저장소:** 기존 파일을 덮어쓰지 않도록 복사한다. 이름이 겹친 파일은 아래 표대로 직접 병합한다.

```bash
rsync -a --ignore-existing --exclude .git --exclude .godot /tmp/godot-mobile-template/ ./
```

기존 게임이라면 템플릿 전체 도입이 자동 migration은 아니다. 요청 범위에 필요한 Service·관리자만 가져오고 기존 구조를 유지한다.

## 3. 파일 분류

| 경로 | 처리 | 이유 |
| --- | --- | --- |
| `autoload/`, `core/`, `services/`, `ui/`, `tools/` | 유지 | 프레임워크. 게임 변경은 `game/`에서 한다 |
| `addons/play_game_services/` | 유지 | Android Play Games AAR, export opt-in. 기본 export에는 SDK 미포함 |
| `addons/android_services/` | 유지 | Android 결제·AdMob AAR, 라이선스·해시와 export opt-in. 기본 SDK 포함/gate는 false. `onestore/bin/`은 로컬 빌드 출력(Git 제외) |
| `native/android/onestore_iap/` | 유지 (ONE store 미사용이면 제외 가능) | ONE store 결제 플러그인 소스와 `build.sh`. export 제외 |
| `examples/` | 유지 | `game/`으로 복사해 쓰는 레퍼런스(게임 스켈레톤, 구매 처리). 통합 검사·CI가 사용하며 export 제외 |
| `.github/workflows/ci.yml` | 유지 (기존 CI가 있으면 병합) | headless 통합 검사·configure 동기화·문서 링크 검사 |
| `scenes/bootstrap.*` | 유지, 수정하지 않음 | 진입점. 게임 초기화는 `app/init_script` hook 사용 |
| `scenes/main.tscn`, `scenes/demo.gd`, `scenes/transition_demo.*`, `assets/demo/` | 유지 | 통합 검사가 사용한다. 삭제하면 `tests/integration.tscn`이 실패한다 |
| `scenes/android_game_services_probe.*`, `scenes/android_services_probe.*` | 유지 | `pgs_probe`, `android_services_probe` export feature 전용 기기 진단. 배포 preset에서는 자동 제외 |
| `tests/` | 유지 | 프레임워크 회귀 검사. 게임 검사는 별도 파일로 추가 |
| `project.godot`, `export_presets.cfg` | 유지 (기존 Godot 프로젝트면 병합) | Autoload·렌더러·export 설정. 개발용 Android/iOS와 `Android Google Play`, `Android ONE store` preset. 값은 `tools/configure.gd`로 갱신 |
| `config/game.cfg`, `config/products.json` | 게임 값으로 수정 | 아래 4단계 |
| `config/*.local.cfg` | 템플릿에 없음. 게임이 로컬에서 생성 | 운영 ID·공개 키·native gate. Git과 export에서 제외 |
| `game/` | 게임 코드 작성 위치 | `game/README.md`의 API 안내 유지. 게임 검사는 `game/tests/`(export 제외) |
| `AGENTS.md` | 게임 지침의 기반으로 병합 | Boundaries·Dependencies·Commands 규칙 유지, 게임 결정 추가. 유일한 지침 원본 |
| `CLAUDE.md` | 유지 (기존 파일이면 `@AGENTS.md` 줄만 추가) | Claude Code가 AGENTS.md를 불러오는 import 줄. 지침을 여기에 중복하지 않는다 |
| `README.md` | 게임 소개로 교체 가능 | 개발 문서 링크와 `Dependency BOM` 섹션은 유지(AGENTS가 참조) |
| `docs/ARCHITECTURE.md`, `docs/CODEBASE_MAP.md`, `docs/DEVELOPMENT.md`, `docs/DEPENDENCIES.md`, `docs/GAME_SERVICES.md`, `docs/ANDROID_PLAY_GAMES.md`, `docs/ANDROID_SERVICES.md`, `docs/STORE_RELEASE.md`, `docs/ONESTORE.md`, `docs/PGS_ANDROID_DEPENDENCIES.txt`, `docs/ANDROID_SERVICES_DEPENDENCIES.txt` | 유지 | 프레임워크 계약·의존성 근거·스토어 배포 절차 |
| `docs/template/` | 유지 (읽기 전용 참고) | 출처 버전의 변경·계획·검증 기록. 게임 문서를 여기에 쓰지 않는다 |
| `.gitignore`, `.gitattributes`, `.editorconfig` | 유지 (기존 파일이면 병합) | Godot cache·build·서명 파일 제외 규칙 |

게임의 구현 계획·검증 기록은 `docs/IMPLEMENTATION_PLAN.md`, `docs/VALIDATION.md` 등 게임 문서로 새로 만든다.

## 4. 게임에 맞게 설정하기

1. `config/game.cfg`의 `[app]`을 바꾼다: `name`, `version`(게임 앱 버전), `build_number`, `android_package`, `ios_bundle`(`com.example.*` 금지), `orientation`, `main_scene`.
2. 사용하지 않는 기능은 `[features]`에서 `false`로 바꾼다. 상품은 `config/products.json`에서 정의한다(`android`, `onestore`, `ios` 키). 배포 preset의 SDK 포함 옵션은 이 기능 플래그를 따른다.
3. 새 게임은 [examples/game_skeleton](../../examples/game_skeleton/README.md)을 `game/`으로 복사해 시작한다(복사 명령·`main_scene`·`init_script` 값은 그 README). 직접 구조를 만든다면 저장 schema·migration이 필요할 때 `game/`에 init script를 만들고 `[app] init_script`에 경로를 지정한다. 예시는 [game/README.md](../../game/README.md).
4. 설정을 `project.godot`와 `export_presets.cfg`에 반영하고 diff를 확인한다.

```bash
godot --headless --path . --script res://tools/configure.gd
```

실제 게임 서비스 ID·signing 정보는 Git에 넣지 않는다. 절차는 [DEVELOPMENT.md](../DEVELOPMENT.md#configuration)와 [ANDROID_PLAY_GAMES.md](../ANDROID_PLAY_GAMES.md)를 따른다.
`main_scene`을 게임 장면으로 바꾸고 configure를 실행하면 배포 preset에서 데모 장면·음원이 자동 제외된다.
결제를 쓰면 [examples/purchase_ledger](../../examples/purchase_ledger/README.md)를 `game/`으로 복사한다. 스토어 제출 전에는 [STORE_RELEASE.md](../STORE_RELEASE.md)의 점검표를 따른다.

## 5. 출처 기록

게임의 `AGENTS.md` 프로젝트 정보에 한 줄로 기록한다.

```text
- Template: godot-mobile-template v0.4.0 (https://github.com/harpuria/godot-mobile-template, commit <hash>), applied <YYYY-MM-DD>.
```

템플릿 파일을 의도적으로 바꾸거나 제외했다면 같은 곳에 짧게 남긴다.

## 6. 검증

```bash
godot --headless --path . --editor --import --quit
godot --headless --path . --scene res://tests/integration.tscn
godot --headless --path . --scene res://tests/integration.tscn -- --disabled
godot --headless --path . --scene res://tests/integration.tscn -- --native
godot --headless --path . --scene res://examples/game_skeleton/tests/game_tests.tscn
python3 tools/check_docs.py
```

게임 스켈레톤을 복사했다면 `res://game/tests/game_tests.tscn`도 실행한다.
종료 코드 0, `INTEGRATION`·`GAME TESTS` 요약의 실패 0건, `SCRIPT ERROR`·`Parse Error` 부재를 확인한다.
상품·기능 설정을 바꿨다면 통합 검사의 기본 상품 가정과 맞는지 확인한다.
F5로 bootstrap부터 실행해 `main_scene`이 열리고 init script 오류가 없는지 본다.
이 결과는 Desktop scaffold 검증이다. export·네이티브·실기기 결과로 보고하지 않는다.

## 템플릿 버전 업데이트

1. 현재 기록된 버전과 목표 버전 사이의 [CHANGELOG.md](CHANGELOG.md) 항목, 특히 “파생 게임 업데이트 시 주의”를 읽는다.
2. 템플릿 clone에서 두 버전의 프레임워크 변경만 확인한다.

```bash
git -C /tmp/godot-mobile-template fetch --tags
git -C /tmp/godot-mobile-template diff v0.3.0 v0.4.0 -- autoload core services ui scenes tests tools addons examples native project.godot export_presets.cfg docs .github
```

3. 프레임워크 경로의 변경을 게임에 적용한다. `game/`과 게임이 바꾼 `config/` 값, 게임 문서는 덮어쓰지 않는다.
   `config/game.cfg`에 새로 생긴 키만 추가한다.
4. 위 검증 명령을 실행하고 게임을 F5로 확인한다.
5. 출처 기록의 버전·commit·날짜를 갱신한다.
