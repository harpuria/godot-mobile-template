## 게임 서비스의 비동기 요청 계약과 진행 중인 네이티브 요청을 관리한다.
class_name GameServicesAdapter
extends Node

signal completed(request_id: int, details: Dictionary)
signal failed(request_id: int, reason: String)

var _pending_id := 0
var _operation := ""
var _payload: Dictionary = {}
var _abandoned := false

## SDK가 없는 기본 구현은 초기화하지 않는다.
func initialize() -> void:
	pass

## SDK를 사용할 수 있는지 확인한다.
func is_available() -> bool:
	return false

## 현재 플랫폼 인증 상태를 확인한다.
func is_authenticated() -> bool:
	return false

## 타임아웃 뒤에도 완료되지 않은 OS 작업을 포함해 요청 잠금을 조회한다.
func is_busy() -> bool:
	return _pending_id != 0

## 구현하지 않은 요청은 명시적으로 실패한다.
func execute(request_id: int, _kind: String, _data: Dictionary) -> void:
	failed.emit(request_id, "unavailable")

## 취소할 수 없는 OS 요청은 콜백을 받을 때까지 잠금을 유지한다.
func abandon(request_id: int) -> void:
	if request_id == _pending_id:
		_abandoned = true

func _begin(request_id: int, kind: String, data: Dictionary) -> bool:
	if _pending_id != 0:
		failed.emit(request_id, "busy")
		return false
	_pending_id = request_id
	_operation = kind
	_payload = data.duplicate(true)
	_abandoned = false
	return true

func _finish(reason: String = "", details: Dictionary = {}) -> void:
	var request_id := _pending_id
	var abandoned := _abandoned
	_pending_id = 0
	_operation = ""
	_payload = {}
	_abandoned = false
	if request_id == 0 or abandoned:
		return
	if reason.is_empty():
		completed.emit(request_id, details)
	else:
		failed.emit(request_id, reason)
