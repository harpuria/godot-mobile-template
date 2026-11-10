# Game skeleton 예제

새 게임의 출발점으로 쓰는 최소 구조다. 타이틀 → 플레이 → 결과 흐름, 일시정지, Android back, 저장, 번역, 게임 전용 검사를 포함한다.
`examples/`는 export에서 제외되며 CI가 이 예제의 검사를 실행한다. 게임 코드는 이 폴더를 직접 불러오지 않고 `game/`으로 복사해 쓴다.

| 파일 | 역할 |
| --- | --- |
| `game_init.gd` | `app/init_script` hook. 저장 schema 버전과 번역(`locale/*.po`) 등록 |
| `game_rules.gd` | 장면과 분리한 게임 규칙(10초 탭 점수). 여기부터 게임 규칙으로 교체 |
| `game_session.gd` | 예제 경로(`ROOT`), 장면 사이에 넘기는 결과, `SaveManager` 진행 기록 |
| `title.*`, `play.*`, `result.*` | 화면 세 개. UI는 script에서 만들고 `SceneManager`로 이동 |
| `locale/en.po`, `locale/ko.po` | 번역. 저장 복구 팝업의 `SAVE_RECOVERY_*` 키 포함 |
| `tests/game_tests.*` | 게임 전용 headless 검사 실행기 |

## 쓰는 법

저장소 루트에서 실행한다. 비어 있는 `game/`(README만 있는 상태)을 기준으로 한다.

```bash
cp examples/game_skeleton/*.gd examples/game_skeleton/*.tscn game/
```

```bash
cp -R examples/game_skeleton/locale examples/game_skeleton/tests game/
```

```bash
rm game/tests/*.uid
```

```bash
grep -rl 'res://examples/game_skeleton' game | xargs perl -pi -e 's#res://examples/game_skeleton#res://game#g'
```

`.uid` 파일은 복사하지 않는다. 같은 UID가 두 곳에 있으면 Godot가 충돌을 경고한다. 다음 import 때 새로 만들어진다.

`config/game.cfg`의 `[app]`을 바꾸고 configure를 실행한다.

```ini
main_scene="res://game/title.tscn"
init_script="res://game/game_init.gd"
```

```bash
godot --headless --path . --script res://tools/configure.gd
```

검사는 다음 명령으로 실행한다. 종료 코드 0과 `GAME TESTS: N checks, 0 failures`를 확인한다.

```bash
godot --headless --path . --scene res://game/tests/game_tests.tscn
```

## 따르는 계약

- **초기화:** 검사 실행기도 bootstrap과 같은 순서(게임 hook → `App.initialize()`)로 시작한다. F6으로 장면만 실행하면 hook이 호출되지 않아 번역 키가 그대로 보인다. F5로 실행한다.
- **저장:** `SaveManager.set_value()` 후 `flush()`로 라운드 결과를 즉시 기록한다. 숫자는 `int(...)`로 읽는다.
- **일시정지:** `SceneTree.paused`를 쓰지 않고 장면의 `paused` 값으로 규칙 진행만 멈춘다. `App.paused`(백그라운드)와 `App.back_requested`(Android back)를 구독한다.
- **종료:** 타이틀의 back은 `App.request_quit()`으로 저장 후 종료한다.
- **번역:** 고정 문구는 번역 키를 `text`에 넣고, 숫자가 들어가는 문구는 `tr("KEY") % 값`을 쓴다. 언어를 추가하면 `game_init.gd`의 `LOCALES`와 `SettingsPanel.languages`를 함께 고친다.
- **검사:** `game/tests/`는 모든 export preset에서 제외된다. 규칙을 바꾸면 `game_tests.gd`의 해당 검사를 같이 고친다.

## 포함하지 않는 것

- 광고·결제 연결. API는 [game/README.md](../../game/README.md), 구매 지급은 [purchase_ledger](../purchase_ledger/README.md)를 따른다.
- 실행 중 언어 변경 시 이미 만든 `tr()` 문구의 갱신. 장면을 다시 열면 반영된다.
- 공통 Theme·아트·사운드. 기기 화면 검증(safe area, 회전, 터치)은 Desktop 검사로 대신하지 않는다.
