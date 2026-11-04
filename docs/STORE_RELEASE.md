# 스토어 배포 안내 — Google Play · App Store · ONE store

기준: Godot **4.7.2**, 템플릿 **0.4.0**, 스토어 요건 확인일 **2026-11-04**.
스토어 정책은 자주 바뀐다. 제출 전에 각 스토어 공식 문서를 다시 확인하고, 확인한 날짜와 결과를 게임 문서에 남긴다.
이 문서는 템플릿이 준비한 범위와 게임이 직접 해야 하는 일을 구분한다. 실제 검증 결과는 [검증 기록](template/VALIDATION.md)을 따른다.

## 배포용 export preset

`tools/configure.gd`가 `config/game.cfg` 값으로 아래 preset을 만들고 갱신한다. 이름은 preset 식별자이므로 바꾸지 않는다.

| Preset | 용도 | 형식 | SDK 포함 |
| --- | --- | --- | --- |
| `Android` | 개발 실행(Godot 실행 버튼) | APK, Gradle 끔 | 없음 |
| `iOS` | Xcode 프로젝트·App Store 빌드 | Xcode export | iOS native 미설치 |
| `Android Google Play` | Play Console 업로드 | **AAB**, Gradle | 기능 플래그에 따라 Billing·Ads·Play Games |
| `Android ONE store` | ONE store 업로드 | APK, Gradle, custom feature `onestore` | 기능 플래그에 따라 ONE store IAP·Ads. Google Billing·Play Games 제외 |

- `[app] build_number`가 Android version code와 iOS build number가 된다. 스토어 제출마다 1씩 올리고 configure를 다시 실행한다.
- `main_scene`이 템플릿 데모가 아니면 iOS·스토어 preset에서 데모·진단 장면과 `assets/demo/`를 제외한다. 개발용 `Android` preset은 데모를 유지한다.
- 진단 preset(custom feature에 `probe`가 들어간 preset)은 configure가 건드리지 않는다.
- Gradle preset은 **Project → Install Android Build Template**이 먼저 필요하다. 생성되는 `android/build/`는 Git에서 제외된다.

```bash
godot --headless --path . --script res://tools/configure.gd
godot --headless --path . --export-release 'Android Google Play' build/android/game-google-play.aab
godot --headless --path . --export-release 'Android ONE store' build/android/game-onestore.apk
```

Release export에서 SDK를 포함했는데 native gate가 닫혀 있거나 Google 샘플 광고(`use_test_ads=true`)를 쓰면 exporter가 경고한다.
경고가 있는 산출물은 스토어에 올리지 않는다. 운영 값은 Git 제외 파일 `config/android.local.cfg`, `config/game_services.local.cfg`에 둔다.

## 공통 출시 점검

- [ ] `app/name`, `version`, `build_number`, `android_package`, `ios_bundle`이 게임 값이다. `com.example.*`가 남아 있지 않다.
- [ ] `services/mode="native"`이고 사용할 기능의 `android_mode`·`android_native_verified`를 해당 빌드의 로컬 설정에서 열었다.
- [ ] 게임이 `transaction_received` → 검증·지급 기록 저장 → `finish_purchase()`를 구현했다. 참고: [examples/purchase_ledger](../examples/purchase_ledger/README.md).
- [ ] 게임 시작 시 `App.billing.get_unfinished_transactions()`도 같은 경로로 처리한다(신호 연결 전에 수신된 거래).
- [ ] 광고 실제 ID와 UMP 동의 화면·거부·개인정보 선택 변경을 실기기에서 확인했다.
- [ ] 아이콘·스플래시·스토어 스크린샷이 게임 것으로 바뀌었다(`icon.svg`는 템플릿 아이콘).
- [ ] 한국 출시: 게임물 등급분류(각 스토어의 자체등급분류), 확률형 아이템이 있으면 확률 정보 표시 의무를 확인한다.

## Google Play

템플릿 상태: GPGS·Billing·AdMob·UMP AAR 설치, Debug/Release 기기 로딩과 샘플 광고 확인. 실제 상품 구매·계정 기능은 게임별 검증이다.

| 요건 (2026-11-04 확인) | 템플릿 상태 |
| --- | --- |
| 신규 앱·업데이트 target API **36** 이상 (2025-08-31부터) | 검증한 4.7.2 Gradle template: compile/target 36, min 24 |
| Play Billing Library **8.0.0 이상** (2026-08-31부터) | Billing 9.1.0 |
| AAB 업로드, 64-bit | `Android Google Play` preset: AAB, arm64-v8a |
| 16 KB 메모리 페이지 지원 | 템플릿 AAR에 native `.so` 없음, 엔진은 4.7.2 template. 최종 AAB를 Play Console의 App bundle explorer로 확인 |

