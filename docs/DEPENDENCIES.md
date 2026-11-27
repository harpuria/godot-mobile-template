# Dependency 조사 및 Compatibility BOM

최종 Android 통합 확인일: **2026-10-21**. 최신 버전 재확인일: **2026-11-04**. 기준 엔진: **Godot 4.7.2**, Template: **0.5.0**.
초기 조사는 2026-09-16, GPGS 최초 설치는 2026-10-01이다. 날짜별 실제 검사 결과는 [VALIDATION.md](template/VALIDATION.md)를 따른다.

Godot AI 4.4.2의 원본 commit은 `423954f4314e250fa2602525d461debc91b1a173`, 공식 `godot-ai-v4-plugin.zip`의 SHA-256은 `93b976b68df03352073d36c30b6daa593cdc42322cd10f6dacdec10d049ac9a0`이다. 갱신할 때는 새 태그의 공식 manifest·서명·ZIP을 upstream `script/v4-release verify`로 검증한다. 애드온 전체와 두 클라이언트의 버전·의존성 기준일·Python 범위를 함께 갱신한다. [배포 및 검증 절차](https://github.com/hi-godot/godot-ai/blob/v4.4.2/docs/packaging-distribution.md)

## 상태의 의미

- **Locked**: 정확히 고정한 버전.
- **Installed, export opt-in**: AAR가 설치됐고 별도 Android Gradle preset에서 선택할 때만 포함한다.
- **Upstream supported**: 제작자의 지원 범위이며 이 프로젝트의 기기 검증과 구분한다.
- **Unverified**: 해당 기능을 실제 스토어·계정·기기 조합으로 확인하지 않았다.
- **Experimental / Unknown**: API 개발 중 또는 정확한 조합을 공개 자료로 확인하지 못했다.

## 채택 BOM — Mobile Template BOM v0.5.0

| 구성 | 고정 버전 | 플랫폼 | 상태 / 호환성 근거 |
| --- | --- | --- | --- |
| Godot / GDScript | 4.7.2 | All | Locked; 엔진 버전 유지 |
| [Godot AI](https://github.com/hi-godot/godot-ai/releases/tag/v4.4.2) | 4.4.2 (애드온·Python 서버) | 에디터 전용, 모바일 SDK 없음 | MIT. 서명된 플러그인 ZIP 검증, Godot 4.7.2 Linux 편집기와 MCP stdio 연결 확인 |
| 공통 Service / Mock / Adapter | Template 0.5.0 | All | In-repo |
| Godot Play Game Services | v3.4.0 | Android | MIT, AAR 유지; SDK 갱신 후 JNI·기기 로딩 확인, 계정 기능 미검증 |
| Google Play Games Services v2 | 22.1.0 | Android | Installed, export opt-in |
| Gson | 2.14.0 | Android | Apache-2.0, Java 8+/Android API 21+ |
| GodotGooglePlayBilling | 3.3.0 | Android | MIT, JNI·상품 조회 응답 확인, 실제 스토어 구매 미검증 |
| Google Play Billing (billing-ktx) | 9.1.0 | Android | Installed, export opt-in |
| Poing AdMob ads/core | 5.1.0 | Android | MIT, 고정 Android 4.7.2 archive; 샘플 광고·콜백 기기 확인 |
| Google Mobile Ads Next-Gen | 1.4.0 | Android | 플러그인 공식 조합 유지; Installed, export opt-in |
| Google UMP | 4.0.0 | Android | Ads의 전이 의존성; 갱신 후 광고 자격 확인 |
| AndroidX ConstraintLayout | 2.2.0 | Android | Apache-2.0; Poing Android exporter 고정 의존성 |
| Kotlin runtime (전이 의존성) | 2.2.10 | Android | Billing 9.1.0이 요구; Apache-2.0, export·기기 결과는 VALIDATION 참고 |
| GodotOneStoreIap | Template 0.5.0 소스 | Android (ONE store) | 템플릿 소유 Java 소스, `build.sh`로 로컬 AAR 생성(Git 제외); 컴파일·가짜 SDK 계약만 확인, **Unverified** |
| ONE store IAP SDK (`com.onestorecorp.sdk:sdk-iap`) | 21.04.00 | Android (ONE store) | Maven Central; 전이 의존성 sdk-auth 1.2.2 → sdk-base 1.2.2; [ONE store SDK 약관](https://m.onestore.co.kr/common/license/ONESTORE_SDK_TERMS.html), 오픈소스 아님 |
| iOS native plugins | 없음 | iOS | Game Center / IAP / 광고 바이너리 미설치 |
| GitHub Actions `actions/checkout` | v5.0.1 (`93cb6efe18208431cddfb8368fd83d5badbf9bfd`) | CI | MIT; commit SHA 고정 |

개발용 `Android` preset은 SDK를 포함하지 않는다. `game_services/include_sdk`, `billing/include_sdk`, `billing/onestore_include_sdk`, `ads/include_sdk`는 모두 false다.
스토어 preset(`Android Google Play`, `Android ONE store`)은 configure가 기능 플래그에 맞춰 SDK를 포함한다. ONE store preset은 Google Billing·Play Games를 넣지 않는다.
기능별 native gate도 false다. 설치·빌드·샘플 광고 검증을 실제 스토어 구매/계정 인증 완료로 확대 해석하지 않는다.
운영 ID·서명·비밀은 Git 밖에서 관리한다. [설정과 API 계약](ANDROID_SERVICES.md).

## Android 고정 배포물 — 2026-10-21

### GPGS 의존성 갱신

- [v3.4.0 release](https://github.com/godot-sdk-integrations/godot-play-game-services/releases/tag/v3.4.0)의 기존 Debug/Release AAR와 MIT 고지를 유지한다.
- upstream 태그는 games-v2 21.0.0 / Gson 2.11.0으로 빌드됐지만, 이 프로젝트의 export 의존성은 **22.1.0 / 2.14.0**으로 명시적으로 갱신했다.
- [Google 22.1.0 릴리스](https://developers.google.com/android/guides/releases#september_15_2026), [Gson 2.14.0](https://github.com/google/gson/releases/tag/gson-parent-2.14.0), [Gson 요구사항](https://github.com/google/gson/blob/gson-parent-2.14.0/README.md#requirements).
- Gson은 [Apache-2.0](https://github.com/google/gson/blob/gson-parent-2.14.0/LICENSE)이다. JDK 17 / 최소 Android API 24로 빌드한다.
- 실제 Game ID, OAuth, 계정 로그인·리더보드·업적은 여전히 게임별 설정·검증이 필요하다.

### Android Billing — GodotGooglePlayBilling 3.3.0

- [고정 release](https://github.com/godot-sdk-integrations/godot-google-play-billing/releases/tag/3.3.0), [MIT](https://github.com/godot-sdk-integrations/godot-google-play-billing/blob/3.3.0/LICENSE).
- [태그 빌드 설정](https://github.com/godot-sdk-integrations/godot-google-play-billing/blob/3.3.0/godot-google-play-billing/build.gradle.kts): Billing **9.1.0**, compileSdk 36, minSdk 23, Java 17, Godot library 4.5.1.stable.
- release ZIP의 AAR 두 개와 라이선스만 `addons/android_services/billing/`에 설치했다. 자체 exporter가 Billing SDK만 연결하며 Maven Godot 4.5.1을 의존성으로 추가하지 않는다.
- 실제 [JNI 메서드·신호](https://github.com/godot-sdk-integrations/godot-google-play-billing/blob/3.3.0/godot-google-play-billing/src/main/java/org/godotengine/plugin/googleplaybilling/GodotGooglePlayBilling.kt)에 맞춰 어댑터를 구현했다.
- 상품 조회, offer 선택, pending, 취소, 재연결, restore, acknowledge/consume, 중복·timeout 계약은 가짜 SDK로 검사했다.
- 실제 상품의 구매·pending 전환·취소·소모/복원·구독 갱신은 Play Console 테스트 트랙과 검증 서버가 준비된 게임에서 추가 확인해야 한다.

### Android 광고 — Poing AdMob 5.1.0

- [고정 release](https://github.com/poingstudios/godot-admob-plugin/releases/tag/v5.1.0), MIT 고지는 `addons/android_services/admob/LICENSE`에 보존했다.
- `android-template-v4.7.2.zip`의 ads/core Debug/Release AAR 네 개만 `addons/android_services/admob/`에 설치했다. 자동 다운로드·미디에이션·upstream autoload를 추가하지 않았다.
- archive의 exporter가 **Next-Gen Ads 1.4.0**, **ConstraintLayout 2.2.0**을 지정한다. 실제 Gradle 해결에서 **Google UMP 4.0.0**을 확인했다. [고정 exporter 소스](https://github.com/poingstudios/godot-admob-plugin/tree/v5.1.0/platforms/android).
- AAR metadata는 minCompileSdk 35, Android manifest는 min SDK 24다. 기준 Godot template의 compile/target 36 / min 24와 함께 export한다.
- [ConstraintLayout Maven POM](https://dl.google.com/dl/android/maven2/androidx/constraintlayout/constraintlayout/2.2.0/constraintlayout-2.2.0.pom)의 라이선스는 Apache-2.0이다.
- `/5.0/` 문서의 과거 SDK 값을 현재 BOM으로 전사하지 않는다. iOS Ads 13.9.0과 iOS UMP는 이번에 설치·검증하지 않았다.
- UMP 갱신·광고 자격과 Google 샘플 보상형/전면 광고를 검사한다. 실제 광고 ID의 required 동의 UI·거부·선택 변경·운영 광고·개인정보 선언은 게임별 후속 검증이다.

### 라이선스·무결성·검증 증거

- 새 AAR 여섯 개의 `classes.jar`에는 `org/godotengine/godot/` 엔진 클래스가 없다. 실행 엔진은 4.7.2 export template의 library다.
- 원본 release asset SHA-256과 각 AAR 해시는 [manifest.json](../addons/android_services/manifest.json)에 기록했다. 공식 GitHub asset digest와 일치한다.
- Google Billing, Play Games, Ads, UMP는 각 Google SDK 약관을 따르며 MIT 플러그인 라이선스와 별개다. [Google 약관](https://developers.google.com/terms).
- Kotlin runtime은 Billing SDK에 의해 2.2.10으로 해결됐다. [Kotlin 소스·Apache-2.0](https://github.com/JetBrains/kotlin/tree/v2.2.10). Godot template의 Kotlin Gradle plugin 2.1.21을 업그레이드하지 않았다.
- [실제 Android 의존성 graph](ANDROID_SERVICES_DEPENDENCIES.txt), [검증 결과](template/VALIDATION.md)를 따른다.

## 최신 버전 재확인 — 2026-11-04

업그레이드하지 않고 upstream 최신 상태만 대조했다.

| 구성 | 채택 | 확인한 최신 | 결정 |
| --- | --- | --- | --- |
| Godot | 4.7.2 | 4.7.2 stable(2026-08-18), 4.8 beta 2 | 유지. 4.8 stable과 패치 이후 검증 gate를 거쳐 검토 |
| Godot Play Game Services | v3.4.0 | v3.4.0 (git tag) | 최신 |
| GodotGooglePlayBilling / Billing | 3.3.0 / 9.1.0 | 3.3.0 / 9.1.0 | 최신. Play의 Billing 8.0+ 요건(2026-08-31) 충족 |
| Poing AdMob / Next-Gen Ads | 5.1.0 / 1.4.0 | 5.1.0 stable(5.2.0은 nightly) / 1.4.0 | 최신 stable |
| play-services-games-v2 | 22.1.0 | 22.1.0 | 최신 |
| Gson | 2.14.0 | Maven Central 2.15.0 | 유지. 기기 검증 없이 올리지 않는다 |
| ONE store IAP SDK | 21.04.00 | 21.04.00 (Maven Central, 2026-03-30) | 신규 채택 |
| StoreKit2 / Godot AdMob / In-app Review | 보류 | v0.2 / v7.0 / v5.3 | 아래 후보 기록과 동일 |

### ONE store IAP — 2026-11-04

- 공식 SDK: [ONE-store/onestore_iap_release](https://github.com/ONE-store/onestore_iap_release)(샘플은 Apache-2.0)가 안내하는 `com.onestorecorp.sdk:sdk-iap:21.04.00`. Maven Central에서 해결하므로 별도 저장소를 추가하지 않는다.
- SHA-256: `sdk-iap-21.04.00.aar` `608777efe504c99956f51f7714e528ba35bd8cc41f865681d6da353b48c437ec`,
  `sdk-auth-1.2.2.aar` `410adca2d7f747a6b131e0bc0708c4fc1cb3acefc115f06c716a83246dce11ac`,
  `sdk-base-1.2.2.aar` `3a3684727c6a6a60fe36be5b871df2f5b29dc893d0ea365defd334ba435cd12c`. 각 파일의 SHA-1은 Maven Central `.sha1`과 일치했다.
- SDK manifest: min SDK 16, `ProxyActivity`, IAP API v7. 권한을 추가하지 않는다.
- 공식 Godot 플러그인이 없어 `native/android/onestore_iap/`에 Godot plugin v2 Java 소스를 작성했다. GodotGooglePlayBilling 3.3.0 JNI 계약을 그대로 제공하고, 로그인은 deprecated된 `launchLoginFlowAsync` 대신 sdk-auth의 `GaaSignInClient`를 쓴다.
- 컴파일 검사: JDK 21 `javac --release 17`, Godot `org.godotengine:godot:4.7.2.stable` AAR(SHA-256 `8791eecfe7c96a4de2d188a0bccfe9b83b92589a5a6825847473416a990e8629`)의 classes, SDK 세 개, Android API stub. 경고는 Godot AAR의 Kotlin metadata 누락뿐이다.
- 기기·ONE store sandbox 결제는 하지 않았다. 검증 전에는 AAR를 커밋하지 않고 `android_native_verified`를 운영 빌드에서 열지 않는다. 절차: [ONESTORE.md](ONESTORE.md).

## 다음 Native BOM 후보 — 아직 설치하지 않음

| 후보 | 확인한 release | 플랫폼 | 결정 |
| --- | --- | --- | --- |
| godot-sdk-integrations Godot Admob | 7.0 | Android / iOS | Poing과 동시 설치하지 않음; 대안 보류 |
| Godot StoreKit 2 | 0.2 | iOS | API 개발 중, 바이너리 호환성 미검증 |
| Godot iOS Plugins InAppStore | 3.5-stable | iOS | 공개 바이너리는 Godot 3.5용; 현재 엔진에 설치 금지 |
| Godot In-app Review Plugin | 5.3 | Android / iOS | optional 보류 |

### 광고 대안: godot-sdk-integrations Godot Admob 7.0

- [저장소](https://github.com/godot-sdk-integrations/godot-admob), [releases](https://github.com/godot-sdk-integrations/godot-admob/releases). License **MIT**, Android/iOS 지원. 7.0은 Godot **4.7** 테스트를 설명하지만 4.7.2에 대한 프로젝트 검증은 없다.
- UMP와 iOS ATT 지원이 이미 있으므로 도입 시 PrivacyAdapter가 같은 플러그인의 기능을 이용하고 별도 UMP/ATT SDK를 중복 도입하지 않는다.
- 설치 계획: 정확한 7.0 플랫폼별 release archive를 추출 후 Plugins 활성화. 양 플랫폼 addon interface 버전을 맞춘다.
- Native SDK: 이전 6.0 release의 iOS **12.14.0** 기록은 있지만 **7.0 태그의 Android/iOS/UMP 정확한 버전은 Unknown**. 이전 수치를 승계했다고 추측하지 않는다.
- 마지막 문서 확인: **2026-09-16**. 선택 보류: native BOM 및 4.7.2 실제 검증 필요.

### iOS Billing: StoreKit 2 / InAppStore

- [Godot StoreKit 2 저장소](https://github.com/godot-sdk-integrations/godot-storekit2), [releases](https://github.com/godot-sdk-integrations/godot-storekit2/releases). 확인한 최신 release **v0.2**, License **MIT**. README가 API 불안정을 명시하므로 GitHub의 Latest 표기만으로 stable API라고 판단하지 않는다. 유지보수는 11 commits와 release 존재까지만 확인했으며 최신 commit의 정확한 날짜는 **Unknown**.
- 설치 계획: 엔진에 맞는 바이너리를 `ios/plugins/`로 추출하고 iOS preset의 플러그인을 활성화한다. 이 조사에서는 4.7.2용 바이너리/ABI를 확인하지 못했다.
- Native: Apple **StoreKit 2**, OS SDK framework이므로 plugin과 독립된 배포 패키지 버전은 N/A. 필요한 Xcode/iOS deployment target의 정확한 조합은 **Unknown**이며 도입 전 태그 Xcode 설정을 검사한다. Apple SDK 약관은 플러그인 MIT와 별개다.
- [기존 Godot iOS Plugins releases](https://github.com/godot-sdk-integrations/godot-ios-plugins/releases)의 최신 표시 바이너리는 **3.5-stable**이며 InAppStore가 포함된다. Godot 3.5 바이너리를 4.7.2에 설치하지 않는다. [관리 조직의 MIT/유지보수 정보](https://github.com/orgs/godot-sdk-integrations/repositories)
- 선택: 두 후보 모두 보류. Mock 구매/복원 구조를 유지하며 실제 transaction 검증·finish·restore·구독 갱신은 후속 통합에서 구현한다.
- 마지막 문서 확인: **2026-09-16**. 상태: **Experimental / Unverified**.

### Privacy / Analytics / Review

- Android Privacy는 설치된 Poing AdMob AAR의 UMP API와 Ads가 해결하는 UMP 4.0.0을 재사용한다. iOS ATT는 미설치다. Mock consent를 실제 이용자 동의의 증거로 사용하지 않는다.
- Analytics는 특정 사업자가 필요하지 않아 자체 Mock만 사용한다. Firebase 및 관련 native SDK는 **미도입, 버전 N/A**.
- Review 후보는 [Godot In-app Review Plugin](https://github.com/godot-mobile-plugins/godot-inapp-review), [v5.3 release](https://github.com/godot-mobile-plugins/godot-inapp-review/releases), License **MIT**. Godot 4.7 테스트 및 양 플랫폼 지원을 명시한다. Android native Google Play Review library의 정확한 버전은 **Unknown**, iOS는 시스템 review API이며 독립 SDK 패키지 버전 N/A.
- 설치 계획: 5.3 플랫폼 archive를 추출하고 플러그인 활성화, Android Gradle 및 iOS export plugin 활성화. 실제 리뷰 창은 스토어 정책/할당량에 따라 나타나지 않을 수 있다. 호출 완료를 사용자의 리뷰 작성 완료로 해석하지 않는다.
- optional 모듈이므로 현재 Mock/interface 유지. 마지막 확인 **2026-09-16**, 4.7.2 프로젝트 호환성 **Unverified**.

## 게임 서비스 최초 도입 기록 — 2026-10-01

아래는 최초 API 조사·설치 조합이다. 현재 Android SDK 22.1.0 / Gson 2.14.0은 위 2026-10-21 BOM과 검증 기록을 따른다.

Android v3.4.0 AAR는 설치했고, 기본 preset의 SDK 포함 옵션은 false다.
Android 기기 로딩은 통과했지만 Google 계정 기능과 iOS Game Center는 **Unverified**이며 플랫폼별 native gate 기본값은 false다.

| 후보 | 고정 버전 / 소스 | 라이선스 | Native dependency | Godot 4.7.2 상태 |
| --- | --- | --- | --- | --- |
| Godot Play Game Services | **v3.4.0** | MIT | `play-services-games-v2:21.0.0`, `gson:2.11.0` | README 4.3+; upstream 빌드 4.5.1; 이 프로젝트 4.7.2 기기 로딩 통과, 계정 미검증 |
| Godot iOS Plugins / GameCenter | **caafb2c7fbfb5c72a64f163c76449274fa49abaa** commit | MIT | Apple GameKit OS framework; 독립 패키지 버전 N/A | 고정 소스에 Godot 4.x/4.6+ 분기; 4.7.2용 바이너리/기기 Unverified |

### Android API 조사

- Source: [v3.4.0 release](https://github.com/godot-sdk-integrations/godot-play-game-services/releases/tag/v3.4.0),
  [태그 MIT 라이선스](https://github.com/godot-sdk-integrations/godot-play-game-services/blob/v3.4.0/LICENSE),
  [태그 build.gradle.kts](https://github.com/godot-sdk-integrations/godot-play-game-services/blob/v3.4.0/plugin/build.gradle.kts).
- 빌드 설정: compileSdk **35**, minSdk **21**, Java **17**, Godot library **4.5.1.stable**.
  이 플러그인은 `implementation`으로 Godot library를 선언한다. 4.7.2 Gradle export에서 dependency resolution과
  Godot library 중복/ABI를 확인하기 전에는 호환성이 입증된 것으로 취급하지 않는다.
- 확인한 [메서드](https://github.com/godot-sdk-integrations/godot-play-game-services/blob/v3.4.0/plugin/src/main/java/com/jacobibanez/plugin/android/godotplaygameservices/GodotAndroidPlugin.kt)와
  [신호](https://github.com/godot-sdk-integrations/godot-play-game-services/blob/v3.4.0/plugin/src/main/java/com/jacobibanez/plugin/android/godotplaygameservices/signals/Signals.kt)에 맞춰
  `AndroidGameServicesAdapter`를 작성했다. 계약 검사는 가짜 SDK이며, 후속 AAR 기기 로딩 검사는 별도로 기록했다.
- 후속 설치: 고정 release의 debug/release AAR와 MIT 고지를 `addons/play_game_services/`에 보존했다.
  upstream GDScript autoload는 도입하지 않았고 자체 export plugin이 AAR와 위 두 Maven 의존성만 연결한다.
  두 AAR의 `classes.jar`에 `org/godotengine/` 클래스가 없고 Gradle graph에도 Maven Godot 4.5.1이 없음을 확인했다.
  실행 엔진은 4.7.2 template의 Godot library다. [실제 의존성 graph](PGS_ANDROID_DEPENDENCIES.txt).
- Release archive SHA-256: `3a1af78f5b9cbf13253b6bffb7795f0c1a9e7d1495052cd456bb6cfb1c265edd`.
  Debug AAR: `7e737a981fb6d1141e70af1dac77a8fc39685c7137aa5b2bc3874b3e38f44b31`.
  Release AAR: `e667109b44b0b5e6eb3ef1c7ca3b6c0f10d71fd0d2b3402b72785a4d7b16cbb9`.
- Native SDK source: [Google Maven](https://maven.google.com/), [Play Games 안내](https://developer.android.com/games/pgs/start).
  Google SDK는 [Google APIs 약관](https://developers.google.com/terms)을 따르며 MIT 플러그인과 별개다.
  Gson 2.11.0은 [Apache-2.0](https://github.com/google/gson/blob/gson-parent-2.11.0/LICENSE)이다.
- 실제 Game ID·OAuth package/SHA-1·테스터·업적·리더보드 설정은 사용자가 아직 준비하지 않았다.
  플러그인의 MIT와 Google SDK 약관은 별개다. 기본 Mock APK export 성공은 네이티브 BOM 검증을 대신하지 않는다.

### iOS API 조사

- Source: [고정 GameCenter 소스](https://github.com/godot-sdk-integrations/godot-ios-plugins/tree/caafb2c7fbfb5c72a64f163c76449274fa49abaa/plugins/gamecenter),
  [고정 MIT 라이선스](https://github.com/godot-sdk-integrations/godot-ios-plugins/blob/caafb2c7fbfb5c72a64f163c76449274fa49abaa/LICENCE),
  [플러그인 manifest](https://github.com/godot-sdk-integrations/godot-ios-plugins/blob/caafb2c7fbfb5c72a64f163c76449274fa49abaa/plugins/gamecenter/gamecenter.gdip).
- manifest는 `GameKit.framework`, `gamekit` capability, `gamecenter.xcframework`를 지정한다.
  Apple OS SDK 약관은 MIT와 별개다. 고정 commit은 API 조사 기준이며 정식 바이너리 release를 의미하지 않는다.
- `IOSGameServicesAdapter`는 singleton의 pending event queue 계약을 따른다.
  현재 source는 `post_score`에서 float32를 사용하므로 Adapter가 정확한 정수 범위를 제한한다.
- Godot 4.7.2-stable 헤더로 release/debug 빌드 및 xcframework 제작, 정확한 Xcode/iOS 최소 버전,
  Game Center entitlement/Team ID/signing, 기기 인증·점수·업적 확인이 남아 있다. 도구 조합의 최소 버전은 **Unknown**이다.
- [GodotApplePlugins](https://github.com/migueldeicaza/GodotApplePlugins)는 iOS **17.0+**를 요구하는 별도 MIT 대안이다.
  현재 Adapter와 API가 다르고 정확한 release/native BOM을 이번 변경에서 채택하지 않았으므로 **Deferred**다.

API와 후속 설치 절차는 [GAME_SERVICES.md](GAME_SERVICES.md)를 따른다.

## Export toolchain 참고

Godot 4.7 Android 공식 가이드는 **OpenJDK 17**, Android SDK Platform **35**, Build-Tools **35.0.1**, Platform-Tools **35.0.0 이상**, CMake **3.10.2.4988404**, NDK **r28b (28.1.13356709)**를 안내한다. SDK command-line tools는 공식 문서가 `latest`라고만 지정하므로 이 템플릿에서 정확한 revision은 **Unknown / 미고정**이며 실제 설치 후 기록해야 한다. Native plugin 도입 시 그 플러그인의 더 높은 compileSdk 요구를 별도로 조정한다. [Godot 4.7 Android export](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html)

iOS는 **macOS + Xcode + 엔진과 일치하는 export templates**가 필요하다. 공식 export 페이지는 특정 macOS/Xcode 최소 숫자를 고정하지 않는다. 따라서 이 문서에서 임의의 최소 버전을 만들지 않으며 검증 기기의 정확한 버전을 후속 기록한다. Team ID와 Bundle ID를 설정하고 Xcode에서 signing/provisioning을 완료해야 한다. [Godot 4.7 iOS export](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_ios.html)

## Native 도입 및 upgrade 검증 gate

1. 정확한 release/tag의 라이선스, native manifest, checksum과 엔진 ABI를 확인한다.
2. 개별 Adapter 안에서만 실제 API를 사용하고 feature off/SDK 없음 경로도 검증한다.
3. Android debug/release export, iOS Xcode export/build를 모두 실행한다.
4. 광고 테스트 ID, 스토어 sandbox로 성공/취소/오류/복원/중복 콜백/pause-resume을 검증한다.
5. UMP/ATT 및 privacy declaration의 최종 SDK 구성과 중복 여부를 확인한다.
6. 기기/OS/툴체인/테스트 날짜와 결과를 기록하고 검증한 조합 전체를 README/BOM에 반영한다.
7. Template 버전을 갱신한다. 자동 latest 업데이트와 조용한 엔진 업그레이드는 금지한다.

Android Play Games의 export·기기 로딩 결과는 [VALIDATION.md](template/VALIDATION.md)에 별도로 기록했다.
Google 계정 기능 및 다른 native 후보의 호환성이 검증된 것으로 확대 해석하지 않는다.
