# Architecture — Mobile Template 0.4.0

## Layer 책임

```text
Game Layer
    ↓
Service Layer
    ↓
Adapter Layer
    ↓
External Plugin / Native SDK
```

> Game code must never directly depend on a mobile platform plugin.

- **Game (`game/`)**: 게임 규칙, 보상, 저장 데이터 schema, 상품별 entitlement와 중복 지급 정책.
- **Service (`services/`)**: 게임 친화적인 요청/결과 신호, feature flag, 동의 gate, logical product mapping, 동시 작업 제어.
- **Adapter**: SDK 호출, SDK 상태/콜백을 공통 결과로 변환. 광고·결제·동의는 Mock/unavailable와 Android native 구현을 제공한다. 결제는 Google Play와 ONE store 어댑터가 같은 계약을 따른다. Android SDK는 export opt-in이고 검증 범위는 VALIDATION에 기록한다. iOS 바이너리는 미설치다.
- **Plugin/SDK (`addons/`, 향후 iOS native 위치)**: 정확히 고정한 검증 dependency. game 코드에서 접근 금지.
  템플릿이 직접 소유한 플러그인 소스는 `native/`에 두고 로컬 빌드 산출물만 `addons/`로 출력한다.

App은 구성 지점이다. singleton 하나에 게임 규칙을 모으지 않으며 Service instance만 생성·소유한다.
게임은 `App.ads` (AdsService), `App.billing` (BillingService), `App.analytics`, `App.privacy`, `App.review`, `App.game_services` (GameServicesService)를 사용한다.
광고 또는 결제 플러그인을 교체해도 게임의 호출 지점은 유지한다.

## Initialization

Autoload 순서: GameConfig → Settings → SaveManager → AudioManager → SceneManager → App.
bootstrap은 `app/init_script`의 게임 hook(`before_app_initialize()`)을 호출해 게임별 schema·migration을 등록한 다음
`App.initialize()` → 저장 load → 설정의 main_scene으로 이동한다. hook은 `game/`의 RefCounted script이며 프레임워크 파일을 고치지 않고 연결한다.
hook 실패는 오류로 기록하고 초기화를 계속한다. 이 경우 미등록 schema의 저장은 기존 load 실패 정책대로 쓰기가 차단된다.
initialize는 중복 호출해도 서비스를 다시 만들지 않는다.
기능 off이면 외부 SDK나 Mock을 초기화하지 않고 unavailable 기본 adapter를 연결한다.
release는 Mock을 선택하지 않는다. SDK 없는 release 구매를 성공으로 간주하지 않는다.
feature flag는 시작 시 확정하며 런타임 재구성 API를 만들지 않았다.

## 상태와 수명

- App과 공통 관리자는 앱 수명이며 장면 변경으로 사라지지 않는다.
- SceneManager는 요청 수락 직후 transitioning=true, 중복은 ERR_BUSY, scene_changed 이후 완료 신호.
- loading overlay를 그릴 두 프레임을 허용한 뒤 메인 스레드에서 ResourceLoader.load한다.
  threaded load 경로에서 이 4.7.2 환경의 종료 RefCounted 경고가 관찰되어 v0.1.0은 단순 load를 선택했다.
  대형 장면 streaming은 별도 요구가 생겼을 때 검증 후 추가한다.
- Android back은 `App.back_requested` 신호로 전달한다. 게임/UI가 팝업 닫기와 이동 정책을 결정한다.
- pause는 SaveManager.flush와 AudioManager 일시 정지, resume은 오디오 재개를 수행한다.
  앱 전체 SceneTree를 pause하지 않으므로 게임 시뮬레이션의 멈춤 정책은 게임이 결정한다.
- 모바일 진동은 MobilePlatform을 사용하며 Settings를 존중한다. SafeArea는 resize마다 계산한다.

## Persistence 경계

