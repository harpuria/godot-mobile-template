## 이벤트 이름만 로그로 남기고 개인정보 및 속성 값은 외부로 전송하지 않는다.
class_name MockAnalyticsAdapter
extends AnalyticsAdapter

func track_event(event_name: String, _properties: Dictionary) -> void:
	AppLogger.info("MockAnalytics", "Event: " + event_name)

## 사용자 속성을 adapter로 전달한다. 개인정보는 호출자가 최소화한다.
func set_user_property(key: String, _value: String) -> void:
	AppLogger.info("MockAnalytics", "Property: " + key)
