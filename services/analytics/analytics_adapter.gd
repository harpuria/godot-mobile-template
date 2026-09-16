## 특정 분석 SDK에 종속되지 않는 이벤트 및 사용자 속성 계약이다.
class_name AnalyticsAdapter
extends Node

func track_event(_event_name: String, _properties: Dictionary) -> void:
	pass

## 사용자 속성을 adapter로 전달한다. 개인정보는 호출자가 최소화한다.
func set_user_property(_key: String, _value: String) -> void:
	pass
