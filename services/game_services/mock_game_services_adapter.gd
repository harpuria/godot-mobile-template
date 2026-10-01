## 실제 계정이나 보상 없이 게임 서비스 요청을 연습하는 개발용 Mock이다.
class_name MockGameServicesAdapter
extends GameServicesAdapter

var outcome := "success"
var _authenticated := false
var scores: Dictionary = {}
var achievements: Dictionary = {}

func is_available() -> bool:
	return OS.is_debug_build()

func is_authenticated() -> bool:
	return is_available() and _authenticated

## 결과를 비동기로 전달하며 release에서는 성공을 만들지 않는다.
func execute(request_id: int, kind: String, data: Dictionary) -> void:
	if not is_available():
		failed.emit(request_id, "unavailable")
		return
	if not _begin(request_id, kind, data):
		return
	var selected := outcome
	await get_tree().create_timer(0.05).timeout
	if _abandoned:
		_finish()
		return
	if selected != "success":
		if kind == "authenticate":
			_authenticated = false
		_finish("cancelled" if selected == "cancel" else "mock_error")
		return
	match kind:
		"authenticate":
			_authenticated = true
		"submit_score":
			scores[data.native_id] = data.score
		"unlock_achievement":
			achievements[data.native_id] = true
	_finish("", {"mock": true, "ui_status": "requested"} if kind.begins_with("show_") else {"mock": true})
