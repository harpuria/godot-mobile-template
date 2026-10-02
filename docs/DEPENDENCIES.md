# Dependency 조사 및 Compatibility BOM

조사일: **2026-09-16**. 기준 엔진: **Godot 4.7.2**, Template: **0.1.0**.
게임 서비스의 후속 확인일은 **2026-10-01**이며 아래 설치·기기 검증 기록을 따른다.

공식 Godot 아카이브에서 4.7.2 stable의 공개일 **2026-08-18**을 확인했다. 엔진 버전은 변경하지 않는다. [공식 다운로드](https://godotengine.org/download/archive/4.7.2-stable/), [릴리스 설명](https://godotengine.org/article/maintenance-release-godot-4-7-2/)

## 상태의 의미

- **Locked**: 이 템플릿이 지정한 정확한 버전.
- **Upstream supported**: 제작자의 지원 범위 또는 릴리스 테스트 주장. 이 프로젝트의 기기 검증과 다르다.
- **Unverified**: 해당 기능 또는 플랫폼을 이 프로젝트와 Godot 4.7.2 조합으로 검증하지 않았다. 부분적인 AAR 로딩 검증은 계정 기능의 검증을 대신하지 않는다.
- **Experimental**: 제작자가 API 불안정 또는 개발 중이라고 명시했다.
- **Unknown**: 공개 자료로 정확한 값이나 상태를 확정하지 못했다.

## 채택 BOM — Mobile Template BOM v0.2.0

| Category | Name | Version | Platform | Godot Compatibility | Status |
| --- | --- | --- | --- | --- | --- |
| Engine | Godot Engine | 4.7.2 | Android / iOS / Desktop | 기준 버전 | Locked |
| Language | GDScript | Godot 4.7.2 내장 | All | 엔진에 포함 | Locked |
| Services | 저장/설정/오디오/씬/Mock 서비스, 게임 서비스 Service/Adapter | Template 0.2.0 | All | 실행 검증 결과는 README 참고; native 미검증 | In-repo |
| Native plugin | Godot Play Game Services | v3.4.0 | Android | 4.7.2 Debug/Release export·기기 로딩 통과; 계정 기능 미검증 | Installed, export opt-in |
| External native SDK | Google Play Games Services v2 | 21.0.0 | Android | 위 플러그인과 Gradle 의존성 해결 확인 | Installed, export opt-in |
| Serialization | Gson | 2.11.0 | Android | 위 플러그인의 고정 의존성 | Installed, export opt-in |
| iOS native plugins | 없음 | N/A | iOS | GameCenter 바이너리 통합 보류 | Not installed |

기본 Android preset은 SDK를 포함하지 않는다. Play Games SDK는 별도 Gradle export에서 명시적으로 선택한다. 광고·결제 실기기 검증 조합이라고 표현하지 않는다. Godot는 [MIT 라이선스](https://godotengine.org/license/)이며 엔진 배포물의 제3자 고지 역시 보존한다. 설치는 4.7.2 Standard 편집기 및 정확히 일치하는 4.7.2 export templates를 사용한다. [엔진 소스](https://github.com/godotengine/godot)

## 다음 Native BOM 후보 — 아직 설치하지 않음

| 후보 | 확인한 최신 정식 release | 플랫폼 | 유지보수 근거 | Godot 4.7.2 판정 | 결정 |
| --- | --- | --- | --- | --- | --- |
| GodotGooglePlayBilling | 3.3.0 | Android | 2026-07-27 release | Upstream 4.2+ / 프로젝트 Unverified | Android 결제 우선 후보 |
| Poing Studios Godot AdMob Plugin | 5.1.0 | Android / iOS | 2026-09-13 release | Upstream 4.7.2 테스트 명시 / 프로젝트 Unverified | 광고 우선 검토 후보 |
| godot-sdk-integrations Godot Admob | 7.0 | Android / iOS | 2026-05-27 release | Upstream 4.7 / 정확한 patch Unverified | 대안, 동시 설치 금지 |
| Godot StoreKit 2 | 0.2 | iOS | release 존재, API 개발 중 | Experimental / 4.7.2 Unverified | 보류 |
| Godot iOS Plugins InAppStore | 3.5-stable release 확인 | iOS | 확인한 정식 바이너리는 Godot 3.5용 | 4.7.2용 바이너리 Unverified | 구형 release 설치 금지 |
| Godot In-app Review Plugin | 5.3 | Android / iOS | 2026-05-25 release | Upstream 4.7 / 정확한 patch Unverified | optional 보류 |

표의 버전은 설치된 dependency가 아니다. 최신 여부는 아래 링크를 조사한 날짜 기준이며 nightly/prerelease를 선택하지 않았다.

### Android Billing: GodotGooglePlayBilling 3.3.0

- Source: [관리 저장소](https://github.com/godot-sdk-integrations/godot-google-play-billing), [정식 releases](https://github.com/godot-sdk-integrations/godot-google-play-billing/releases). 기존 Godot 프로젝트 플러그인의 `godot-sdk-integrations` 관리 저장소를 우선 조사했다.
- License: [MIT, 3.3.0 태그](https://github.com/godot-sdk-integrations/godot-google-play-billing/blob/3.3.0/LICENSE).
- Native: **Google Play Billing Library 9.1.0**, `billing-ktx:9.1.0`. 태그의 빌드 파일은 Godot library **4.5.1.stable**, compileSdk **36**, minSdk **23**, Java **17**을 지정한다. [태그 build.gradle.kts](https://github.com/godot-sdk-integrations/godot-google-play-billing/blob/3.3.0/godot-google-play-billing/build.gradle.kts)
- 설치 계획: 3.3.0 release ZIP을 `addons/GodotGooglePlayBilling/`로 복사하고 Plugins 활성화, Android Gradle build 활성화. [제작자 설치 안내](https://github.com/godot-sdk-integrations/godot-google-play-billing)
- 선정 이유: Android billing 전용 인터페이스와 현재 native library 업데이트가 확인된다. 4.2+ 지원 설명은 있으나 4.7.2 실기기 결제 검증 자료로 간주하지 않는다.
- 제약/TODO: Gradle 의존성 해결과 중복 Godot library 여부, 상품 조회, pending, acknowledge/consume, 취소, 재시작 후 복구, 구독 offer, 중복 거래 방지를 sandbox에서 확인한다. Google SDK 배포 약관은 MIT 플러그인 라이선스와 별개로 확인한다.
- 마지막 문서 확인: **2026-09-16**. 실제 통합: **Unverified**.

### 광고 우선 후보: Poing Studios Godot AdMob Plugin 5.1.0

- Source: [제작자 저장소 및 MIT 표시](https://github.com/poingstudios/godot-admob-plugin), [5.1.0 release](https://github.com/poingstudios/godot-admob-plugin/releases/tag/v5.1.0).
- 유지보수: release에서 R8, export, iOS callback crash 관련 수정이 확인된다. release는 Godot **4.7.2까지 테스트**했다고 명시하고 Android 4.7.2 template asset을 제공한다. 이를 프로젝트 검증과 구분한다.
- Native release 표기: Android Google Mobile Ads **Next-Gen 1.4.0**, iOS Google Mobile Ads **13.9.0**. 기존 Android `play-services-ads`의 24.x 버전과 혼동하지 않는다.
- 중요한 불일치: 5.1.0 release는 compileSdk **35**, 최소 iOS **15.0**을 설명하지만 `/5.0/` 문서는 compileSdk **36**, 최소 iOS **14.0**, Android SDK **1.2.1**, iOS SDK **13.6.0**, iOS UMP **3.1.0**을 표시한다. 따라서 `/5.0/` 값을 5.1.0 BOM에 그대로 전사하지 않는다. **5.1.0 UMP 정확한 버전은 Unknown**. [문서](https://poingstudios.github.io/godot-admob-plugin/5.0/)
- 설치 계획: 정확한 5.1.0 ZIP을 프로젝트에 추출하고 플러그인을 활성화한다. 자동 native 다운로드가 있으므로 먼저 태그 manifest와 다운로드 URL/version 고정을 감사한다. Android build template/Gradle과 iOS export 설정을 검증한다.
- 선정 이유: 양 플랫폼 지원 및 정확한 Godot patch에 대한 upstream 자료가 가장 직접적이다.
- 보류 이유/TODO: tagged native manifest/라이선스/해시를 확인하고 충돌하는 문서 요건을 해소한 다음 최소 양 플랫폼 export 및 테스트 광고를 검증해야 한다. 이 scaffold에는 아직 설치하지 않는다.
- 마지막 문서 확인: **2026-09-16**. 프로젝트 호환성: **Unverified**.

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

- Privacy는 별도 네이티브 dependency를 설치하지 않는다. 광고 후보의 UMP/ATT 내장을 재사용할 계획이다. Mock consent를 실제 이용자 동의나 법적 준수의 증거로 사용하지 않는다. [Admob 내장 기능](https://github.com/godot-sdk-integrations/godot-admob)
- Analytics는 특정 사업자가 필요하지 않아 자체 Mock만 사용한다. Firebase 및 관련 native SDK는 **미도입, 버전 N/A**.
- Review 후보는 [Godot In-app Review Plugin](https://github.com/godot-mobile-plugins/godot-inapp-review), [v5.3 release](https://github.com/godot-mobile-plugins/godot-inapp-review/releases), License **MIT**. Godot 4.7 테스트 및 양 플랫폼 지원을 명시한다. Android native Google Play Review library의 정확한 버전은 **Unknown**, iOS는 시스템 review API이며 독립 SDK 패키지 버전 N/A.
- 설치 계획: 5.3 플랫폼 archive를 추출하고 플러그인 활성화, Android Gradle 및 iOS export plugin 활성화. 실제 리뷰 창은 스토어 정책/할당량에 따라 나타나지 않을 수 있다. 호출 완료를 사용자의 리뷰 작성 완료로 해석하지 않는다.
- optional 모듈이므로 현재 Mock/interface 유지. 마지막 확인 **2026-09-16**, 4.7.2 프로젝트 호환성 **Unverified**.

## 게임 서비스 후보 — 2026-10-01

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
