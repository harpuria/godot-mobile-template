## 장면 전환 완료와 돌아가기 동작을 확인하는 두 번째 검증 화면이다.
extends Control

func _ready() -> void:
	var safe := SafeArea.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(safe)
	var button := Button.new()
	button.text = "Transition complete — Back to Demo"
	button.pressed.connect(_back)
	safe.add_child(button)
	App.back_requested.connect(_back)

func _back() -> void:
	SceneManager.change_scene("res://scenes/main.tscn")
