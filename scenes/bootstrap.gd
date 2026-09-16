## 공통 서비스를 초기화하고 설정에 지정한 첫 장면으로 진입한다.
extends Node

func _ready() -> void:
	App.initialize()
	SceneManager.change_scene(str(GameConfig.value("app", "main_scene", "res://scenes/main.tscn")))
