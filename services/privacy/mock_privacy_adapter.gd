## 개발 테스트 전용 동의 결과이다. 법적 동의나 실제 ATT 승인으로 간주하지 않는다.
class_name MockPrivacyAdapter
extends PrivacyAdapter

var next_status := "granted"

## 개인정보 동의 흐름을 요청하고 결과 상태를 알린다.
func request_consent() -> void:
	AppLogger.info("MockPrivacy", "Simulated consent: " + next_status)
	consent_updated.emit(next_status)
