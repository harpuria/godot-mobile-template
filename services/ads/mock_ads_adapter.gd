## SDK 없이 지연된 광고 결과를 발생시키는 개발용 Mock이다.
class_name MockAdsAdapter
extends AdsAdapter

var busy := false
var next_result := "success"

## 보상형 광고 요청을 받을 수 있는지 반환한다.
func is_rewarded_ready() -> bool:
	return not busy

## 전면 광고 요청을 받을 수 있는지 반환한다.
func is_interstitial_ready() -> bool:
	return not busy

## success 또는 error를 다음 한 요청에만 적용한다.
func set_next_result(result: String) -> void:
	next_result = result if result in ["success", "error"] else "error"

func show_rewarded(placement_id: String) -> void:
	if busy:
		rewarded_failed.emit(placement_id, "busy")
		return
	busy = true
	var result := next_result
	next_result = "success"
	AppLogger.info("MockAds", "Rewarded: " + placement_id)
	await get_tree().create_timer(0.3).timeout
	busy = false
	if result == "success":
		rewarded_completed.emit(placement_id)
	else:
		rewarded_failed.emit(placement_id, "mock_error")

## 전면 광고 표시를 요청하고 종료 또는 실패를 신호로 전달한다.
func show_interstitial(placement_id: String) -> void:
	if busy:
		ad_failed.emit(placement_id, "busy")
		return
	busy = true
	var result := next_result
	next_result = "success"
	AppLogger.info("MockAds", "Interstitial: " + placement_id)
	await get_tree().create_timer(0.3).timeout
	busy = false
	if result == "success":
		interstitial_closed.emit(placement_id)
	else:
		ad_failed.emit(placement_id, "mock_error")
