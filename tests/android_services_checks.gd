## Android 결제·광고·UMP의 실제 JNI 계약과 실패·중복·동의 경로를 가짜 SDK로 검사한다.
extends Node

class BillingSDK extends Node:
	signal connected
	signal disconnected
	signal connect_error(code: int, message: String)
	signal query_product_details_response(response: Dictionary)
	signal query_purchases_response(response: Dictionary)
	signal on_purchase_updated(response: Dictionary)
	signal consume_purchase_response(response: Dictionary)
	signal acknowledge_purchase_response(response: Dictionary)
	var calls: Array = []
	var billing_ready := true
	var launch_code := 0
	func initPlugin() -> void: calls.append(["init"])
	func startConnection() -> void: calls.append(["connect"])
	func endConnection() -> void: calls.append(["disconnect"])
	func isReady() -> bool: return billing_ready
	func queryProductDetails(ids: PackedStringArray, kind: String) -> void: calls.append(["details", ids, kind])
	func queryPurchases(kind: String, suspended: bool) -> void: calls.append(["restore", kind, suspended])
	func purchase(id: String, option: String, offer: String, personalized: bool) -> Dictionary:
		calls.append(["purchase", id, option, offer, personalized])
		return {"response_code": launch_code}
	func purchaseSubscription(id: String, plan: String, offer: String, personalized: bool) -> Dictionary:
		calls.append(["subscription", id, plan, offer, personalized])
		return {"response_code": launch_code}
	func consumePurchase(token: String) -> void: calls.append(["consume", token])
	func acknowledgePurchase(token: String) -> void: calls.append(["acknowledge", token])

class BillingHarness extends AndroidBillingAdapter:
	var sdk := BillingSDK.new()
	func initialize() -> void:
		add_child(sdk)
		_bind_plugin(sdk)

class OneStoreSDK extends BillingSDK:
	var public_key := ""
	func setPublicKey(key: String) -> void:
		public_key = key
		calls.append(["key", key])

class OneStoreHarness extends OneStoreBillingAdapter:
	var sdk := OneStoreSDK.new()
	func initialize() -> void:
		add_child(sdk)
		_bind_plugin(sdk)

class CoreSDK extends Node:
	signal on_initialization_complete(status: Dictionary)
	var initializes := 0
	func initialize() -> void: initializes += 1
	func set_request_configuration(_config: Dictionary, _ids: PackedStringArray) -> void: pass

class AdSDK extends Node:
	signal on_rewarded_ad_loaded(uid: int)
	signal on_rewarded_ad_failed_to_load(uid: int, error: Dictionary)
	signal on_rewarded_ad_dismissed_full_screen_content(uid: int)
	signal on_rewarded_ad_failed_to_show_full_screen_content(uid: int, error: Dictionary)
	signal on_rewarded_ad_user_earned_reward(uid: int, reward: Dictionary)
	signal on_interstitial_ad_loaded(uid: int)
	signal on_interstitial_ad_failed_to_load(uid: int, error: Dictionary)
	signal on_interstitial_ad_dismissed_full_screen_content(uid: int)
	signal on_interstitial_ad_failed_to_show_full_screen_content(uid: int, error: Dictionary)
	var calls: Array = []
	var next_uid := 0
	func create() -> int:
		next_uid += 1
		return next_uid
	func load(id: String, request: Dictionary, keywords: PackedStringArray, uid: int) -> void: calls.append(["load", id, request, keywords, uid])
	func show(uid: int) -> void: calls.append(["show", uid])
	func destroy(uid: int) -> void: calls.append(["destroy", uid])

class AdsHarness extends AndroidAdmobAdapter:
	var core := CoreSDK.new()
	var rewarded := AdSDK.new()
	var interstitial := AdSDK.new()
	func initialize(privacy: PrivacyService) -> void:
		add_child(core)
		add_child(rewarded)
		add_child(interstitial)
		_bind_plugins(core, rewarded, interstitial, privacy)

