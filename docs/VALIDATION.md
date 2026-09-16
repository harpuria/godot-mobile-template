# Validation — 2026-09-16

## 환경

- Engine: `4.7.2.stable.official.ed1daf0bf`.
- macOS / Apple M1. 실제 화면 검증: OpenGL API 4.1 Metal 90.5, Compatibility renderer.
- 설치 JDK: Temurin 25.0.3. 권장 JDK17과 다른 값이며 Android 검증 toolchain으로 채택하지 않음.
- Android SDK 및 Godot 4.7.2 export templates: 미설치.
- Xcode: 전체 앱 미설치, `/Library/Developer/CommandLineTools` 선택 상태.
- Git 저장소가 없는 시작 폴더. commit/tag 생성 안 함.

## 완료

- [x] Godot 4.7.2 Editor headless import/open 완료.
- [x] Parser / compile error 없음.
- [x] Bootstrap → Demo 실행.
- [x] Save/Load, migration, 자동 저장 타이머, 파일 손상/미래 schema/쓰기 실패 보호.
- [x] Settings 독립 저장 및 게임 옵션 확장.
- [x] AudioManager BGM/SFX/UI, mute, pause/resume, 정리.
- [x] SceneManager 전환/중복 요청/없는 경로.
- [x] Mock 광고 성공/실패, consent gate.
- [x] Mock 결제 success/cancel/error, 상품 ID 매핑, 복원, 중복 요청 차단.
- [x] Mock privacy/analytics/review.
- [x] 전체 feature off 및 native 미설치 초기화.
- [x] 실제 macOS 렌더러에서 Demo 버튼 실행 및 viewport PNG 확인.
- [x] game/ 외부 plugin 직접 의존 없음 (현재 게임 코드는 없음).
- [x] Android/iOS dependency 조사와 exact version/source/license 문서.
- [x] README/BOM/ARCHITECTURE/AGENTS 및 secret ignore 작성.

최종 headless: **51 + 8 + 8 = 67 검사, 실패 0**.
실제 렌더러 실행은 그 이전 49개 동작 검사 + screenshot 1개 = **50 검사, 실패 0**.
이후 추가된 자동 저장 타이머/분수 schema 2개 검사는 headless에서 확인했다.
실제 화면은 `/tmp/mobile-template-demo.png`로 캡처해 텍스트, 버튼, 스크롤 배치를 확인했다.
사운드 재생기와 버스 상태는 검증했지만 사람의 청취 판정 또는 모바일 스피커 검증은 하지 않았다.
OS touch/back/노치/회전은 실제 모바일 기기에서 추가 확인해야 한다.

## Export 시도 — 완료하지 못함

Android:
```text
--export-debug Android build/android/mobile-template.apk
exit 1
Missing: android_debug.apk / android_release.apk (4.7.2.stable)
Invalid Android SDK path: platform-tools, adb, build-tools, apksigner
```

iOS:
```text
--export-debug iOS build/ios/mobile-template.zip
exit 1
Missing: export_templates/4.7.2.stable/ios.zip
```

- [ ] Android debug/release export 및 기기 실행.
- [ ] iOS Xcode export/build/signing 및 기기 실행.
- [ ] 실제 광고/결제/동의/리뷰 SDK 검증.
- [ ] release binary에서 Mock 금지 동작 검증 (코드 guard와 native mode 경로는 검사함).

SDK/template와 전체 Xcode, signing 및 테스트 기기가 준비되어야 완료할 수 있다.
SDK 없는 기본 서비스 구현을 네이티브 지원 완료로 표현하지 않는다.

## 관찰한 환경 이슈

sandbox 내부에서는 macOS 시스템 CA 읽기와 Editor Settings 저장 권한 오류가 있었다.
허용된 일반 실행으로 재검증하여 해당 오류가 사라짐을 확인했다.
threaded PackedScene 로드 경로에서 종료 RefCounted 경고가 나타났고, 메인 스레드 로드로 단순화한 이후 통합/데모 종료에서 경고가 사라졌다.
모바일 export preset이 있는 Editor에서는 SDK가 설치되기 전까지 build-tools 누락 메시지가 예상된다.

## 재현

```bash
rtk godot --headless --path . --editor --import --quit
rtk godot --headless --path . --scene res://tests/integration.tscn
rtk godot --headless --path . --scene res://tests/integration.tscn -- --disabled
rtk godot --headless --path . --scene res://tests/integration.tscn -- --native
```

필요 시 GUI 렌더링과 `/tmp` 캡처:
```bash
rtk godot --path . --scene res://tests/integration.tscn -- --capture
```

통합 검사는 고유 임시 저장 경로를 사용하고 정상 완료 시 정리한다.
런타임 출력의 완료 요약과 종료 코드, script error 부재를 함께 확인한다.
