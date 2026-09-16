## 선택적 리뷰 기능의 활성화 여부와 결과를 관리한다.
class_name ReviewService
extends Node

signal request_finished(status: String)
var enabled := false
var adapter: ReviewAdapter

## 기능 활성화 값과 adapter를 연결하고 결과 신호를 서비스에 전달한다.
func initialize(active: bool, implementation: ReviewAdapter) -> void:
	enabled = active
	adapter = implementation
	add_child(adapter)
	adapter.request_finished.connect(func(status: String): request_finished.emit(status))

## 선택적 스토어 리뷰 요청의 처리 결과를 알린다.
func request_review() -> void:
	if not enabled:
		request_finished.emit("disabled")
		return
	adapter.request_review()