class InfoSDK extends Node:
	signal on_consent_info_updated_success
	signal on_consent_info_updated_failure(error: Dictionary)
	var status := 2
	var option_status := 2
	var updates := 0
	func update(_request: Dictionary) -> void: updates += 1
	func get_consent_status() -> int: return status
	func get_is_consent_form_available() -> bool: return true
	func get_privacy_options_requirement_status() -> int: return option_status

class FormsSDK extends Node:
	signal on_consent_form_load_success_listener(uid: int)
	signal on_consent_form_load_failure_listener(error: Dictionary)
	signal on_consent_form_dismissed(uid: int, error: Dictionary)
	signal on_privacy_options_form_dismissed_listener(error: Dictionary)
	var calls: Array = []
	func load_consent_form() -> void: calls.append(["load"])
	func show(uid: int) -> void: calls.append(["show", uid])
	func show_privacy_options_form() -> void: calls.append(["options"])

class PrivacyHarness extends AndroidAdmobPrivacyAdapter:
	var info := InfoSDK.new()
	var forms := FormsSDK.new()
	func initialize() -> void:
		add_child(info)
		add_child(forms)
		_bind_plugins(info, forms)

var events: Array = []

## 계약 검사는 실기기·스토어 검증을 대신하지 않는다.
func run(test: Node) -> void:
	_billing(test)
	_restore_entitlements(test)
	_onestore(test)
	await _ads_and_privacy(test)
	for adapter in [AndroidBillingAdapter.new(), AndroidAdmobAdapter.new(), AndroidAdmobPrivacyAdapter.new()]:
		test.add_child(adapter)
		if adapter is AndroidAdmobAdapter:
			adapter.initialize(App.privacy)
		else:
			adapter.initialize()
		test.check(adapter._plugin == null if adapter is AndroidBillingAdapter else adapter._core == null if adapter is AndroidAdmobAdapter else adapter._info == null, "Android SDK absent on Desktop remains unavailable")
		adapter.queue_free()
	var disabled := BillingService.new()
	test.add_child(disabled)
	var unused := BillingHarness.new()
	disabled.initialize(false, unused)
	test.check(unused.sdk.calls.is_empty(), "Disabled billing does not initialize native SDK")
	unused.sdk.free()
	disabled.queue_free()

func _transaction(id: String, token: String, state: int = 1) -> Dictionary:
	return {"product_ids": PackedStringArray([id]), "purchase_token": token, "purchase_state": state, "is_acknowledged": false, "signature": "fake-signature", "original_json": "{}"}

func _detail(id: String, options: Array = []) -> Dictionary:
	return {"product_id": id, "one_time_purchase_offer_details_list": options if not options.is_empty() else [{"purchase_option_id": "buy", "offer_id": null}]}

