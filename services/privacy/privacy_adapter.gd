## UMP/ATT 등 개인정보 흐름을 숨기는 계약이다. 실제 동의 상태를 추측하지 않는다.
class_name PrivacyAdapter
extends Node

signal consent_updated(status: String)

## 활성 서비스만 네이티브 신호를 연결한다.
func initialize() -> void:
	pass

## UMP 광고 요청 자격은 분석·개인화 동의와 별도로 해석한다.
func can_request_ads() -> bool:
	return false

## 이용자가 개인정보 선택을 다시 열 수 있는 경로다.
func show_privacy_options() -> void:
	consent_updated.emit("unavailable")

## 개인정보 동의 흐름을 요청하고 결과 상태를 알린다.
func request_consent() -> void:
	consent_updated.emit("unavailable")
