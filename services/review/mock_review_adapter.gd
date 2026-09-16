## 실제 리뷰 없이 요청 흐름을 확인하는 Mock이다.
class_name MockReviewAdapter
extends ReviewAdapter

## 선택적 스토어 리뷰 요청의 처리 결과를 알린다.
func request_review() -> void:
	AppLogger.info("MockReview", "Review requested")
	request_finished.emit("mock_requested")