func _billing(test: Node) -> void:
	var service := BillingService.new()
	test.add_child(service)
	var adapter := BillingHarness.new()
	service.initialize(true, adapter)
	var sdk := adapter.sdk
	service.purchase_completed.connect(func(id: String, tx: Dictionary): events.append(["completed", id, tx]))
	service.purchase_cancelled.connect(func(id: String): events.append(["cancelled", id]))
	service.purchase_failed.connect(func(id: String, reason: String): events.append(["failed", id, reason]))
	service.purchase_pending.connect(func(id: String, tx: Dictionary): events.append(["pending", id, tx]))
	service.transaction_received.connect(func(id: String, tx: Dictionary): events.append(["received", id, tx]))
	service.restore_completed.connect(func(items: Array): events.append(["restored", items]))
	service.products_updated.connect(func(items: Array): events.append(["products", items]))
	service.products_failed.connect(func(reason: String): events.append(["products_failed", reason]))
	test.check(sdk.calls.back() == ["restore", "inapp", false], "Billing start syncs owned purchases before any game request")
	sdk.query_purchases_response.emit({"response_code": 0, "purchases": [_transaction("com.example.game.coin_small", "cold")]})
	sdk.query_purchases_response.emit({"response_code": 0, "purchases": []})
	test.check(events.size() == 1 and events.back()[0] == "received" and events.back()[2].purchase_token == "cold", "Cold-start sync re-delivers unfinished purchase for verification")
	test.check(not service.busy and adapter._operation.is_empty(), "Silent sync releases billing without restore signal")
	test.check(service.get_unfinished_transactions().size() == 1 and service.get_unfinished_transactions()[0].purchase_token == "cold", "Unfinished transactions remain queryable for late listeners")
	service.purchase("REMOVE_ADS")
	test.check(sdk.calls.back() == ["details", PackedStringArray(["com.example.game.remove_ads"]), "inapp"], "Billing queries mapped store product before launch")
	sdk.query_product_details_response.emit({"response_code": 0, "product_details": [_detail("com.example.game.remove_ads")]})
	test.check(sdk.calls.back() == ["purchase", "com.example.game.remove_ads", "buy", "", false], "Billing 3.3.0 purchase option arguments")
	var tx := _transaction("com.example.game.remove_ads", "owned")
	sdk.on_purchase_updated.emit({"response_code": 0, "purchases": [tx]})
	test.check(events.back()[0] == "received" and not events.back()[2].verified and not service.busy, "Purchased transaction requires explicit game verification")
	test.check(sdk.calls.back()[0] == "purchase", "Unverified purchase is not acknowledged or consumed")
	var count := events.size()
	sdk.on_purchase_updated.emit({"response_code": 0, "purchases": [tx]})
	test.check(events.size() == count, "Duplicate native transaction is not delivered twice")
	test.check(service.finish_purchase("unknown") == ERR_INVALID_PARAMETER, "Unknown finish token rejected")
	test.check(service.finish_purchase("owned") == OK and sdk.calls.back() == ["acknowledge", "owned"], "Verified non-consumable uses acknowledge")
	sdk.acknowledge_purchase_response.emit({"response_code": 0, "token": "wrong"})
	test.check(events.size() == count, "Wrong finalization token cannot complete purchase")
	sdk.acknowledge_purchase_response.emit({"response_code": 0, "token": "owned"})
	test.check(events.back()[0] == "completed" and events.back()[2].finished, "Purchase completes after matching acknowledge callback")
	test.check(service.finish_purchase("owned") == ERR_INVALID_PARAMETER, "Finished token cannot be finished twice")
	service.purchase("COIN_SMALL")
	sdk.query_product_details_response.emit({"response_code": 0, "product_details": [_detail("com.example.game.coin_small")]})
	sdk.on_purchase_updated.emit({"response_code": 0, "purchases": [_transaction("com.example.game.coin_small", "pending", 2)]})
	test.check(events.back()[0] == "pending" and service.finish_purchase("pending") == ERR_INVALID_PARAMETER, "Pending purchase never grants or consumes")
	sdk.on_purchase_updated.emit({"response_code": 0, "purchases": [_transaction("com.example.game.coin_small", "pending")]})
	test.check(events.back()[0] == "received", "Pending purchase later becomes verifiable")
	service.finish_purchase("pending")
	test.check(sdk.calls.back() == ["consume", "pending"], "Consumable uses consume after explicit confirmation")
	sdk.consume_purchase_response.emit({"response_code": 6, "token": "pending"})
	test.check(events.back()[2] == "finish_failed:6", "Failed consume does not complete purchase")
	test.check(service.finish_purchase("pending") == OK, "Failed consume can be retried")
	sdk.consume_purchase_response.emit({"response_code": 0, "token": "pending"})
	service.purchase("PREMIUM", {"base_plan_id": "monthly"})
	sdk.query_product_details_response.emit({"response_code": 0, "product_details": [{"product_id": "com.example.game.premium", "subscription_offer_details": [{"base_plan_id": "monthly", "offer_id": null}]}]})
	test.check(sdk.calls.back()[0] == "subscription" and sdk.calls.back()[2] == "monthly", "Subscription uses selected base plan")
	sdk.on_purchase_updated.emit({"response_code": 1})
	test.check(events.back()[0] == "cancelled" and not service.busy, "Native purchase cancellation releases service")
	service.purchase("REMOVE_ADS")
	sdk.query_product_details_response.emit({"response_code": 0, "product_details": [_detail("com.example.game.remove_ads", [{"purchase_option_id": "one", "offer_id": null}, {"purchase_option_id": "two", "offer_id": null}])]})
	test.check(events.back()[2] == "purchase_options_required", "Ambiguous offers never pick an arbitrary price")
	service.query_products()
	sdk.query_product_details_response.emit({"response_code": 0, "product_details": [_detail("com.example.game.remove_ads")]})
	test.check(sdk.calls.back()[2] == "subs", "Product query includes subscription catalog")
	sdk.query_product_details_response.emit({"response_code": 0, "product_details": []})
	test.check(events.back()[0] == "products" and not service.busy, "Product details reach public service")
	service.restore_purchases()
	sdk.query_purchases_response.emit({"response_code": 0, "purchases": [_transaction("com.example.game.remove_ads", "restored")]})
	test.check(sdk.calls.back() == ["restore", "subs", false], "Restore queries both product types excluding suspended subscriptions")
	sdk.query_purchases_response.emit({"response_code": 0, "purchases": []})
	test.check(events.back()[0] == "received" and not events.back()[2].verified, "Restore re-enters verification instead of granting")
	service.purchase("REMOVE_ADS")
	adapter._timeout()
	test.check(events.back()[2] == "timeout", "Missing billing callback surfaces timeout")
	service.purchase("REMOVE_ADS")
	test.check(events.back()[2] == "busy", "Timeout keeps native lock until old callback")
	count = events.size()
	sdk.query_product_details_response.emit({"response_code": 0, "product_details": [_detail("com.example.game.remove_ads")]})
	test.check(events.size() == count, "Late query does not launch timed-out purchase")
	sdk.billing_ready = false
	service.purchase("REMOVE_ADS")
	test.check(sdk.calls.back() == ["connect"], "Disconnected billing starts a new connection")
	adapter._timeout()
	sdk.billing_ready = true
	sdk.connected.emit()
	test.check(adapter._operation.is_empty(), "Late connection releases timed-out connect without dispatch")
	service.purchase("REMOVE_ADS")
	count = sdk.calls.size()
	sdk.connected.emit()
	test.check(sdk.calls.size() == count, "Unsolicited reconnect cannot duplicate active product query")
	sdk.disconnected.emit()
	test.check(events.back()[2] == "disconnected" and adapter._expired, "Disconnect keeps in-flight callback lock")
	sdk.query_product_details_response.emit({"response_code": 0, "product_details": []})
	service.restore_purchases()
	sdk.query_purchases_response.emit({"response_code": 0, "purchases": [_transaction("com.example.game.remove_ads", "restored")]})
	sdk.query_purchases_response.emit({"response_code": 0, "purchases": []})
	test.check(events.back()[0] == "received" and events.back()[2].purchase_token == "restored", "Restore re-delivers unfinalized transaction for verification retry")
	var before := events.size()
	adapter._notification(NOTIFICATION_APPLICATION_RESUMED)
	test.check(sdk.calls.back() == ["restore", "inapp", false], "Resume syncs purchases silently")
	sdk.query_purchases_response.emit({"response_code": 0, "purchases": []})
	sdk.query_purchases_response.emit({"response_code": 0, "purchases": []})
	var restored := events.slice(before).filter(func(event: Array) -> bool: return event[0] == "restored")
	test.check(restored.is_empty() and adapter._operation.is_empty(), "Resume sync never emits unsolicited restore_completed")
	service.queue_free()

