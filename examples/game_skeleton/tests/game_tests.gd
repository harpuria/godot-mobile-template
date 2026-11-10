## 게임 전용 headless 검사 실행기. 규칙, 저장, 번역, 장면 흐름을 실제 SceneTree에서 확인한다.
## 실행: godot --headless --path . --scene res://examples/game_skeleton/tests/game_tests.tscn
extends Node

const Session := preload("res://examples/game_skeleton/game_session.gd")
const GameRules := preload("res://examples/game_skeleton/game_rules.gd")
const Bootstrap := preload("res://scenes/bootstrap.gd")

var checks := 0
var failures := 0

func _ready() -> void:
	# 장면이 바뀌어도 실행기가 남도록 root로 옮긴다.
	get_parent().remove_child.call_deferred(self)
	get_tree().root.add_child.call_deferred(self)
	_run.call_deferred()

## 조건 하나를 기록한다. 실패는 `FAIL:`로 출력한다.
func check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("PASS: " + message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func _run() -> void:
	# 실제 사용자 저장을 건드리지 않도록 임시 경로를 쓴다.
	var dir := OS.get_environment("TMPDIR")
	if dir.is_empty() or not dir.is_absolute_path():
		dir = OS.get_user_data_dir()
	dir = dir.path_join("game-tests-%s" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(dir)
	SaveManager.storage_path = dir.path_join("save.json")
	Settings.storage_path = dir.path_join("settings.cfg")
	# bootstrap과 같은 순서: 게임 hook → App.initialize().
	check(Bootstrap.run_init_script(Session.scene("game_init.gd")) == OK, "Game init hook runs")
	App.initialize()
	check(App.ready_for_game and not SaveManager.write_blocked, "App initialized with a writable save")
	_check_rules()
	_check_progress()
	_check_translations()
	await _check_flow()
	for file in ["save.json", "save.json.bak", "settings.cfg"]:
		DirAccess.remove_absolute(dir.path_join(file))
	DirAccess.remove_absolute(dir)
	print("GAME TESTS: %s checks, %s failures" % [checks, failures])
	get_tree().quit(1 if failures > 0 else 0)

func _check_rules() -> void:
	var rules := GameRules.new()
	check(rules.tap() and rules.score == 1, "Tap scores during the round")
	rules.tick(GameRules.ROUND_SECONDS - 0.5)
	check(not rules.is_over(), "Round continues before the time limit")
	rules.tick(1.0)
	check(rules.is_over() and rules.time_left == 0.0, "Round ends at the time limit")
	check(not rules.tap() and rules.score == 1, "Tap ignored after the round")

func _check_progress() -> void:
	check(Session.best_score() == 0 and Session.rounds_played() == 0, "Fresh save has no progress")
	check(Session.finish_round(7) == OK and Session.last_was_best, "First result saved as best")
	check(Session.finish_round(3) == OK and not Session.last_was_best and Session.best_score() == 7, "Lower score keeps the best")
	SaveManager.data.clear()
	check(SaveManager.load_slot() == OK and Session.best_score() == 7 and Session.rounds_played() == 2, "Progress survives reload")

func _check_translations() -> void:
	var previous := TranslationServer.get_locale()
	TranslationServer.set_locale("ko")
	check(tr("START") == "시작", "Korean translation loaded")
	TranslationServer.set_locale("fr")
	check(tr("START") == "Start", "Unsupported locale falls back to English")
	TranslationServer.set_locale(previous)

func _check_flow() -> void:
	await _goto("title.tscn")
	var title := get_tree().current_scene
	check(title.start_button.text == tr("START") and tr("START") != "START", "Title scene shows translated text")
	title.start()
	await SceneManager.transition_completed
	var play := get_tree().current_scene
	play.tap()
	check(play.rules.score == 1, "Play scene accepts taps")
	App.back_requested.emit()
	check(play.paused and play.pause_menu.visible, "Android back opens the pause menu")
	play.tap()
	check(play.rules.score == 1, "Taps ignored while paused")
	App.back_requested.emit()
	App.paused.emit()
	check(play.paused, "App background pauses the round")
	play.set_paused(false)
	play.rules.time_left = 0.01
	await SceneManager.transition_completed
	check(get_tree().current_scene.name == "Result" and Session.last_score == 1, "Round end opens the result scene")
	check(Session.rounds_played() == 3, "Round result saved")
	get_tree().current_scene.to_title()
	await SceneManager.transition_completed
	check(get_tree().current_scene.name == "Title", "Result returns to title")

func _goto(file: String) -> void:
	SceneManager.change_scene(Session.scene(file), false)
	await SceneManager.transition_completed
