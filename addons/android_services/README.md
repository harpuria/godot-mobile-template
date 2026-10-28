# Android 결제·광고 배포물

정확한 공식 release에서 아래 AAR만 복사했다. App 소유 어댑터가 native singleton을 직접 사용한다.
export 연결은 이 템플릿의 `plugin.gd`가 맡으며 SDK 포함 옵션은 기본 false다.

| 기능 | 버전 / 원본 | 라이선스 | Maven 의존성 |
| --- | --- | --- | --- |
| Google Play Billing | [3.3.0](https://github.com/godot-sdk-integrations/godot-google-play-billing/releases/tag/3.3.0)의 Debug/Release AAR | `billing/LICENSE` (MIT) | `com.android.billingclient:billing-ktx:9.1.0` |
| Poing AdMob | [5.1.0](https://github.com/poingstudios/godot-admob-plugin/releases/tag/v5.1.0)의 `android-template-v4.7.2.zip`, ads/core Debug/Release AAR | `admob/LICENSE` (MIT) | `ads-mobile-sdk:1.4.0`, `constraintlayout:2.2.0`; Google UMP `4.0.0`이 전이 의존성으로 해결됨 |

출처 archive와 각 AAR의 SHA-256은 [manifest.json](manifest.json)에 기록했다.
새 AAR 여섯 개의 `classes.jar`에는 `org/godotengine/godot/` 엔진 클래스가 없다.
실행 엔진은 고정된 Godot 4.7.2 export template이다.

설정·서비스 API는 [ANDROID_SERVICES.md](../../docs/ANDROID_SERVICES.md),
라이선스와 호환성 범위는 [DEPENDENCIES.md](../../docs/DEPENDENCIES.md),
실제 export·기기 결과는 [VALIDATION.md](../../docs/template/VALIDATION.md)를 따른다.
