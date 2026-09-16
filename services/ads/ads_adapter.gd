## 광고 SDK 구현 계약이다. 기본 구현은 사용할 수 없는 상태를 반환한다.
class_name AdsAdapter
extends Node

signal rewarded_completed(placement_id: String)
signal rewarded_failed(placement_id: String, reason: String)
signal interstitial_closed(placement_id: String)
signal ad_failed(placement_id: String, reason: String)

## 보상형 광고 요청을 받을 수 있는지 반환한다.
func is_rewarded_ready() -> bool:
	return false

## 전면 광고 요청을 받을 수 있는지 반환한다.
func is_interstitial_ready() -> bool:
	return false

## 실제 adapter는 SDK가 보상을 승인했을 때만 rewarded_completed를 발생시킨다.
func show_rewarded(placement_id: String) -> void:
	rewarded_failed.emit(placement_id, "unavailable")

## 전면 광고 표시를 요청하고 종료 또는 실패를 신호로 전달한다.
func show_interstitial(placement_id: String) -> void:
	ad_failed.emit(placement_id, "unavailable")

## 배너는 첫 버전에서 선택적 기능으로 예약한다.
func show_banner(placement_id: String) -> void:
	ad_failed.emit(placement_id, "banner_not_implemented")

## adapter가 표시 중인 배너를 숨긴다.
func hide_banner() -> void:
	pass
