## 동의 상태가 확정되기 전 광고 및 분석 사용을 차단하는 최소 개인정보 서비스이다.
class_name PrivacyService
extends Node

signal consent_updated(status: String)
var status := "unknown"
var enabled := false
var adapter: PrivacyAdapter

## 기능 활성화 값과 adapter를 연결하고 결과 신호를 서비스에 전달한다.
func initialize(active: bool, implementation: PrivacyAdapter) -> void:
	enabled = active
	adapter = implementation
	add_child(adapter)
	adapter.consent_updated.connect(func(value: String):
		status = value
		consent_updated.emit(status))

## 실제 통합 시 UMP와 ATT 상태를 adapter 내부에서 각각 처리한다.
func request_consent() -> void:
	if not enabled:
		status = "disabled"
		consent_updated.emit(status)
		return
	adapter.request_consent()

## 광고와 분석을 사용해도 되는 확정 상태인지 반환한다.
func can_use_services() -> bool:
	return enabled and status == "granted"

## 다음 Mock 동의 요청의 결과를 지정한다.
func set_mock_status(value: String) -> void:
	if adapter is MockPrivacyAdapter:
		adapter.next_status = value if value in ["granted", "denied", "unknown"] else "unknown"
