## 결과 화면. 방금 점수와 최고 점수를 보여 주고 재도전 또는 타이틀로 보낸다.
extends Control

const Session := preload("res://examples/game_skeleton/game_session.gd")

func _ready() -> void:
	var safe := SafeArea.new()
	safe.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(safe)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 32)
	safe.add_child(box)
	var lines := [tr("SCORE") % Session.last_score, tr("BEST_SCORE") % Session.best_score()]
	if Session.last_was_best:
		lines.push_front(tr("NEW_BEST"))
	for line in lines:
		var label := Label.new()
		label.text = line
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 40)
		box.add_child(label)
	box.add_child(_button("RETRY", retry))
	box.add_child(_button("QUIT_TO_TITLE", to_title))
	App.back_requested.connect(to_title)

## 새 라운드를 시작한다.
func retry() -> void:
	SceneManager.change_scene(Session.scene("play.tscn"))

## 타이틀로 돌아간다. Android back도 같은 동작이다.
func to_title() -> void:
	SceneManager.change_scene(Session.scene("title.tscn"))

func _button(text_key: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = tr(text_key)
	button.custom_minimum_size.y = 96
	button.pressed.connect(action)
	return button
