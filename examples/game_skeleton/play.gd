## 플레이 화면. 규칙 진행, 일시정지, Android back, 앱 백그라운드 전환을 처리한다.
extends Control

const Session := preload("res://examples/game_skeleton/game_session.gd")
const GameRules := preload("res://examples/game_skeleton/game_rules.gd")

var rules := GameRules.new()
var paused := false
var finished := false
var score_label := Label.new()
var time_label := Label.new()
var hud := VBoxContainer.new()
var pause_menu := VBoxContainer.new()

func _ready() -> void:
	var safe := SafeArea.new()
	safe.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(safe)
	var box := hud
	box.add_theme_constant_override("separation", 24)
	safe.add_child(box)
	var pause_button := _button("PAUSE", toggle_pause)
	pause_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	box.add_child(pause_button)
	for label in [time_label, score_label]:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 48)
		box.add_child(label)
	var tap_button := _button("TAP", tap)
	tap_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(tap_button)
	pause_menu.alignment = BoxContainer.ALIGNMENT_CENTER
	pause_menu.add_theme_constant_override("separation", 24)
	pause_menu.add_child(_button("RESUME", toggle_pause))
	pause_menu.add_child(_button("QUIT_TO_TITLE", quit_to_title))
	pause_menu.visible = false
	safe.add_child(pause_menu)
	App.paused.connect(_on_app_paused)
	App.back_requested.connect(toggle_pause)
	_refresh()

func _process(delta: float) -> void:
	if paused or finished:
		return
	rules.tick(delta)
	_refresh()
	if rules.is_over():
		finish()

## 탭 입력을 규칙에 전달한다. 일시정지 중에는 무시한다.
func tap() -> void:
	if paused or finished:
		return
	if rules.tap():
		# 효과음은 여기서 AudioManager.play_sfx(stream)으로 재생한다.
		_refresh()

## 일시정지 메뉴를 열거나 닫는다. SceneTree.paused는 쓰지 않아 장면 전환이 막히지 않는다.
func toggle_pause() -> void:
	set_paused(not paused)

## 일시정지 상태를 지정한다. 라운드가 끝난 뒤에는 바뀌지 않는다.
func set_paused(value: bool) -> void:
	if finished:
		return
	paused = value
	pause_menu.visible = value
	hud.visible = not value

## 라운드를 끝내고 결과를 저장한 뒤 결과 화면으로 이동한다.
func finish() -> void:
	if finished:
		return
	finished = true
	var error := Session.finish_round(rules.score)
	if error != OK:
		push_warning("Round result not saved: %s" % error_string(error))
	MobilePlatform.vibrate(60)
	SceneManager.change_scene(Session.scene("result.tscn"), false)

## 진행 중인 라운드를 버리고 타이틀로 돌아간다.
func quit_to_title() -> void:
	finished = true
	SceneManager.change_scene(Session.scene("title.tscn"))

## 앱이 백그라운드로 가면 돌아왔을 때 일시정지 메뉴가 보이게 한다.
func _on_app_paused() -> void:
	set_paused(true)

func _refresh() -> void:
	time_label.text = tr("TIME_LEFT") % ceili(rules.time_left)
	score_label.text = tr("SCORE") % rules.score

func _button(text_key: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text_key
	button.custom_minimum_size = Vector2(160, 96)
	button.pressed.connect(action)
	return button
