## 타이틀 화면. 최고 점수를 보여 주고 플레이를 시작한다.
extends Control

const Session := preload("res://examples/game_skeleton/game_session.gd")
var start_button := Button.new()

func _ready() -> void:
	var safe := SafeArea.new()
	safe.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(safe)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 32)
	safe.add_child(box)
	var title := Label.new()
	title.text = "GAME_TITLE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	box.add_child(title)
	var best := Label.new()
	best.text = tr("BEST_SCORE") % Session.best_score()
	best.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(best)
	start_button.text = "START"
	start_button.custom_minimum_size.y = 96
	start_button.pressed.connect(start)
	box.add_child(start_button)
	App.back_requested.connect(_on_back_requested)

## 플레이 장면으로 이동한다.
func start() -> void:
	SceneManager.change_scene(Session.scene("play.tscn"))

## 타이틀에서 Android back은 저장 후 종료한다.
func _on_back_requested() -> void:
	App.request_quit()
