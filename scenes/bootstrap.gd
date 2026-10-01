## 공통 서비스를 초기화하고 설정에 지정한 첫 장면으로 진입한다.
extends Node

func _ready() -> void:
	if OS.has_feature("pgs_probe"):
		SceneManager.change_scene("res://scenes/android_game_services_probe.tscn", false)
		return
	App.initialize()
	SceneManager.change_scene(str(GameConfig.value("app", "main_scene", "res://scenes/main.tscn")))
