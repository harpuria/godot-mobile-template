## 게임 초기화 hook을 실행하고 공통 서비스를 초기화한 뒤 설정에 지정한 첫 장면으로 진입한다.
extends Node

const INIT_METHOD := "before_app_initialize"

func _ready() -> void:
	if OS.has_feature("pgs_probe"):
		SceneManager.change_scene("res://scenes/android_game_services_probe.tscn", false)
		return
	var init_script := str(GameConfig.value("app", "init_script", ""))
	var init_error := run_init_script(init_script)
	if init_error != OK:
		push_error("Game init script failed (%s): %s" % [error_string(init_error), init_script])
	App.initialize()
	SceneManager.change_scene(str(GameConfig.value("app", "main_scene", "res://scenes/main.tscn")))

## 게임 초기화 script의 before_app_initialize()를 App.initialize() 전에 한 번 호출한다.
## 경로가 비어 있으면 OK를 반환한다. 실패 시 hook을 호출하지 않고 오류 코드를 반환한다.
static func run_init_script(path: String) -> Error:
	if path.is_empty():
		return OK
	if not ResourceLoader.exists(path):
		return ERR_FILE_NOT_FOUND
	var script := load(path) as Script
	if script == null or not script.can_instantiate():
		return ERR_CANT_CREATE
	var hook: Object = script.new()
	if not hook is RefCounted:
		hook.free()
		return ERR_INVALID_PARAMETER
	if not hook.has_method(INIT_METHOD):
		return ERR_METHOD_NOT_FOUND
	hook.call(INIT_METHOD)
	return OK
