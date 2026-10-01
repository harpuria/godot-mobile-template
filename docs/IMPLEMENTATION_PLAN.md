# 구현 계획 — Template 0.1.0

기준: Godot 4.7.2 / GDScript / Android, iOS. 특정 게임 구현 제외.

## 구조 결정
- Autoload: GameConfig, Settings, SaveManager, AudioManager, SceneManager, App.
- App이 AdsService/BillingService/Analytics/PrivacyService/ReviewService 노드를 소유한다.
  서비스별 전역 singleton 중복 등록 없이 `App.ads`, `App.billing`로 접근한다.
- Game → Service → Adapter → Plugin. 미검증 native SDK를 기본 배포에 포함하지 않는다. 사용자가 요청한 개발용 연결은 opt-in으로 검증하고 한계를 기록한다.
- JSON 게임 저장은 version envelope + migration callback. Settings는 별도 ConfigFile.
- 앱 pause/quit와 타이머에서 변경된 저장만 기록한다.
- bootstrap → 초기화 → main 검증 장면. SafeArea, loading overlay, settings UI 재사용.
- feature flag가 꺼지거나 native adapter가 없으면 명시적 unavailable 결과.
  Editor/desktop debug에서 Mock을 사용하며 release에서 가짜 구매 성공을 내보내지 않는다.

## 순서 및 완료 기준
1. 공식 release/호환성 조사 → docs/DEPENDENCIES.md 후보 및 BOM.
2. Foundation → bootstrap/config/logging/scene lifecycle 파싱 및 초기화.
3. 공통 기능 → 저장/설정/audio/mobile/safe area 실행.
4. 서비스 → mock ads/billing outcomes, privacy/analytics/review abstraction.
5. Native → 검증 가능한 조합만 채택; 나머지 근거/TODO 명시.
6. Demo + headless integration → 실제 4.7.2에서 저장, 신호, 중복 요청, flag, scene 검사.
7. README/ARCHITECTURE/AGENTS와 export preset 작성, 환경 한계 포함 검증 보고.

## 진행
- 환경 조사 완료: Godot 4.7.2 설치, SDK/export templates/Xcode 미설치.
- dependency 조사 완료: docs/DEPENDENCIES.md. native 없는 BOM 0.1.0 확정.
- Foundation/Common/Service/Mock/Demo/문서 구현 완료.
- Phase 4 native integration은 호환성/SDK manifest/기기 검증이 미완료되어 보류.
- Phase 5 Desktop 검증 완료: 67 checks, 0 failures 및 실제 렌더링 확인.
- Android/iOS export를 실제 시도했으며 SDK/template 부재로 실패. 완료 조건은 docs/VALIDATION.md 참고.
- 다음 필수 작업: JDK17/Android toolchain/4.7.2 templates 및 Xcode 환경 준비 후 양 플랫폼 export와 실기기 검증.

## 게임 서비스 확장 — 2026-10-01

- 목표: `App.game_services`로 Google Play Games / Game Center의 로그인·일반 업적·리더보드 API를 제공한다.
- 완료: 공통 Service/기본 Adapter/Debug Mock, 고정 upstream API 대상 Android/iOS 연결 코드,
  config의 플랫폼 ID 매핑과 feature/native gate, 데모 버튼, 가짜 SDK 계약 검사와 unavailable 검사.
- SDK 미설치 상태이며 각 native gate는 false다. 네이티브 호환성 Verified로 표시하지 않는다.
- Desktop 검사·실제 렌더러 및 기본 export 결과는 `docs/VALIDATION.md`의 2026-10-01 기록이 최신이다.
  9월의 toolchain 부재 기록은 당시 환경을 설명하며 현재 Android export 불가를 의미하지 않는다.
- 남은 순서: `docs/DEPENDENCIES.md` 고정 후보의 빌드/라이선스/ABI → Android Gradle export와 테스트 계정 기기 검사 →
  iOS 4.7.2 xcframework/Xcode/entitlement export와 기기 검사. 각 gate를 검증용 로컬 빌드에서 열고 결과를 기록한다.
- 완료 기준: 각 플랫폼에서 실제 로그인 성공/실패, 점수/업적 조회, UI 요청, 네트워크 실패 및 release Mock 차단까지 확인.
- 클라우드 저장·매치메이킹·서버 인증·Android 증분 업적은 후속 요구 사항이다.

## Android 네이티브 후속 — 2026-10-01

- 고정 v3.4.0 AAR 및 MIT 고지, 자체 export adapter를 추가했다. 기본 SDK 포함 옵션은 false다.
- Godot 4.7.2 / Android 16에서 Debug 21개, Release 23개 native 로딩·미설정·Mock 차단 검사가 통과했다.
- JNI has_java_method 계약 수정과 local config export 주입을 구현했다.
- 실제 Google 계정 기능은 Console Game ID/OAuth/테스터/업적/리더보드 준비 후 검증한다.
- 배포 초기화 gate와 iOS native 상태는 변경하지 않았다. 재현은 docs/ANDROID_PLAY_GAMES.md 참고.