SaveManager는 단일 JSON 슬롯과 version envelope만 소유한다. game이 schema와 migration Callable을 등록한다.
Settings는 별도 ConfigFile이며 저장 게임 초기화와 독립적이다.
기본 JsonStore는 임시 파일 기록 후 rename한다. read/parse/schema 실패 후에는 원본을 덮어쓰지 않는다.
쓰기 금지는 사용자 복구 결정 또는 정상 load로 해제한다. 앱은 실패를 감추지 않고 신호를 UI에 노출한다.
JSON은 Resource/object 저장, 암호화, 서버 저장을 대신하지 않는다.

## 서비스 계약

Ads: 요청 전 readiness 및 privacy 확인. 보상은 SDK reward callback을 검증한 completed에서만 발생해야 한다.
Mock은 단일 busy 상태로 rewarded/interstitial 동시 표시를 차단한다.
Billing: logical ID를 현재 스토어(`GameConfig.store()`)의 store ID로 매핑하고 상품 조회·구매·복원을 직렬화한다.
스토어는 빌드 단위로 고정한다. Android 스토어 구분은 export custom feature(`onestore`)이며 런타임에 바꾸지 않는다.
Android native는 시작·재개 때 미완료 구매를 조용히 다시 수신한다(sync). sync는 restore 결과 신호를 보내지 않는다.
Native는 transaction_received(미검증 수신) → 게임/서버 검증·지급 기록 저장 → finish_purchase → acknowledge/consume 완료 순서다.
구매 성공은 거래 Dictionary로 전달하며 game이 entitlement 및 idempotency를 정의한다.
Mock 복원은 세션 메모리의 비소모성/구독 거래만 반환한다.
Analytics: 동의 전 호출은 false, 허용된 Mock은 이름만 로그로 기록한다.
Privacy: unknown/granted/denied/disabled/unavailable와 native UMP의 ads_allowed 상태를 제공한다.
can_request_ads는 광고 자격이고 can_use_services는 분석 동의다. ads_allowed를 분석 동의로 승격하지 않는다.
SDK별 세부 상태와 동의 UI는 adapter 소유다.
Review: 요청 처리 결과만 제공하며 리뷰 창 표시 또는 작성 완료를 보장하지 않는다.
Game services: 명시적 로그인, 일반 업적 해제, 논리 ID의 점수 제출과 플랫폼 화면 요청을 제공한다.
요청은 직렬화하고 요청 ID로 결과를 연결한다. 타임아웃 난 OS 요청의 콜백을 새 요청에 재사용하지 않는다.
Mock은 Debug에서만 성공할 수 있고 실제 업적 보상/진행 저장은 game 소유다.
Android/iOS native는 플랫폼별 초기화 gate 기본 false다. Android AAR는 별도 Gradle preset의 SDK 포함 옵션으로 선택한다.
GameConfig는 exporter가 주입한 whitelist 설정을 읽고 `android_mode=native`로 게임 서비스만 native로 선택할 수 있다.
기본 흐름에는 새 singleton을 추가하지 않는다. `pgs_probe` feature는 App 초기화 전에 별도 진단 장면으로 분기한다.
API, 화면 요청 의미 및 iOS 점수 범위는 [GAME_SERVICES.md](GAME_SERVICES.md)를 따른다.

Android native billing의 pending/transaction update/finish/restore, 광고의 init/load/retry/재개/동의 변경 정책은 각 어댑터가 소유한다.
SDK 정보 수신과 실제 스토어/계정 검증은 구분한다. 자세한 계약은 [ANDROID_SERVICES.md](ANDROID_SERVICES.md)를 따른다.

## 확장 절차

1. 먼저 기존 공개 API로 게임 요구를 구현한다.
2. framework 변경이 필요한 경우에만 core/services 경계를 수정한다.
3. 새 adapter는 해당 기본 adapter를 상속하고 실제 tag API를 확인한다.
4. App 구성 지점에서 feature/mode/platform별로 명시적으로 선택한다.
5. 신호 전달, feature off, SDK 없음, 지연/중복 콜백을 검증한다.
6. 양 플랫폼 export 및 기기 검증을 수행하고 전체 dependency BOM을 갱신한다.

의미 없는 EventBus, duplicate singleton, genre-specific manager는 추가하지 않는다.
실제 사용 사례가 생기기 전에는 빈 events/utils/popup 디렉터리에 코드를 채울 필요가 없다.
