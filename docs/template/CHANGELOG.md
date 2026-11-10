# Template Changelog

템플릿 버전별 변경 기록이다. 버전은 SemVer이며 `GameConfig.TEMPLATE_VERSION`, README와 함께 갱신한다.
`config/game.cfg`의 `app/version`은 게임 앱 버전이며 이 기록과 무관하다.
파생 게임을 업데이트할 때는 [적용 절차](APPLYING.md#템플릿-버전-업데이트)를 따른다.

## 미출시

### 추가

- `examples/game_skeleton/`: 타이틀 → 플레이 → 결과 흐름, 일시정지·Android back·백그라운드 처리, 저장 연결, `.po` 번역(en·ko),
  게임 전용 headless 검사 실행기(`tests/game_tests.tscn`). CI가 이 검사를 실행한다.
- 저장 백업: `SaveManager`가 저장마다 직전 파일을 `save.json.bak`으로 남기고, 원본이 없거나 JSON으로 읽히지 않으면 백업으로 복구한다.
  `recovered_from_backup(error)` 신호, `JsonStore.write(path, document, keep_backup)`.
- `ui/popup/save_recovery_popup.gd`(`SaveRecoveryPopup`): 저장 load 실패 시 bootstrap이 첫 장면 전에 표시한다. `[save] recovery_popup`으로 끌 수 있다.
- `SettingsPanel.languages`와 언어 목록의 `System` 항목.

### 변경

- `Settings`의 `language` 기본값을 `"en"`에서 빈 값(기기 언어)으로 바꿨다. 이전에는 기기 언어와 무관하게 영어 locale을 강제했다.
- load 실패 상태에서 `reset_slot()`을 호출하면 읽지 못한 원본을 `save.json.unreadable`로 보관한다.
- 모든 export preset의 exclude filter에 `game/tests/*` 추가.

### 파생 게임 업데이트 시 주의

- `config/game.cfg`의 `[save]`에 `recovery_popup=true`를 추가한다. 자체 복구 UI가 있으면 `false`로 둔다.
- 이미 실행한 기기의 `settings.cfg`에는 `language="en"`이 저장돼 있어 그대로 영어를 쓴다. 기기 언어를 따르게 하려면 게임이 한 번 빈 값으로 되돌린다.
- 원본 저장이 손상되면 이전에는 `load_failed`였던 경우가 백업 복구(`OK`)로 바뀐다. 손상 알림이 필요하면 `recovered_from_backup`을 구독한다.
- configure를 다시 실행해 `export_presets.cfg`의 exclude filter를 갱신한다.

### 수정

- 테스트: `Finished effects cleaned up`이 0.25초 효과음을 0.4초 고정 대기 뒤 확인해, 오디오 처리가 조금만 늦어도 실패했다(macOS 환경 점검에서 3회 중 2회). 효과음 정리를 최대 3초까지 기다리도록 바꿨다. 정리가 끝나면 바로 다음 검사로 넘어간다.

## 0.4.0 — 2026-11-04

### 추가

- 스토어 배포 preset: `Android Google Play`(Gradle·AAB), `Android ONE store`(Gradle·APK, custom feature `onestore`).
  `tools/configure.gd`가 없으면 만들고 SDK 포함 옵션을 기능 플래그·스토어 규칙에 맞춘다.
- `[app] build_number`: 모든 Android version code·iOS build number에 반영.
- 배포 preset(iOS 포함)은 `main_scene`이 데모가 아니면 데모·진단 장면과 `assets/demo/`를 자동 제외.
- ONE store 결제: `GameConfig.store()`·`store_product_id()`, `OneStoreBillingAdapter`, `products.json`의 `onestore` 키,
  `billing/onestore_include_sdk` export 옵션, 템플릿 소유 플러그인 소스 `native/android/onestore_iap/`(IAP SDK 21.04.00)와 `build.sh`. 기기 미검증.
- `BillingService.get_unfinished_transactions()`: 신호 연결 전에 수신된 미완료 거래 조회.
- `examples/purchase_ledger/`: 서버 없는 게임용 구매 지급·중복 방지·저장 후 finish 레퍼런스와 검사.
- Release export 경고: 닫힌 native gate, Google 샘플 광고, Game ID 없는 Play Games, ONE store preset의 Play Games.
- `.github/workflows/ci.yml`(headless 통합·configure 동기화·문서 링크), `tools/check_docs.py`.
- [스토어 배포 안내](../STORE_RELEASE.md), [ONE store 연동](../ONESTORE.md).

### 변경

- Android 결제 어댑터가 연결 직후와 resume마다 미완료 구매를 조용히 sync한다. resume에서 더 이상 `restore_completed`를 보내지 않는다.
- configure가 preset 번호 0/1만이 아니라 모든 Android·iOS preset을 갱신하고, 진단(`probe`) preset은 유지한다. `runnable` 값을 커밋해 재실행 diff를 없앴다.
- export exclude filter에 `examples/*`, `native/*` 추가.
- 문서: APPLYING의 태그 안내·파일 분류표, DEVELOPMENT의 오래된 Billing/AdMob 안내·설정 표·구조도, 깨진 앵커 수정.
- 의존성 버전은 바꾸지 않았다. 2026-11-04 최신 대조 결과는 [DEPENDENCIES.md](../DEPENDENCIES.md#최신-버전-재확인--2026-11-04).

### 파생 게임 업데이트 시 주의

- `config/game.cfg`에 `[app] build_number`, `[billing] onestore_product_ids`, `onestore_public_key` 키를 추가한다. 기존 version code를 쓰고 있었다면 그 값을 `build_number`로 옮긴다.
- configure를 실행하면 `export_presets.cfg`에 스토어 preset 두 개가 추가된다. 직접 만든 Gradle preset이 있으면 이름을 확인해 중복을 정리한다.
- resume 시 `restore_completed`에 의존했다면 `transaction_received`/`get_unfinished_transactions()`로 옮긴다.
- 게임 첫 장면에서 `transaction_received`를 연결하고 `get_unfinished_transactions()`도 같은 지급 경로로 처리한다.

## 0.3.0 — 2026-10-21

### 추가

- Android Google Play Billing 3.3.0 / Billing SDK 9.1.0 AAR, 어댑터, 상품 상세 조회·pending·취소·복원·acknowledge/consume 연결.
- `BillingService.transaction_received`와 `finish_purchase()`: 게임의 거래 검증·지급 기록 저장 후 스토어 완료 처리.
- Android Poing AdMob 5.1.0 ads/core AAR / Next-Gen Ads 1.4.0 / UMP 4.0.0 연결.
  동의 후 광고 초기화·로드, 보상 콜백 중복 방지, 전면 광고 닫힘, 재시도와 객체 폐기.
- `PrivacyService.can_request_ads()`와 `show_privacy_options()`. UMP 광고 자격과 분석 동의를 분리.
- `billing/include_sdk`, `ads/include_sdk` export opt-in, `android_mode`·`android_native_verified` gate와 whitelist 로컬 설정 주입.
- SDK 세 개를 함께 넣는 `android_services_probe` 진단 장면과 가짜 SDK 계약 검사.
- [Android 연동 안내](../ANDROID_SERVICES.md), 출처·라이선스·AAR 해시 manifest.

### 변경

- GPGS 플러그인 v3.4.0을 유지하고 Google games-v2 21.0.0 → 22.1.0, Gson 2.11.0 → 2.14.0으로 갱신.
- Godot 엔진은 4.7.2 유지. 기본 Mock·SDK 미포함·네이티브 gate false 유지.
- Release에서 MockBillingAdapter를 직접 생성해도 구매·복원을 성공시킬 수 없도록 클래스 자체 guard를 추가.

### 파생 게임 업데이트 시 주의

- 실제 구매 수신을 구매 검증 완료로 해석하지 않는다. 게임/서버가 검증과 중복 지급 방지·저장을 끝낸 뒤 finish를 호출한다.
- 기존 `can_use_services()`는 분석 동의에 유지하고 광고 gate에는 `can_request_ads()`를 사용한다.
- native 스토어 계정 기능과 UMP required/동의 변경은 해당 게임의 실제 ID로 검증한 뒤 활성화한다.
- 실제 export·기기 증거와 남은 범위는 [VALIDATION.md](VALIDATION.md)를 따른다.

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
