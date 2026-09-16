## 스토어 리뷰 요청 계약이다. OS는 실제 팝업 표시를 보장하지 않는다.
class_name ReviewAdapter
extends Node

signal request_finished(status: String)

## 선택적 스토어 리뷰 요청의 처리 결과를 알린다.
func request_review() -> void:
	request_finished.emit("unavailable")