## SDK 복원 응답에서 대기·정지 거래가 구매 원장에 보유 권한으로 기록되는지 검사한다.
func _restore_entitlements(test: Node) -> void:
	var service := BillingService.new()
	test.add_child(service)
	var adapter := BillingHarness.new()
	service.initialize(true, adapter)
	var sdk := adapter.sdk
	# 초기 자동 조회를 마친 뒤 게임이 요청한 복원 응답을 보낸다.
	sdk.query_purchases_response.emit({"response_code": 0, "purchases": []})
	sdk.query_purchases_response.emit({"response_code": 0, "purchases": []})
	var saved_data := SaveManager.data.duplicate(true)
	SaveManager.reset_slot({})
	var ledger := preload("res://examples/purchase_ledger/purchase_ledger.gd").new()
	service.add_child(ledger)
	ledger.attach(service)
	var pending: Array[String] = []
	var restores: Array = []
	service.purchase_pending.connect(func(id: String, _tx: Dictionary): pending.append(id))
	service.restore_completed.connect(func(items: Array): restores.append(items))

	var ads := _transaction("com.example.game.remove_ads", "ads-restore", 2)
	var premium := _transaction("com.example.game.premium", "premium-restore")
	premium.is_suspended = true
	service.restore_purchases()
	sdk.query_purchases_response.emit({"response_code": 0, "purchases": [ads]})
	sdk.query_purchases_response.emit({"response_code": 0, "purchases": [premium]})
	test.check(restores == [[]], "Pending and suspended purchases are excluded from restore results")
	test.check(pending == ["REMOVE_ADS", "PREMIUM"], "Pending and suspended purchases still notify the game")
	test.check(not ledger.owns("REMOVE_ADS") and not ledger.owns("PREMIUM"), "Restore cannot grant pending or suspended entitlements")

	ads.purchase_state = 1
	service.restore_purchases()
	sdk.query_purchases_response.emit({"response_code": 0, "purchases": [ads]})
	sdk.query_purchases_response.emit({"response_code": 0, "purchases": [premium]})
	test.check(restores.size() == 2 and restores[1].size() == 1 and restores[1][0].purchase_token == "ads-restore", "The same token becomes restorable once purchased")
	test.check(ledger.owns("REMOVE_ADS") and not ledger.owns("PREMIUM"), "Only the confirmed entitlement is granted")
	sdk.acknowledge_purchase_response.emit({"response_code": 0, "token": "ads-restore"})
	ads.is_acknowledged = true
	var deliveries: Array[String] = []
	service.transaction_received.connect(func(id: String, _tx: Dictionary): deliveries.append(id))
	service.purchase_completed.connect(func(id: String, _tx: Dictionary): deliveries.append(id))
	ledger.entitlement_changed.connect(func(id: String, _owned: bool): deliveries.append(id))
	service.restore_purchases()
	sdk.query_purchases_response.emit({"response_code": 0, "purchases": [ads]})
	sdk.query_purchases_response.emit({"response_code": 0, "purchases": []})
	test.check(restores.size() == 3 and restores.back().size() == 1 and restores.back()[0].purchase_token == "ads-restore", "A finalized purchase still appears in the store's current inventory")
	test.check(deliveries.is_empty() and service.get_unfinished_transactions().is_empty(), "Restoring a finalized token does not deliver, grant or finish it again")
	service.restore_purchases()
	sdk.query_purchases_response.emit({"response_code": 0, "purchases": []})
	sdk.query_purchases_response.emit({"response_code": 0, "purchases": []})
	test.check(restores.size() == 4 and restores.back().is_empty(), "A finalized token absent from the store is absent from the next restore")
	service.queue_free()
	SaveManager.reset_slot(saved_data)
	SaveManager.save_slot()

