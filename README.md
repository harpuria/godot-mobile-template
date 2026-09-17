# godot-mobile-template

Project: godot-mobile-template  
Godot: 4.7.2  
Language: GDScript  
Targets: Android / iOS  
Template Version: 0.1.0

모바일 게임을 만들 때 쓰는 **시작용 프로젝트**다.
저장, 소리, 화면 이동 기능이 들어 있다. `game/` 폴더에 게임을 만들면 된다.

Android 휴대폰에서 실행과 테스트용 광고·결제를 확인했다(사용자 확인). iPhone과 실제 광고·결제 연결은 아직 확인하지 않았다.

## 1. 먼저 실행해 보기

1. [Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/)를 설치한다. **Standard 버전**을 선택한다.
2. 이 프로젝트 폴더를 컴퓨터에 준비한다. ZIP으로 받았다면 압축을 푼다.
3. Godot를 열고 **Import**를 누른 뒤, 폴더 안의 `project.godot`를 선택한다.
4. 프로젝트가 열리면 오른쪽 위 **▶ 실행 버튼** 또는 **F5**를 누른다.

`MOBILE TEMPLATE` 화면이 나오면 성공이다.

## 2. 버튼을 눌러 확인하기

화면 아래쪽 버튼은 스크롤하면 보인다.
**Mock은 실제 광고를 보거나 돈을 내지 않고 연습하는 기능**이다.

| 해 볼 것 | 누를 버튼 | 성공하면 |
| --- | --- | --- |
| 저장하고 읽기 | `Save Test` → `Load Test` | 같은 저장값이 보인다 |
| 소리 듣기 | `Play BGM`, `Play SFX` | 소리가 난다 |
| 광고 연습 | `Grant Mock Consent` → `Show Mock Rewarded Ad` | `rewarded_completed`가 나온다 |
| 구매 연습 | `Mock Purchase Success` | `purchase_completed`가 나온다 |
| 취소·오류 연습 | `Mock Purchase Cancel`, `Mock Purchase Error` | `purchase_cancelled`, `purchase_failed`가 각각 나온다 |
| 구매 복원 연습 | 구매 성공 후 `Restore Mock Purchases` | `1 item(s)`가 나온다 |
| 화면 바꾸기 | `Scene Transition` | 다른 화면으로 이동한다 |

복원 연습은 앱을 끄지 않은 상태에서 진행한다. 실제 구매 내역은 아니다.

## 3. 내 게임 만들기

1. 이 프로젝트 폴더를 복사해 새 게임용으로 사용한다.
2. Godot에서 **Scene → New Scene → 2D Scene**을 선택하고 `game/main.tscn`으로 저장한다.
3. [config/game.cfg](config/game.cfg)를 텍스트 편집기로 연다. 기존 `[app]` 안에서 다음 값만 바꾼다.

```ini
name="내 첫 게임"
main_scene="res://game/main.tscn"
orientation="portrait"
```

`portrait`는 세로, `landscape`는 가로, `sensor`는 휴대폰을 돌리는 방향이다.

4. 이름과 방향을 적용한다. **Mac에서는 프로젝트 폴더에서 터미널을 열고** 아래 명령을 실행한다.

```bash
rtk proxy /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tools/configure.gd
```

명령이 어렵다면 AI에게 **“config/game.cfg의 설정을 프로젝트에 반영해 줘”**라고 요청해도 된다.

5. 프로젝트를 다시 열고 **F5**를 누른다. 이제 `game/main.tscn`이 열린다. 처음에는 빈 화면이 정상이다. 이 장면부터 게임을 만든다.

게임 파일은 `game/`, 게임 설정은 `config/`에 둔다. 공통 기능을 고칠 때는 [코드 안내서](docs/CODEBASE_MAP.md)를 참고한다.

## 4. 휴대폰에서 실행하기

**Android:** [Android 준비 방법](docs/DEVELOPMENT.md#android-setup)을 따라 필요한 도구를 설치한다. 휴대폰에서 **USB 디버깅**을 켜고 컴퓨터에 연결한 뒤, Godot의 Android 실행 버튼을 누른다.

휴대폰에서도 광고·결제를 연습하려면 `config/game.cfg`의 기존 `[services]` 값을 아래처럼 맞추고 **Debug 빌드(개발용 앱)**로 설치한다.

```ini
[services]
mode="mock"
allow_mobile_debug_mocks=true
```

**iPhone:** Mac과 Xcode가 필요하다. [iPhone 준비 방법](docs/DEVELOPMENT.md#ios-setup)을 따라 설정한다.

실제 광고와 결제를 붙이거나 스토어에 올리는 작업은 별도로 필요하다.

## 잘 안 될 때

| 문제 | 먼저 해 볼 것 |
| --- | --- |
| 광고 실패 | `Grant Mock Consent`를 먼저 누른다 |
| 휴대폰에서 `Unavailable` 표시 | 위의 Mock 설정을 확인하고 Debug 빌드로 다시 설치한다 |
| 소리가 나지 않음 | 휴대폰·컴퓨터 음량과 데모 아래쪽 Volume 설정을 확인한다 |
| 새 게임 대신 데모 실행 | `main_scene` 경로와 파일 저장 여부를 확인한다 |
| 앱 내보내기 실패 | [Android](docs/DEVELOPMENT.md#android-setup) 또는 [iPhone](docs/DEVELOPMENT.md#ios-setup) 준비 방법을 확인한다 |

## Dependency BOM

사용 중인 도구의 버전이다. 버전은 자동으로 바꾸지 않는다.

| 구성 | 버전 |
| --- | --- |
| Godot / 내장 GDScript | 4.7.2 |
| 이 템플릿 | 0.1.0 |
| 추가 광고·결제 플러그인 | 설치하지 않음 |

## 더 자세히 보기

- [개발 상세 안내](docs/DEVELOPMENT.md): 설정, 코드 사용 예제, Android·iPhone 빌드 방법
- [도구·라이선스 기록](docs/DEPENDENCIES.md): 정확한 버전과 사용 조건
- [검증 기록](docs/VALIDATION.md): 어디까지 확인했는지
- [AI 작업 규칙](AGENTS.md) · [코드 안내서](docs/CODEBASE_MAP.md) · [설계 설명](docs/ARCHITECTURE.md)
