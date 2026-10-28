## Godot Play Game Services v3.4.0의 Android singleton을 공통 계약으로 연결한다.
class_name AndroidGameServicesAdapter
extends GameServicesAdapter

var _plugin: Object
var _authenticated := false
var _checking_auth := false

## Android에서만 설치된 SDK를 검색한다. 미설치 시 unavailable을 유지한다.
func initialize() -> void:
	if OS.get_name() == "Android" and Engine.has_singleton("GodotPlayGameServices"):
		var game_id := str(GameConfig.value("game_services", "android_game_id", ""))
		if game_id.is_empty() or not game_id.is_valid_int() or game_id.to_int() <= 0 or game_id != str(game_id.to_int()):
			AppLogger.info("PlayGames", "Game ID unset; SDK initialization skipped")
			return
		_bind_plugin(Engine.get_singleton("GodotPlayGameServices"))

func _bind_plugin(candidate: Object) -> void:
	for method in ["initialize", "isAuthenticated", "signIn", "unlockAchievement", "submitScore", "showLeaderboard", "showAchievements"]:
		if not supports_plugin_method(candidate, method):
			return
	for event in ["userAuthenticated", "achievementUnlocked", "scoreSubmitted"]:
		if not candidate.has_signal(event):
			return
	_plugin = candidate
	_plugin.connect("userAuthenticated", _on_authenticated)
	_plugin.connect("achievementUnlocked", _on_achievement)
	_plugin.connect("scoreSubmitted", _on_score)
	_plugin.call("initialize")

## Godot 4.7.2 JNI singleton은 Java 메서드를 has_java_method로 조회한다.
static func supports_plugin_method(candidate: Object, method: String) -> bool:
	return AndroidPlugin.supports(candidate, method)

func is_available() -> bool:
	return is_instance_valid(_plugin)

func is_authenticated() -> bool:
	return is_available() and _authenticated

## SDK 완료 콜백을 기다린다. 화면 요청은 콜백이 없어 requested만 반환한다.
func execute(request_id: int, kind: String, data: Dictionary) -> void:
	if not is_available():
		failed.emit(request_id, "unavailable")
		return
	if not _begin(request_id, kind, data):
		return
	if kind != "authenticate":
		_checking_auth = true
		_plugin.call("isAuthenticated")
		return
	_dispatch()

func _dispatch() -> void:
	match _operation:
		"authenticate":
			_plugin.call("signIn")
		"submit_score":
			_plugin.call("submitScore", _payload.native_id, _payload.score)
		"unlock_achievement":
			_plugin.call("unlockAchievement", _payload.native_id)
		"show_leaderboard":
			_plugin.call("showLeaderboard", _payload.native_id)
			_finish("", {"ui_status": "requested"})
		"show_achievements":
			_plugin.call("showAchievements")
			_finish("", {"ui_status": "requested"})
		_:
			_finish("unsupported")

func _on_authenticated(authenticated: bool) -> void:
	_authenticated = authenticated
	if _checking_auth:
		_checking_auth = false
		if _abandoned or not authenticated:
			_finish("not_authenticated")
		else:
			_dispatch()
		return
	if _operation == "authenticate":
		_finish("" if authenticated else "authentication_failed")

func _on_achievement(success: bool, native_id: String) -> void:
	if _operation == "unlock_achievement" and _payload.get("native_id") == native_id:
		_finish("" if success else "native_error")

func _on_score(success: bool, native_id: String) -> void:
	if _operation == "submit_score" and _payload.get("native_id") == native_id:
		_finish("" if success else "native_error")

func _exit_tree() -> void:
	if not is_instance_valid(_plugin):
		return
	_plugin.disconnect("userAuthenticated", _on_authenticated)
	_plugin.disconnect("achievementUnlocked", _on_achievement)
	_plugin.disconnect("scoreSubmitted", _on_score)
