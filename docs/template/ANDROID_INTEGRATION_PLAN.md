# Android 네이티브 연동 — 2026-10-21

## 범위와 상태

완료. Godot 4.7.2를 유지하고 아래 세 작업을 반영했다. 실제 결과와 남은 게임별 검증은 [VALIDATION.md](VALIDATION.md)를 따른다.
기본 Mock 설정과 미검증 네이티브 gate는 유지한다. 실제 스토어/계정 기능은 콘솔 설정과 기기 검증 결과를 구분해 기록한다.

1. GPGS: 기존 v3.4.0 AAR를 유지하고 games-v2 22.1.0, Gson 2.14.0으로 갱신한다.
2. 결제: GodotGooglePlayBilling 3.3.0 / Billing 9.1.0을 고정하고 기존 BillingService에 Android 어댑터를 연결한다.
3. 광고: Poing AdMob 5.1.0의 Android 배포물과 SDK 조합을 감사·고정하고 광고/UMP 어댑터를 연결한다.

## 구현과 수락 기준

- 플러그인 호출은 어댑터 안에서만 수행하고 App이 인스턴스를 소유한다.
- SDK 포함은 Android Gradle export에서 명시적으로 선택한다. 게임별 로컬 설정은 허용한 키만 빌드에 주입한다.
- 결제는 상품 조회, pending, 구매 취소/실패, acknowledge/consume, 재연결·복원을 다루며 검증되지 않은 거래를 성공으로 만들지 않는다.
- 광고는 동의 확인 후 초기화·로드하고 보상 콜백에서만 성공을 보낸다. 중복 표시·실패·동의 변경을 처리한다.
- 실제 태그 API에 대한 가짜 SDK 계약 검사와 기본/disabled/native 통합 시나리오를 실행한다.
- Android Debug·Release export와 가능한 기기 검사에서 SDK 등록과 실패 경로를 확인한다.
- Play Console 계정/상품 검증 및 실제 테스트 광고 확인은 실제 실행 여부를 기록한다.
- README BOM, DEPENDENCIES, ARCHITECTURE, CODEBASE_MAP, CHANGELOG와 VALIDATION을 갱신한다.

## 현재 확인

- 세 SDK를 포함한 Debug·Release export·기기 실행 성공. Release는 직접 생성한 Mock 구매·복원 차단까지 16 검사, 실패 0.
- Debug에서 UMP 갱신 후 광고 로드, 샘플 전면 광고 종료·보상형 reward 콜백 확인.
- 최종 import와 Desktop 계약 검사는 163 + 13 + 13 검사, 실패 0. Mock guard 변경 후 재검사와 두 APK 해시·설정 필터 검증 완료.
- 최종 Release에서 UMP 갱신 후 샘플 전면 광고 종료·보상형 reward 콜백을 확인했다. APK와 기기 로그는 Git 제외 build/android에 보존했다.
- 실제 스토어 상품·구매·계정 기능과 required UMP 동의 UI는 게임별 후속 검증이다.

- 작업 트리 clean, Godot 4.7.2 실행 확인.
- 기존 GPGS AAR 두 개의 해시는 문서와 일치한다.
- Android SDK와 4.7.2 export templates는 있다. 프로젝트의 Gradle build template은 아직 없다.
- 기본 Java Runtime이 없어 /tmp에 격리된 JDK 17.0.20.1+1을 준비했다.
- iOS 신규 연동은 이번 범위에 포함하지 않는다.
