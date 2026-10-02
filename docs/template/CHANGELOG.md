# Template Changelog

템플릿 버전별 변경 기록이다. 버전은 SemVer이며 `GameConfig.TEMPLATE_VERSION`, README와 함께 갱신한다.
`config/game.cfg`의 `app/version`은 게임 앱 버전이며 이 기록과 무관하다.
파생 게임을 업데이트할 때는 [적용 절차](APPLYING.md#템플릿-버전-업데이트)를 따른다.

## 0.2.0 — 2026-10-02

### 추가

- `App.game_services`: 로그인·업적·리더보드 공통 Service, Debug Mock, Android/iOS Adapter 연결 코드.
- Android Godot Play Game Services v3.4.0 AAR와 export 연결(Gradle export opt-in), 기기 진단 장면.
- 게임 초기화 hook: `config/game.cfg`의 `app/init_script`에 지정한 `RefCounted` script의
  `before_app_initialize()`를 bootstrap이 `App.initialize()` 전에 호출한다. 기본값은 빈 값이다.
- [적용 절차](APPLYING.md): 가져오기 방법, 파일 분류, 출처 기록, 버전 업데이트.
- 루트 `CLAUDE.md`: Claude Code가 `AGENTS.md`를 불러오도록 `@AGENTS.md` import 줄만 둔다.

### 변경

- 템플릿 자체 문서를 `docs/template/`으로 이동했다.
  `docs/IMPLEMENTATION_PLAN.md` → `docs/template/IMPLEMENTATION_PLAN.md`,
  `docs/VALIDATION.md` → `docs/template/VALIDATION.md`.
  `docs/IMPLEMENTATION_PLAN.md`, `docs/VALIDATION.md` 경로는 파생 게임 문서용으로 비워 둔다.
- 저장 schema·migration 등록 위치를 bootstrap 수정에서 `app/init_script` hook으로 바꿨다.
- 데모 제목이 `GameConfig.TEMPLATE_VERSION`을 표시한다.

### 파생 게임 업데이트 시 주의

- 0.1.0에서 `scenes/bootstrap.gd`를 직접 고쳐 migration을 등록했다면 그 코드를 `game/`의 init script로 옮긴다.
- 템플릿 문서 경로를 참조하던 게임 문서·지침의 링크를 갱신한다.

## 0.1.0 — 2026-09-18

태그 없이 배포되었다. 해당 commit: `a5a42d3` (2026-09-16 최초), `9fde3f6` (2026-09-18 문서·Android 사용자 확인).

- Godot 4.7.2 / GDScript, Android·iOS 대상 scaffold.
- Autoload: GameConfig, Settings, SaveManager, AudioManager, SceneManager, App.
- 광고·결제·분석·동의·리뷰 Service와 Mock, release Mock 차단.
- bootstrap, 데모·전환 장면, headless 통합 검사, `tools/configure.gd`.
