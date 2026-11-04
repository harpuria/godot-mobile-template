# Game Layer

게임별 scene/script/resource 및 저장 데이터 정의를 이 디렉터리에 둡니다.
`config/game.cfg`의 `app/main_scene`을 게임의 첫 scene 경로로 변경합니다.

- 광고: `App.ads.show_rewarded("revive")`, 보상은 `rewarded_completed`에서 지급.
- 구매: `App.billing.purchase("REMOVE_ADS")`, 성공/취소/실패 신호 처리.
- 저장: `SaveManager.set_value("progress", {...})`, `flush()`.
- 설정: `Settings.set_setting("my_option", value)`.
- 사운드: `AudioManager.play_sfx(stream)`.
- 장면: `SceneManager.change_scene("res://game/main.tscn")`.

> Game code must never directly depend on a mobile platform plugin.

게임별 schema_version과 migration은 이 디렉터리의 초기화 script에서 등록합니다.
`config/game.cfg`의 `app/init_script`에 경로를 지정하면 bootstrap이 `App.initialize()` 전에 호출합니다.

```gdscript
# game/game_init.gd — init_script="res://game/game_init.gd"
extends RefCounted

func before_app_initialize() -> void:
	SaveManager.schema_version = 2
	SaveManager.register_migration(1, func(old: Dictionary) -> Dictionary:
		old["new_field"] = 0
		return old)
```

게임은 purchase_token(native)·transaction_id(Mock) 기준 중복 지급 방지와 영구 entitlement 정책을 정의해야 합니다.
시작점: `examples/purchase_ledger/purchase_ledger.gd`를 이 디렉터리로 복사해 지급 규칙을 고칩니다. ([예제 안내](../examples/purchase_ledger/README.md))
Mock transaction은 실제 결제 증거가 아닙니다. 데모 자료는 scenes/와 assets/demo/에 있습니다.
