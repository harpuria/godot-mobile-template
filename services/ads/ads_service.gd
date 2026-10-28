## 게임에 광고 API를 제공하고 활성화 여부와 개인정보 정책을 검사한다.
class_name AdsService
extends Node

signal rewarded_completed(placement_id: String)
signal rewarded_failed(placement_id: String, reason: String)
signal interstitial_closed(placement_id: String)
signal ad_failed(placement_id: String, reason: String)
var adapter: AdsAdapter
var privacy: PrivacyService
var enabled := false

## App이 플래그에 따라 adapter를 선택한다. SDK 초기화는 adapter 내부에서만 수행한다.
func initialize(active: bool, implementation: AdsAdapter, privacy_service: PrivacyService) -> void:
	enabled = active
	privacy = privacy_service
	adapter = implementation
	add_child(adapter)
	adapter.rewarded_completed.connect(func(id: String): rewarded_completed.emit(id))
	adapter.rewarded_failed.connect(func(id: String, reason: String): rewarded_failed.emit(id, reason))
	adapter.interstitial_closed.connect(func(id: String): interstitial_closed.emit(id))
	adapter.ad_failed.connect(func(id: String, reason: String): ad_failed.emit(id, reason))
	if enabled:
		adapter.initialize(privacy)

## 보상형 광고 요청을 받을 수 있는지 반환한다.
func is_rewarded_ready() -> bool:
	return enabled and privacy.can_request_ads() and adapter.is_rewarded_ready()

## 전면 광고 요청을 받을 수 있는지 반환한다.
func is_interstitial_ready() -> bool:
	return enabled and privacy.can_request_ads() and adapter.is_interstitial_ready()

## 수락 여부와 관계없이 결과 신호가 발생한다. 보상은 completed에서만 지급한다.
func show_rewarded(placement_id: String) -> void:
	if placement_id.is_empty() or not is_rewarded_ready():
		rewarded_failed.emit(placement_id, "disabled_consent_or_not_ready")
		return
	adapter.show_rewarded(placement_id)

## 전면 광고 표시를 요청하고 종료 또는 실패를 신호로 전달한다.
func show_interstitial(placement_id: String) -> void:
	if placement_id.is_empty() or not is_interstitial_ready():
		ad_failed.emit(placement_id, "disabled_consent_or_not_ready")
		return
	adapter.show_interstitial(placement_id)

func show_banner(placement_id: String) -> void:
	if not enabled or not privacy.can_request_ads():
		ad_failed.emit(placement_id, "disabled_or_consent_required")
		return
	adapter.show_banner(placement_id)

## adapter가 표시 중인 배너를 숨긴다.
func hide_banner() -> void:
	adapter.hide_banner()

## 개발용 결과 제어이며 native adapter에는 적용되지 않는다.
func set_mock_result(result: String) -> void:
	if adapter is MockAdsAdapter:
		adapter.set_next_result(result)
