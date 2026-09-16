# 구현 계획 — Template 0.1.0

기준: Godot 4.7.2 / GDScript / Android, iOS. 특정 게임 구현 제외.

## 구조 결정
- Autoload: GameConfig, Settings, SaveManager, AudioManager, SceneManager, App.
- App이 AdsService/BillingService/Analytics/PrivacyService/ReviewService 노드를 소유한다.
  서비스별 전역 singleton 중복 등록 없이 `App.ads`, `App.billing`로 접근한다.
- Game → Service → Adapter → Plugin. 미검증 native SDK는 설치하지 않는다.
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
