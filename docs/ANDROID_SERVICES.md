# Android 결제·광고·동의 연동

기준: Godot **4.7.2**, 템플릿 **0.4.0**. iOS 결제·광고 바이너리는 포함하지 않는다. ONE store 결제는 [ONESTORE.md](ONESTORE.md), 스토어 제출은 [STORE_RELEASE.md](STORE_RELEASE.md)를 따른다.
게임은 `App.billing`, `App.ads`, `App.privacy`만 사용한다.
SDK 설치, export 성공, 기기 로딩, 스토어 계정 기능 검증은 서로 다른 상태이며 실제 결과는 [검증 기록](template/VALIDATION.md)을 따른다.

## 고정 의존성과 기본 gate

- GPGS 플러그인 v3.4.0 AAR + Google games-v2 **22.1.0**, Gson **2.14.0**.
- GodotGooglePlayBilling **3.3.0** + Google Play Billing **9.1.0**.
- Poing AdMob Android **5.1.0** ads/core AAR + Google Mobile Ads Next-Gen **1.4.0**,
  UMP **4.0.0**, ConstraintLayout **2.2.0**. 플러그인 공식 배포물의 조합을 유지한다.
- Debug의 기본 `services/mode="mock"`, 플랫폼별 `android_native_verified=false`를 유지한다.
  SDK가 미포함되거나 feature off이면 네이티브 API를 초기화하지 않는다. Release에서 Mock 구매는 성공하지 않는다.
- upstream의 별도 GDScript singleton이나 자동 다운로드 editor plugin을 등록하지 않는다.

## Android Gradle export

1. Godot **4.7.2.stable**과 일치하는 export templates 및 Android build template을 설치한다.
2. Editor Settings에서 JDK **17**, Android SDK 경로를 설정한다. 기준 template의 compile/target SDK는 **36**, 최소 SDK는 **24**다.
3. 스토어 배포는 configure가 만든 `Android Google Play` preset(Gradle·AAB)을 쓴다. 진단·실험용이면 Android preset을 복제하고 Gradle build를 켠다.
4. 필요한 기능의 `billing/include_sdk`, `ads/include_sdk`, `game_services/include_sdk`를 true로 선택한다.
   개발용 `Android` preset은 세 옵션 모두 false이고, 스토어 preset은 configure가 기능 플래그에 맞춘다.
5. Google Play 상품·테스터 설정과 아래 로컬 설정을 준비한다. 광고는 처음에 Google 샘플 ID를 사용한다.

게임 서비스의 Console ID·OAuth 설정은 기존 [ANDROID_PLAY_GAMES.md](ANDROID_PLAY_GAMES.md)를 따른다.
결제·광고는 Git에서 제외된 `config/android.local.cfg`에 설정한다.

```ini
[billing]
android_mode="native"
; 검증을 수행할 로컬 빌드에서만 연다. true 자체는 검증 증거가 아니다.
android_native_verified=true
android_product_ids={"REMOVE_ADS": "스토어의 실제 상품 ID"}
timeout_seconds=120.0

[ads]
android_mode="native"
android_native_verified=true
use_test_ads=true
; use_test_ads=false인 실제 광고 빌드는 다음 ID를 설정한다.
android_app_id=""
rewarded_unit_id=""
interstitial_unit_id=""
test_device_ids=[]
retry_seconds=30.0

[privacy]
tag_for_under_age_of_consent=false
```

exporter는 허용된 설정만 `config/android_services.build.cfg`로 주입한다.
local 원본은 export에서 제외하며, 포함하지 않은 SDK의 gate는 빌드 설정에서 false로 고정한다.
GameConfig는 같은 whitelist만 읽는다. 앱 이름·main scene·다른 기능 설정을 local 파일로 덮어쓰지 않는다.
샘플 광고의 App ID·광고 단위 ID는 Google 공식 테스트 값이다. 실제 ID를 Git에 넣지 않는다.

## Google Play Billing 계약

`config/products.json`이 logical ID와 상품 타입을 소유한다. Android ID는 로컬 `android_product_ids`로 바꿀 수 있다.
실제 가격과 offer는 `App.billing.query_products()`의 `products_updated(products)` 결과에서 읽는다.
응답의 `product_id`, `one_time_purchase_offer_details_list`, `subscription_offer_details`는 SDK 3.3.0의 실제 필드다.

| API / 신호 | 의미 |
| --- | --- |
| `query_products()` | 일회성 상품과 구독 상세를 순차 조회; 실패는 `products_failed(reason)` |
| `purchase(logical_id, options={})` | 상세 재조회 후 구매 화면 요청 |
| `purchase_pending(logical_id, transaction)` | pending 또는 suspended; 지급·consume 금지 |
| `transaction_received(logical_id, transaction)` | PURCHASED 수신. `verified=false`, `mock=false`; 게임이 서버 검증과 저장을 수행할 단계 |
| `finish_purchase(purchase_token) -> Error` | 게임이 검증·중복 지급 방지·지급 기록 저장을 마친 뒤 호출 |
| `purchase_completed(logical_id, transaction)` | 일회성 비소모성/구독 acknowledge 또는 소모성 consume 완료; `finished=true` |
| `restore_purchases()` | inapp/subs 순차 조회. 미완료 소모성도 검증 이벤트로 복구하고 복원 목록에는 비소모성/구독만 넣음 |
| `get_unfinished_transactions() -> Array` | 수신했지만 finish하지 않은 거래 사본. 신호 연결 전에 도착한 거래를 처리할 때 사용 |

