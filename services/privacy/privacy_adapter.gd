## UMP/ATT 등 개인정보 흐름을 숨기는 계약이다. 실제 동의 상태를 추측하지 않는다.
class_name PrivacyAdapter
extends Node

signal consent_updated(status: String)

## 개인정보 동의 흐름을 요청하고 결과 상태를 알린다.
func request_consent() -> void:
	consent_updated.emit("unavailable")