## ONE store 플러그인은 Google 결제와 같은 JNI 계약을 쓰되 상품 ID·공개 키·복구 오류가 다르다.
func _onestore(test: Node) -> void:
	test.check(GameConfig.store_product_id("REMOVE_ADS", "onestore") == "remove_ads" and GameConfig.store_product_id("REMOVE_ADS", "app_store") == "com.example.game.removeads", "Store-specific product IDs resolve per store")
	test.check(GameConfig.store_product_id("UNKNOWN", "onestore").is_empty(), "Missing ONE store ID never falls back to Google Play ID")
	var google_only := BillingHarness.new()
	var mismatch := OneStoreBillingAdapter.new()
	test.add_child(mismatch)
	test.add_child(google_only.sdk)
	mismatch._bind_plugin(google_only.sdk)
	test.check(mismatch._plugin == null, "ONE store adapter rejects plugin without setPublicKey contract")
	mismatch.queue_free()
	google_only.sdk.queue_free()
	google_only.free()
	GameConfig.store_override = "onestore"
	GameConfig.config.set_value("billing", "onestore_public_key", "test-public-key")
	var service := BillingService.new()
	test.add_child(service)
	var adapter := OneStoreHarness.new()
	service.initialize(true, adapter)
	var sdk := adapter.sdk
	var local: Array = []
	service.purchase_failed.connect(func(id: String, reason: String): local.append(["failed", id, reason]))
	service.transaction_received.connect(func(id: String, tx: Dictionary): local.append(["received", id, tx]))
	test.check(sdk.calls[0] == ["key", "test-public-key"] and sdk.calls[1] == ["init"], "ONE store public key is set before initPlugin")
	sdk.query_purchases_response.emit({"response_code": 0, "purchases": []})
	sdk.query_purchases_response.emit({"response_code": 0, "purchases": []})
	service.purchase("REMOVE_ADS")
	test.check(sdk.calls.back() == ["details", PackedStringArray(["remove_ads"]), "inapp"], "ONE store purchase uses onestore product ID")
	sdk.query_product_details_response.emit({"response_code": 10, "product_details": []})
	test.check(local.back() == ["failed", "REMOVE_ADS", "store_login_required"] and not service.busy, "ONE store login requirement surfaces recoverable reason")
	service.purchase("REMOVE_ADS")
	sdk.query_product_details_response.emit({"response_code": 0, "product_details": [_detail("remove_ads")]})
	sdk.on_purchase_updated.emit({"response_code": 0, "purchases": [_transaction("remove_ads", "os-token")]})
	test.check(local.back()[0] == "received" and local.back()[2].store_id == "remove_ads" and not local.back()[2].verified, "ONE store purchase enters the same verification step")
	test.check(service.finish_purchase("os-token") == OK and sdk.calls.back() == ["acknowledge", "os-token"], "ONE store non-consumable acknowledges after game confirmation")
	GameConfig.store_override = ""
	GameConfig.config.set_value("billing", "onestore_public_key", "")
	service.queue_free()