게임은 `transaction_received`에서 purchase token, package, product, 수량, 구매 상태와 entitlement를 서버에서 검증한다.
검증된 지급 기록을 게임의 SaveManager schema 또는 서버에 내구성 있게 저장한 뒤 `finish_purchase()`를 호출한다.
재시작·복원으로 같은 토큰이 다시 올 수 있으므로 중복 지급 방지는 게임/서버가 소유한다.
기본 템플릿은 이 메서드를 자동 호출하지 않으며 검증 서버나 게임별 보상을 만들어내지 않는다.
`verified=true`는 게임이 위 계약에 따라 finish를 요청했다는 표시이며 어댑터가 별도 서버 검증을 했다는 의미가 아니다.
서버가 acknowledge/consume을 직접 수행하는 구성을 사용한다면 게임이 이 계약을 해당 서버 흐름과 맞춰야 한다.

`options`에는 `purchase_option_id`(일회성), `base_plan_id`(구독), `offer_id`, `is_offer_personalized`를 지정할 수 있다.
일반 offer가 유일하면 자동으로 선택한다. 후보가 여러 개이거나 선택한 옵션이 없으면 `purchase_options_required`로 거절한다.
임의의 첫 가격·구독 offer로 결제하지 않는다. 구독 변경·업그레이드 API는 이번 공통 계약에 포함하지 않는다.

어댑터는 플러그인 연결 직후와 앱 resume마다 보유 구매를 조용히 조회(sync)한다. 앱이 꺼진 동안 완료된 구매도 3일 자동 환불 기한 전에 `transaction_received`로 다시 온다.
sync는 `restore_completed`를 보내지 않으며 실패는 개발 로그로만 남긴다. sync 중 들어온 게임 요청은 `busy`로 실패하므로 재시도한다.
취소·연결 오류·미조회 상품·native 오류·최종 처리 실패를 실패 신호로 보낸다.
기본 timeout은 120초다. 응답에 요청 ID가 없으므로 timeout/연결 끊김 후 미완료 native 작업은 늦은 응답까지 잠근다.
응답이 영원히 없으면 앱을 재시작해야 한다. 다음 요청을 이전 성공 콜백으로 완료시키지 않는다.

## AdMob·UMP 계약

`App.privacy.request_consent()`가 매번 UMP 정보를 갱신하고 필요할 때만 동의 화면을 표시한다.
`App.privacy.show_privacy_options()`는 UMP가 요구하는 개인정보 선택 화면을 다시 연다.
이 플러그인 버전은 `canRequestAds`를 노출하지 않아 갱신된 NOT_REQUIRED/OBTAINED 상태만 광고 요청 자격으로 사용한다.
상태는 **ads_allowed**이며 개인화·분석 동의를 뜻하지 않는다. `can_request_ads()`와 `can_use_services()`를 구분한다.
Native UMP의 ads_allowed만으로 Analytics를 허용하지 않는다.

- 동의 전에는 AdMob initialize/load를 호출하지 않는다. UMP 오류·미확정 상태는 광고를 차단한다.
- 초기화 후 보상형·전면 광고를 로드하고 SDK loaded 콜백이 있어야 readiness가 true다.
- load 실패는 기본 30초 후 재시도한다. 60초 이상 응답 없는 load는 폐기하고 다시 요청한다.
- full-screen 광고는 하나만 표시한다. 보상형은 유효한 matching UID의 reward 콜백에서 한 번만 완료한다.
- 보상 없이 닫힘·표시 오류는 실패다. 전면 광고는 matching close 콜백에서만 closed를 보낸다.
- 광고 객체는 한 번 사용하고 폐기·재로드한다. 55분 지난 객체와 동의 변경으로 무효화된 객체는 재사용하지 않는다.
- 배너·미디에이션·iOS 광고는 이번 범위 밖이다.

## 기기 진단

별도 preset에 `custom_features="android_services_probe"`와 위 세 SDK 포함 옵션을 켠다.
패키지는 일반 게임과 다른 `com.example.mobiletemplate.androidservicesprobe.debug` 등으로 지정한다.
이 feature는 bootstrap에서 `android_services_probe.tscn`으로 분기한다.

```bash
godot --headless --path . --export-debug 'Android Services Debug' build/android/services-debug.apk
godot --headless --path . --export-release 'Android Services Release' build/android/services-release.apk
adb install -r build/android/services-debug.apk
adb shell am start -W -n com.example.mobiletemplate.androidservicesprobe.debug/com.godot.game.GodotAppLauncher
```

진단 앱은 실제 구매 화면을 시작하지 않고 상품 조회만 한다. 미등록 테스트 패키지의 조회 실패는 실제 결제 검증이 아니다.
UMP 결과는 별도로 표시한다. Google 샘플 App ID로 UMP 설정 조회가 실패할 수 있다.
광고는 UMP 갱신 결과가 허용됐을 때 자동으로 로드한다. UMP 오류가 나면 실제 AdMob 앱의 설정을 확인하고 다시 요청한다.
NOT_REQUIRED에서의 성공은 동의 화면 표시·거부·개인정보 선택 변경 검증을 대신하지 않는다.
Release 진단 APK 역시 별도 테스트 인증서로 서명하며 스토어 배포 signing과 구분한다.

## Release export 경고

Release export에서 exporter는 다음을 경고한다. 경고가 있는 산출물은 스토어에 올리지 않는다.

- 결제·광고 SDK를 포함했지만 해당 native gate가 닫혀 있음(release에서 `unavailable`).
- `ads/use_test_ads=true`로 Google 샘플 광고 App ID가 들어감.
- Play Games SDK를 포함했지만 Game ID가 없음, 또는 ONE store preset에 Play Games SDK가 들어감.
