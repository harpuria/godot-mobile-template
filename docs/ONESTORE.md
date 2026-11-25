# ONE store 결제 연동

기준: Godot **4.7.2**, 템플릿 **0.5.0**, ONE store IAP SDK **21.04.00** (API v7).
상태: **Unverified.** 플러그인 소스는 실제 SDK·Godot 4.7.2 클래스로 컴파일 검사만 했다. ONE store 기기 결제·로그인·업데이트 흐름은 검증하지 않았다.
기기 검증 전에는 `android_native_verified`를 운영 빌드에서 열지 않는다.

## 구조

```text
App.billing (BillingService)
  └─ OneStoreBillingAdapter        services/billing/onestore_billing_adapter.gd
       └─ AndroidBillingAdapter 흐름 재사용 (sync·수신·검증 대기·finish)
            └─ GodotOneStoreIap   native/android/onestore_iap (Java, Godot plugin v2)
                 └─ com.onestorecorp.sdk:sdk-iap:21.04.00 (Maven Central)
```

- 플러그인은 GodotGooglePlayBilling 3.3.0과 **같은 메서드·신호·Dictionary 키**를 제공한다. 그래서 게임 API와 구매 계약은 Google Play와 같다.
- 차이: `setPublicKey(key)` 추가, pending 상태 없음, offer 선택 없음(상품당 후보 1개).
- 실패 이유: `store_login_required`(10), `store_update_required`(11), `store_blocked_app`(13), `store_sandbox_unsupported`(14), 그 외 `native_error:<코드>`.
  로그인·업데이트가 필요하면 플러그인이 사용자가 누른 구매에서만 ONE store 화면을 연다. 배경 조회는 저장된 로그인(silent sign-in)만 시도한다. 게임은 실패 안내 후 재시도를 받는다.
- App은 `GameConfig.store() == "onestore"`일 때 이 어댑터를 고른다. 이 값은 export preset의 custom feature `onestore`로 정해진다.

## 빌드

1. Godot에서 **Project → Install Android Build Template**을 실행한다.
2. JDK 17 이상과 Android SDK Platform 36을 준비한다.
3. AAR를 만든다. 스크립트는 Maven Central에서 SDK 세 개(`sdk-iap`, `sdk-auth`, `sdk-base`)를 받고 SHA-256을 확인한다.

```bash
ANDROID_JAR="$ANDROID_HOME/platforms/android-36/android.jar" \
GODOT_AAR="android/build/libs/release/godot-lib.template_release.aar" \
native/android/onestore_iap/build.sh
```

출력 `addons/android_services/onestore/bin/GodotOneStoreIap.aar`는 Git에서 제외된다. 기기 검증 후 커밋 여부를 결정하고 해시를 [DEPENDENCIES.md](DEPENDENCIES.md)에 기록한다.
`GODOT_AAR` 경로는 설치한 build template에 맞춰 바꾼다. AAR에는 플러그인 클래스만 들어가고 SDK는 Gradle export가 Maven Central에서 해결한다.

## 설정

ONE store 개발자 센터에서 앱과 인앱 상품을 등록하고, 라이선스 공개 키를 복사한다. Git 제외 `config/android.local.cfg`에 넣는다.

```ini
[billing]
android_mode="native"
; 검증을 수행할 로컬 빌드에서만 연다. true 자체는 검증 증거가 아니다.
android_native_verified=true
onestore_product_ids={"REMOVE_ADS": "개발자 센터의 상품 ID"}
onestore_public_key="개발자 센터의 라이선스 공개 키"
```

`Android ONE store` preset으로 export한다. exporter는 다음을 오류로 알린다: Google Billing과 동시 선택, AAR 없음, custom feature `onestore` 없음, Gradle 꺼짐.

```bash
godot --headless --path . --export-debug 'Android ONE store' build/android/onestore-debug.apk
adb install -r build/android/onestore-debug.apk
```

## 기기 검증 항목

ONE store 앱이 설치된 기기와 개발자 센터의 테스트 계정(sandbox)을 사용한다.

- [ ] 첫 실행 sync와 `query_products()` 가격 표시
- [ ] 로그인 안 된 상태 구매 → 로그인 화면 → `store_login_required` → 재시도 성공
- [ ] 비소모성·소모성 구매, `transaction_received` → `finish_purchase()` → `purchase_completed`
- [ ] 앱 종료 중 결제 완료 후 재실행 시 재수신, 중복 지급 없음
- [ ] 취소, 네트워크 끊김, 구독 구매·복원
- [ ] ONE store 앱 업데이트 필요 상태(`store_update_required`)

검증 결과는 기기·OS·ONE store 앱 버전과 함께 [VALIDATION.md](template/VALIDATION.md)(템플릿) 또는 게임 문서에 기록한다.

## 라이선스

ONE store SDK는 오픈소스가 아니며 [ONE store SDK 이용약관](https://m.onestore.co.kr/common/license/ONESTORE_SDK_TERMS.html)을 따른다.
플러그인 소스(`native/android/onestore_iap/`)는 이 템플릿의 일부다. 샘플 저장소 [ONE-store/onestore_iap_release](https://github.com/ONE-store/onestore_iap_release)는 Apache-2.0이며 코드를 복사하지 않고 API 사용법만 참고했다.
