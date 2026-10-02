# Android Play Games 네이티브 연결

2026-10-01: Godot **4.7.2**, Play Games plugin **v3.4.0**, Google SDK **21.0.0**.
SM_F966N / Android 16에서 Debug·Release AAR 로딩을 확인했다. Google 계정 기능은 Console 설정 대기다.
버전·라이선스·체크섬은 [DEPENDENCIES.md](DEPENDENCIES.md), 실제 검사 결과는 [VALIDATION.md](template/VALIDATION.md)를 따른다.

## Gradle export와 진단 앱

1. Godot 4.7.2와 **4.7.2.stable** export templates를 사용한다. Project → Install Android Build Template로 설치한다.
2. Editor Settings → Export → Android에서 **JDK 17**과 Android SDK 경로를 설정한다.
   이번에 실제 사용한 template 요구는 compile/target SDK **36**, Build-Tools **36.1.0**, min SDK **24**다.
   원래 설치된 JDK 25는 변경하지 않고 임시 JDK 17로 검증했다.
3. Android preset을 복제해 이름을 `Android PGS Probe`로 지정한다.
   `gradle_build/use_gradle_build=true`, `game_services/include_sdk=true`, Custom Features=`pgs_probe`로 설정한다.
   Package Unique Name은 `com.example.mobiletemplate.pgsprobe`처럼 기존 앱과 다른 값으로 지정한다.
   이 feature는 게임 대신 진단 장면을 실행하고 다른 서비스를 끈다. 배포 preset에 넣지 않는다.
4. Debug export 후 USB 디버깅을 허용한 기기에 설치한다. 아래 `godot`, `adb`는 실제 설치 경로로 대체한다.

```bash
rtk proxy godot --headless --path . --export-debug 'Android PGS Probe' build/android/pgs-probe-debug.apk
rtk proxy adb install -r build/android/pgs-probe-debug.apk
rtk proxy adb shell am start -W -n com.example.mobiletemplate.pgsprobe/com.godot.game.GodotAppLauncher
rtk proxy adb shell pidof com.example.mobiletemplate.pgsprobe
```

확인한 PID만 사용해 `rtk proxy adb logcat -d --pid=<PID>`를 읽는다.
Game ID 미설정 상태는 Debug `21 checks, 0 failures`, Release `23 checks, 0 failures`가 정상이다.
Release에는 서명 설정이 필요하며 signing material은 Git에 두지 않는다.
이번 release 검사는 테스트용 debug 인증서로 서명한 **release 엔진**이며 스토어 배포 서명 검사가 아니다.

Game ID가 없을 때 확인하는 것은 네이티브 singleton·7개 Java 메서드·3개 신호 등록,
App의 Android adapter 선택, unavailable 실패, 가짜 인증 방지, disabled Adapter 초기화 생략이다.
실제 SDK 로그인·Google 서버의 점수·업적 저장은 이 검사로 확인되지 않는다.

## Play Console에서 준비할 것

[Google 공식 설정 안내](https://developer.android.com/games/pgs/console/setup),
[테스터 안내](https://developer.android.com/games/pgs/console/publish)를 따른다.

1. [Play Console](https://play.google.com/console/)에서 게임의 Play Games Services를 만들고 숫자 **Game ID**를 복사한다.
2. Android credential을 만들고 설치할 APK의 **패키지명과 서명 SHA-1**을 정확히 연결한다.
   테스트 debug 인증서, upload 인증서, Play App Signing 인증서는 서로 다를 수 있다.
   현재 진단 패키지는 `com.example.mobiletemplate.pgsprobe`, 별도 release 진단 패키지는 `com.example.mobiletemplate.pgsprobe.release`다.
   두 APK의 실제 인증서 SHA-1은 [검증 기록](template/VALIDATION.md)에 각각 기록했다.
3. 일반 업적 하나와 리더보드 하나를 만들고 각 ID를 복사한다. 증분 업적은 현재 API 범위 밖이다.
4. Testers에 휴대폰의 Google 계정을 등록한다. 게임을 만든 계정도 테스터 등록이 필요하다.

설정은 Git에서 제외된 `config/game_services.local.cfg`에 넣는다. ConfigFile 주석은 `;`로 쓴다.

```ini
[game_services]
android_game_id="콘솔의 숫자 Game ID"
android_mode="native"
; 개발용 초기화 gate다. true 자체는 기기/계정 검증 증거가 아니다.
android_native_verified=true
leaderboard_ids={"DEMO_SCORE": {"android": "콘솔의 리더보드 ID", "ios": ""}}
achievement_ids={"DEMO_FIRST_WIN": {"android": "콘솔의 일반 업적 ID", "ios": ""}}
```

Exporter는 이 설정의 허용된 다섯 키만 APK의 `config/game_services.build.cfg`에 주입하고
`android/build/res/values/pgs_game_id.xml`과 APP_ID metadata를 생성한다.
local 원본은 export exclude filter `config/*.local.*`로 제외한다. ID는 APK에 공개되며 signing key/비밀번호를 넣지 않는다.
설정을 바꿀 때마다 다시 export·설치한다. SDK 포함 옵션이 false인 빌드는 이 설정을 주입하지 않는다.

## 계정 설정 후 실기기 검증

진단 앱에서 Sign In → Submit Demo Score → Unlock Demo Achievement를 누르고 실제 완료 신호를 확인한다.
Show Leaderboard / Show Achievements로 Google 화면에서 점수와 업적을 확인한다.
Android UI 완료의 `ui_status=requested`는 호출 전달만 뜻한다.
취소·오프라인·앱 재개·인증 상태 변경·재설치·서명이 다른 release도 검증 기록에 남긴다.
게임 앱에 적용할 때는 SDK 포함 옵션과 local 설정을 사용하되 `pgs_probe` feature를 제거한다.
