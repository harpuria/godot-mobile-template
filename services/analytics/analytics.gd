## 기능 플래그와 동의 상태를 확인한 후 분석 adapter를 호출한다.
class_name Analytics
extends Node

var enabled := false
var adapter: AnalyticsAdapter
var privacy: PrivacyService

## 기능 활성화 값과 adapter를 연결하고 결과 신호를 서비스에 전달한다.
func initialize(active: bool, implementation: AnalyticsAdapter, privacy_service: PrivacyService) -> void:
	enabled = active
	privacy = privacy_service
	adapter = implementation
	add_child(adapter)

## 호출 수락 여부를 반환한다. SDK 전송 성공을 보장하지 않는다.
func track_event(event_name: String, properties: Dictionary = {}) -> bool:
	if not enabled or not privacy.can_use_services() or event_name.is_empty():
		return false
	adapter.track_event(event_name, properties)
	return true

## 사용자 속성을 adapter로 전달한다. 개인정보는 호출자가 최소화한다.
func set_user_property(key: String, value: String) -> bool:
	if not enabled or not privacy.can_use_services() or key.is_empty():
		return false
	adapter.set_user_property(key, value)
	return true