게임이 할 일:

- Play App Signing과 upload key를 설정하고, keystore는 Git 밖에서 환경변수로 주입한다([DEVELOPMENT.md](DEVELOPMENT.md#android-setup)).
- Play Games를 쓰면 Play App Signing 인증서 SHA-1로 OAuth credential을 추가한다([ANDROID_PLAY_GAMES.md](ANDROID_PLAY_GAMES.md)).
- Ads SDK가 `AD_ID` 권한을 병합한다. Play Console의 광고 ID 선언, Data safety, 광고 포함 여부, 대상 연령을 작성한다. 아동 대상이면 Families 정책과 `tag_for_under_age_of_consent`를 검토한다.
- 내부 테스트 트랙에 올리고 라이선스 테스터로 구매·취소·복원·구독을 확인한다. 미완료 구매는 3일 안에 acknowledge/consume되지 않으면 자동 환불된다.
- Android 16(target 36)은 edge-to-edge와 predictive back을 기본 적용한다. 노치·제스처 영역(`SafeArea`)과 `App.back_requested` 동작을 실기기에서 확인한다.

## Apple App Store

템플릿 상태: **수익화 게임은 아직 출시할 수 없다.** iOS 결제(StoreKit)·광고(AdMob/UMP/ATT)·Game Center 바이너리가 없어 iOS에서는 결제·광고가 `unavailable`이다.
iOS export·Xcode 빌드·기기 실행도 아직 검증 기록이 없다.

| 요건 (2026-11-04 확인) | 템플릿 상태 |
| --- | --- |
| App Store Connect 업로드는 **Xcode 26 / iOS 26 SDK** 이상 (2026-04-28부터) | 미검증. Godot 4.7.2 export와 Xcode 26 조합을 Mac에서 확인해야 한다 |
| 최소 iOS | preset `min_ios_version="15.0"` |
| Privacy manifest | Godot preset의 privacy 항목으로 생성. 광고 SDK를 추가하면 SDK manifest와 ATT 문구를 다시 확인 |

결제·광고 없는 iOS 게임은 다음을 마치면 제출할 수 있다.

1. Mac에 Xcode 26 이상과 Godot 4.7.2 export templates를 설치한다.
2. iOS preset에 Team ID, signing, provisioning을 로컬에서 설정하고 `build/ios/`로 export한다.
3. Xcode에서 실기기 실행, Archive, App Store Connect 업로드를 확인한다. macOS·Xcode·iOS 버전을 게임 문서에 기록한다.
4. `application/targeted_device_family`가 iPhone+iPad(2)다. iPad를 지원하지 않으면 iPhone(0)으로 바꾸고, 지원하면 iPad 레이아웃·스크린샷을 준비한다.
5. 표준 HTTPS 외 암호화를 쓰지 않으면 `application/additional_plist_content`에 `<key>ITSAppUsesNonExemptEncryption</key><false/>`를 넣어 수출 규정 질문을 생략할 수 있다. 해당 여부는 게임이 판단한다.

결제·광고·Game Center를 쓰려면 iOS native 도입이 먼저 필요하다. 후보와 보류 사유는 [DEPENDENCIES.md](DEPENDENCIES.md#ios-billing-storekit-2--inappstore)를 따른다.
도입 시 비소모성 상품에는 구매 복원 버튼이 필요하고(App Review 3.1.1), 개인 맞춤 광고에는 ATT 동의가 필요하다.

## ONE store

템플릿 상태: ONE store IAP SDK **21.04.00**용 플러그인 **소스**와 어댑터, 가짜 SDK 계약 검사를 포함한다.
AAR은 `native/android/onestore_iap/build.sh`로 로컬에서 만든다. ONE store 실기기 결제는 아직 검증하지 않았다. 절차는 [ONESTORE.md](ONESTORE.md).

- ONE store 배포물에는 Google Play Billing을 넣지 않는다. `Android ONE store` preset은 `billing/include_sdk=false`, `billing/onestore_include_sdk=true`다.
- Play Games는 Google Play 배포용 기능이므로 ONE store preset에서 끈다. 게임은 `App.game_services`가 `unavailable`일 때를 처리한다.
- AdMob은 그대로 쓸 수 있다. 광고 ID·UMP 설정은 Google Play 빌드와 같다.
- 상품 ID는 `products.json`의 `onestore` 키 또는 로컬 `onestore_product_ids`를 쓴다. Google Play ID로 자동 대체하지 않는다.
