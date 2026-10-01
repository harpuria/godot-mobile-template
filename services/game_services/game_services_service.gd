## 플랫폼 공통 로그인, 업적, 리더보드 API와 요청 검증을 제공한다.
class_name GameServicesService
extends Node

signal request_completed(operation: String, details: Dictionary)
signal request_failed(operation: String, reason: String)

var enabled := false
var adapter: GameServicesAdapter
var _platform := ""
var _leaderboards: Dictionary = {}
var _achievements: Dictionary = {}
var _next_id := 0
var _active_id := 0
var _operation := ""
var _logical_id := ""
var _timeout: Timer

## 기능이 활성화된 경우에만 SDK를 초기화하고 요청 제한 시간을 적용한다.
func initialize(active: bool, implementation: GameServicesAdapter, leaderboards: Dictionary,
		achievements: Dictionary, platform: String, timeout_seconds: float = 120.0) -> void:
	enabled = active
	adapter = implementation
	_platform = platform
	_leaderboards = leaderboards.duplicate(true)
	_achievements = achievements.duplicate(true)
	add_child(adapter)
	adapter.completed.connect(_on_completed)
	adapter.failed.connect(_on_failed)
	_timeout = Timer.new()
	_timeout.one_shot = true
	_timeout.wait_time = timeout_seconds if is_finite(timeout_seconds) and timeout_seconds > 0.0 else 120.0
	add_child(_timeout)
	_timeout.timeout.connect(_on_timeout)
	if enabled:
		adapter.initialize()

## 로그인 상태는 Adapter의 현재 플랫폼 상태를 조회한다.
func is_authenticated() -> bool:
	return enabled and adapter != null and adapter.is_authenticated()

## 사용자 동작에 의해 플랫폼 로그인을 요청한다.
func authenticate() -> Error:
	return _request("authenticate")

## 게임의 논리 리더보드 ID로 점수를 제출한다.
func submit_score(leaderboard_id: String, score: int) -> Error:
	return _request("submit_score", leaderboard_id, {"score": score})

## 일반 업적을 완료한다. Android 증분 업적은 별도 계약이 필요하다.
func unlock_achievement(achievement_id: String) -> Error:
	return _request("unlock_achievement", achievement_id)

## 플랫폼 리더보드 화면을 요청한다. 표시 또는 종료를 보장하지 않는다.
func show_leaderboard(leaderboard_id: String) -> Error:
	return _request("show_leaderboard", leaderboard_id)

## 플랫폼 업적 화면을 요청한다. 보상을 지급하지 않는다.
func show_achievements() -> Error:
	return _request("show_achievements")

## 개발용 결과를 선택한다. 실제 플랫폼 상태에는 영향을 주지 않는다.
func set_mock_result(result: String) -> void:
	if adapter is MockGameServicesAdapter and OS.is_debug_build():
		adapter.outcome = result

func _request(kind: String, logical_id: String = "", data: Dictionary = {}) -> Error:
	if not enabled:
		return _reject(kind, "disabled", ERR_UNAVAILABLE)
	if _active_id != 0 or (adapter != null and adapter.is_busy()):
		return _reject(kind, "busy", ERR_BUSY)
	if adapter == null or not adapter.is_available():
		return _reject(kind, "unavailable", ERR_UNAVAILABLE)
	if kind != "authenticate" and not is_authenticated():
		return _reject(kind, "not_authenticated", ERR_UNAUTHORIZED)
	if kind in ["submit_score", "show_leaderboard", "unlock_achievement"]:
		var mapping := _achievements if kind == "unlock_achievement" else _leaderboards
		if logical_id.is_empty() or not mapping.has(logical_id) or not mapping[logical_id] is Dictionary:
			return _reject(kind, "invalid_id", ERR_INVALID_PARAMETER)
		var native_id: Variant = logical_id if adapter is MockGameServicesAdapter else mapping[logical_id].get(_platform, "")
		if not native_id is String or native_id.strip_edges().is_empty():
			return _reject(kind, "unconfigured_id", ERR_UNCONFIGURED)
		data["native_id"] = native_id
	_next_id += 1
	_active_id = _next_id
	_operation = kind
	_logical_id = logical_id
	_timeout.start()
	adapter.execute(_active_id, kind, data)
	return OK

func _reject(kind: String, reason: String, error: Error) -> Error:
	request_failed.emit(kind, reason)
	return error

func _on_completed(request_id: int, details: Dictionary) -> void:
	if request_id != _active_id or _active_id == 0:
		return
	var kind := _operation
	var result := details.duplicate(true)
	result["logical_id"] = _logical_id
	_clear_request()
	request_completed.emit(kind, result)

func _on_failed(request_id: int, reason: String) -> void:
	if request_id != _active_id or _active_id == 0:
		return
	var kind := _operation
	_clear_request()
	request_failed.emit(kind, reason)

func _on_timeout() -> void:
	adapter.abandon(_active_id)
	_on_failed(_active_id, "timeout")

func _clear_request() -> void:
	_timeout.stop()
	_active_id = 0
	_operation = ""
	_logical_id = ""