func _ads_and_privacy(test: Node) -> void:
	var privacy := PrivacyService.new()
	test.add_child(privacy)
	var consent := PrivacyHarness.new()
	privacy.initialize(true, consent)
	var ads := AdsService.new()
	test.add_child(ads)
	var adapter := AdsHarness.new()
	ads.initialize(true, adapter, privacy)
	ads.rewarded_completed.connect(func(id: String): events.append(["reward", id]))
	ads.rewarded_failed.connect(func(id: String, reason: String): events.append(["reward_failed", id, reason]))
	ads.interstitial_closed.connect(func(id: String): events.append(["closed", id]))
	ads.ad_failed.connect(func(id: String, reason: String): events.append(["ad_failed", id, reason]))
	test.check(adapter.core.initializes == 0 and not ads.is_rewarded_ready(), "Unknown consent never initializes or loads ads")
	privacy.request_consent()
	privacy.request_consent()
	test.check(consent.info.updates == 1, "Concurrent consent request does not duplicate UMP UI")
	consent.info.on_consent_info_updated_success.emit()
	test.check(consent.forms.calls.back() == ["load"], "Required UMP consent loads a form")
	consent.forms.on_consent_form_load_success_listener.emit(5)
	test.check(consent.forms.calls.back() == ["show", 5], "UMP shows matching loaded form")
	consent.info.status = 3
	consent.forms.on_consent_form_dismissed.emit(6, {})
	test.check(not privacy.can_request_ads(), "Unrelated consent form cannot open ad gate")
	consent.forms.on_consent_form_dismissed.emit(5, {})
	test.check(privacy.can_request_ads() and not privacy.can_use_services(), "UMP ad eligibility does not grant analytics consent")
	test.check(adapter.core.initializes == 1 and adapter.rewarded.calls.is_empty(), "Ads initialize once after consent and await callback")
	adapter.core.on_initialization_complete.emit({})
	await test.get_tree().process_frame
	test.check(adapter.rewarded.calls.back()[1] == AndroidAdmobAdapter.TEST_UNITS.rewarded, "Native ad load uses Google's sample test unit")
	var uid: int = adapter._uids.rewarded
	adapter.rewarded.on_rewarded_ad_loaded.emit(uid + 1)
	await test.get_tree().process_frame
	test.check(not ads.is_rewarded_ready(), "Wrong ad UID cannot make current ad ready")
	adapter.rewarded.on_rewarded_ad_loaded.emit(uid)
	await test.get_tree().process_frame
	test.check(ads.is_rewarded_ready(), "Matching loaded native rewarded ad is ready")
	ads.show_rewarded("revive")
	test.check(not ads.is_rewarded_ready() and not ads.is_interstitial_ready(), "Full-screen ads share one display lock")
	var count := events.size()
	adapter.rewarded.on_rewarded_ad_user_earned_reward.emit(uid + 1, {"amount": 1})
	await test.get_tree().process_frame
	test.check(events.size() == count, "Unrelated SDK reward is ignored")
	adapter.rewarded.on_rewarded_ad_user_earned_reward.emit(uid, {"amount": 1})
	adapter.rewarded.on_rewarded_ad_user_earned_reward.emit(uid, {"amount": 1})
	await test.get_tree().process_frame
	test.check(events.size() == count + 1 and events.back() == ["reward", "revive"], "SDK reward is delivered exactly once")
	adapter.rewarded.on_rewarded_ad_dismissed_full_screen_content.emit(uid)
	await test.get_tree().process_frame
	test.check(adapter._active.is_empty() and adapter._uids.rewarded != uid, "Dismissal destroys and reloads one-use rewarded ad")
	uid = adapter._uids.rewarded
	adapter.rewarded.on_rewarded_ad_loaded.emit(uid)
	await test.get_tree().process_frame
	ads.show_rewarded("skipped")
	adapter.rewarded.on_rewarded_ad_dismissed_full_screen_content.emit(uid)
	await test.get_tree().process_frame
	test.check(events.back()[2] == "reward_not_earned", "Closing ad without SDK reward never grants")
	uid = adapter._uids.interstitial
	adapter.interstitial.on_interstitial_ad_loaded.emit(uid)
	await test.get_tree().process_frame
	ads.show_interstitial("break")
	adapter.interstitial.on_interstitial_ad_dismissed_full_screen_content.emit(uid)
	await test.get_tree().process_frame
	test.check(events.back() == ["closed", "break"], "Interstitial only reports matching close callback")
	privacy.show_privacy_options()
	test.check(not ads.is_rewarded_ready() and consent.forms.calls.back() == ["options"], "Privacy options suspend ad eligibility")
	consent.info.status = 2
	consent.forms.on_privacy_options_form_dismissed_listener.emit({})
	test.check(not privacy.can_request_ads() and adapter._uids.rewarded == -1, "Consent withdrawal invalidates loaded ads")
	privacy.request_consent()
	consent.info.on_consent_info_updated_failure.emit({"code": 3})
	test.check(privacy.status == "unavailable" and not privacy.can_request_ads(), "UMP error fails closed")
	privacy.request_consent()
	consent._expired = true
	consent.info.status = 1
	consent.info.on_consent_info_updated_success.emit()
	test.check(not privacy.can_request_ads(), "Expired UMP update cannot reopen ad gate")
	ads.queue_free()
	privacy.queue_free()
