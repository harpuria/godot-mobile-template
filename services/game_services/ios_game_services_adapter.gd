## 기존 Godot iOS GameCenter singleton의 이벤트 큐를 공통 계약으로 연결한다.
class_name IOSGameServicesAdapter
extends GameServicesAdapter

var _plugin: Object
var _event_type := ""

## iOS에서만 GameCenter를 검색하며 설치되지 않은 SDK는 호출하지 않는다.
func initialize() -> void:
	if OS.get_name() == "iOS" and Engine.has_singleton("GameCenter"):
		_bind_plugin(Engine.get_singleton("GameCenter"))

func _bind_plugin(candidate: Object) -> void:
	for method in ["authenticate", "is_authenticated", "post_score", "award_achievement",
			"show_game_center", "get_pending_event_count", "pop_pending_event"]:
		if not candidate.has_method(method):
			return
	_plugin = candidate
	set_process(true)

func is_available() -> bool:
	return is_instance_valid(_plugin)

func is_authenticated() -> bool:
	return is_available() and bool(_plugin.call("is_authenticated"))

## OS 콜백이 요청 ID를 제공하지 않으므로 한 번에 한 요청만 처리한다.
func execute(request_id: int, kind: String, data: Dictionary) -> void:
	if not is_available():
		failed.emit(request_id, "unavailable")
		return
	# 기존 플러그인은 score를 float32로 변환하므로 정밀도가 손실되는 점수는 거절한다.
	if kind == "submit_score" and (int(data.score) < -16777216 or int(data.score) > 16777216):
		failed.emit(request_id, "score_out_of_range")
		return
	if not _begin(request_id, kind, data):
		return
	var error: int
	match kind:
		"authenticate":
			_event_type = "authentication"
			error = int(_plugin.call("authenticate"))
		"submit_score":
			_event_type = "post_score"
			error = int(_plugin.call("post_score", {"category": data.native_id, "score": data.score}))
		"unlock_achievement":
			_event_type = "award_achievement"
			error = int(_plugin.call("award_achievement", {"name": data.native_id, "progress": 100.0,
				"show_completion_banner": true}))
		"show_leaderboard", "show_achievements":
			_event_type = "show_game_center"
			var params := {"view": "achievements"}
			if kind == "show_leaderboard":
				params = {"view": "leaderboards", "leaderboard_name": data.native_id}
			error = int(_plugin.call("show_game_center", params))
		_:
			_finish("unsupported")
			return
	if error != OK:
		_finish("native_error:%s" % error)

## 매 프레임 큐를 읽고 관계없는 이벤트는 현재 요청에 전달하지 않는다.
func _process(_delta: float) -> void:
	if not is_available():
		return
	# 결과 신호를 내기 전에 현재 큐를 비워 재진입 요청에 중복 이벤트가 전달되지 않게 한다.
	var events: Array[Dictionary] = []
	var count := mini(int(_plugin.call("get_pending_event_count")), 32)
	for _index in range(count):
		var event: Variant = _plugin.call("pop_pending_event")
		if event is Dictionary:
			events.append(event)
	for event in events:
		if _pending_id == 0 or event.get("type") != _event_type:
			continue
		var details := {"ui_status": "closed"} if _operation.begins_with("show_") else {}
		_finish("" if event.get("result") == "ok" else "native_error:%s" % event.get("error_code", -1), details)
		break
