## Google Play Billing 3.3.0을 연결한다. 구매 수신·검증·스토어 완료를 분리하고 게임 보상은 지급하지 않는다.
## 같은 JNI 계약을 따르는 다른 Android 스토어 플러그인은 이 클래스를 상속해 이름·상품 ID·오류만 바꾼다.
class_name AndroidBillingAdapter
extends BillingAdapter

const METHODS := ["initPlugin", "startConnection", "endConnection", "isReady", "queryProductDetails", "queryPurchases", "purchase", "purchaseSubscription", "consumePurchase", "acknowledgePurchase"]
const EVENTS := ["connected", "disconnected", "connect_error", "query_product_details_response", "query_purchases_response", "on_purchase_updated", "consume_purchase_response", "acknowledge_purchase_response"]
var _plugin: Object
var _operation := ""
var _logical_id := ""
var _product: Dictionary = {}
var _stage := ""
var _expired := false
var _timer: Timer
var _catalog: Dictionary = {}
var _items: Array = []
var _deliveries: Array[Dictionary] = []
var _awaiting: Dictionary = {}
var _finalized: Dictionary = {}
var _finishing_token := ""
var _waiting_connection := false

## SDK가 없거나 플랫폼이 다르면 unavailable을 유지한다.
func initialize() -> void:
	var candidate := AndroidPlugin.find_plugin(_plugin_name(), _required_methods(), EVENTS)
	if candidate != null:
		_bind_plugin(candidate)

func _bind_plugin(candidate: Object) -> void:
	if not AndroidPlugin.matches(candidate, _required_methods(), EVENTS):
		return
	_plugin = candidate
	_plugin.connect("connected", _connected)
	_plugin.connect("disconnected", _disconnected)
	_plugin.connect("connect_error", _connect_error)
	_plugin.connect("query_product_details_response", _product_details)
	_plugin.connect("query_purchases_response", _purchases)
	_plugin.connect("on_purchase_updated", _purchase_updated)
	_plugin.connect("consume_purchase_response", _finished)
	_plugin.connect("acknowledge_purchase_response", _finished)
	_timer = Timer.new()
	_timer.one_shot = true
	add_child(_timer)
	_timer.timeout.connect(_timeout)
	for logical_id in GameConfig.products:
		var product: Dictionary = GameConfig.products[logical_id].duplicate(true)
		product["store_id"] = GameConfig.store_product_id(logical_id, _store())
		if not product.store_id.is_empty():
			_catalog[logical_id] = product
	_configure_plugin()
	_plugin.call("initPlugin")
	# 앱이 꺼진 동안 완료된 구매를 3일 자동 환불 전에 다시 수신한다.
	sync_purchases()

## 연결할 JNI singleton 이름이다.
func _plugin_name() -> String:
	return "GodotGooglePlayBilling"

## singleton이 반드시 제공해야 하는 Java 메서드 목록이다.
func _required_methods() -> Array:
	return METHODS

## 상품 ID를 고를 스토어 키다. GameConfig.store_product_id()에 전달한다.
func _store() -> String:
	return "google_play"

## initPlugin 전에 스토어별 공개 설정을 전달한다.
func _configure_plugin() -> void:
	pass

## native 응답 코드를 게임에 전달할 실패 이유로 바꾼다.
func _native_reason(code: Variant) -> String:
	return "native_error:%s" % code

## 상품 상세를 다시 조회해 만료된 가격·offer cache로 결제하지 않는다.
func purchase(product_id: String, product: Dictionary) -> void:
	if not _begin("purchase", product_id):
		return
	_product = product.duplicate(true)
	if _catalog.has(product_id):
		_product["store_id"] = _catalog[product_id].store_id
	_stage = "details"
	_connect_or_dispatch()

## 일회성 상품과 구독 가격·offer를 순차 조회한다.
func query_products() -> void:
	if _begin("products"):
		_items.clear()
		_stage = "inapp"
		_connect_or_dispatch()

## 복원은 구매 상태를 다시 수신한다. 검증·지급을 생략한 구매 성공으로 해석하지 않는다.
func restore_purchases() -> void:
	if _begin("restore"):
		_items.clear()
		_stage = "inapp"
		_connect_or_dispatch()

## 앱 시작·재개 시 미완료 구매를 조용히 다시 수신한다. restore 결과 신호는 보내지 않는다.
## 다른 작업이 진행 중이면 건너뛴다. 수신 결과는 transaction_received/purchase_pending으로만 전달한다.
func sync_purchases() -> void:
	if not is_instance_valid(_plugin) or not _operation.is_empty():
		return
	_operation = "sync"
	_logical_id = ""
	_expired = false
	_start_timer()
	_items.clear()
	_stage = "inapp"
	_connect_or_dispatch()

## 검증·finish를 기다리는 거래 목록이다. 신호 연결 전에 수신된 거래를 게임이 다시 확인할 때 사용한다.
func get_unfinished_transactions() -> Array:
	var result: Array = []
	for transaction in _awaiting.values():
		result.append(transaction.duplicate(true))
	return result

## 게임이 서버 검증·중복 지급 방지·지급 기록 저장을 마친 뒤에만 호출한다.
func finish_purchase(purchase_token: String) -> Error:
	if not _awaiting.has(purchase_token) or _finalized.has(purchase_token):
		return ERR_INVALID_PARAMETER
	if not _operation.is_empty():
		return ERR_BUSY
	if not is_instance_valid(_plugin) or not bool(_plugin.call("isReady")):
		return ERR_UNAVAILABLE
	var transaction: Dictionary = _awaiting[purchase_token]
	_operation = "finish"
	_logical_id = transaction.logical_id
	_finishing_token = purchase_token
	_expired = false
	_start_timer()
	if transaction.type != "consumable" and bool(transaction.get("is_acknowledged", false)):
		_finished({"response_code": 0, "token": purchase_token})
	else:
		_plugin.call("consumePurchase" if transaction.type == "consumable" else "acknowledgePurchase", purchase_token)
	return OK

func _begin(kind: String, product_id: String = "") -> bool:
	if not is_instance_valid(_plugin) or not _operation.is_empty():
		_emit_failure(kind, product_id, "unavailable" if not is_instance_valid(_plugin) else "busy")
		return false
	_operation = kind
	_logical_id = product_id
	_expired = false
	_start_timer()
	return true

func _start_timer() -> void:
	_timer.start(maxf(1.0, float(GameConfig.value("billing", "timeout_seconds", 120.0))))

func _connect_or_dispatch() -> void:
	if bool(_plugin.call("isReady")):
		_dispatch()
	else:
		_waiting_connection = true
		_plugin.call("startConnection")

func _connected() -> void:
	if _waiting_connection:
		if _expired:
			_clear()
			_drain()
		elif not _operation.is_empty():
			_dispatch()

func _dispatch() -> void:
	_waiting_connection = false
	if _operation == "purchase":
		_plugin.call("queryProductDetails", PackedStringArray([str(_product.store_id)]), "subs" if _product.type == "subscription" else "inapp")
	elif _operation in ["restore", "sync"]:
		_plugin.call("queryPurchases", _stage, false)
	elif _operation == "products":
		var ids := PackedStringArray()
		for product in _catalog.values():
			if (product.type == "subscription") == (_stage == "subs"):
				ids.append(str(product.store_id))
		if ids.is_empty():
			_product_details({"response_code": 0, "product_details": []})
		else:
			_plugin.call("queryProductDetails", ids, _stage)

func _product_details(response: Dictionary) -> void:
	if _operation not in ["products", "purchase"] or (_operation == "purchase" and _stage != "details"):
		return
	if _expired:
		_clear()
		_drain()
		return
	if int(response.get("response_code", -1)) != 0:
		_fail(_native_reason(response.get("response_code", -1)))
		return
	var details: Array = response.get("product_details", [])
	if _operation == "products":
		_items.append_array(details)
		if _stage == "inapp":
			_stage = "subs"
			_dispatch()
		else:
			var items := _items.duplicate(true)
			_clear()
			products_updated.emit(items)
			_drain()
		return
	for detail in details:
		if str(detail.get("product_id", "")) == str(_product.store_id):
			_launch(detail)
			return
	_fail("product_unavailable")

func _launch(detail: Dictionary) -> void:
	var subscription: bool = _product.type == "subscription"
	var option_key := "base_plan_id" if subscription else "purchase_option_id"
	var option_id := str(_product.get(option_key, ""))
	var offer_id := str(_product.get("offer_id", ""))
	var candidates: Array = []
	var offers: Variant = detail.get("subscription_offer_details" if subscription else "one_time_purchase_offer_details_list", [])
	if offers is Array:
		for offer in offers:
			if str(offer.get("offer_id") if offer.get("offer_id") != null else "") != offer_id:
				continue
			if option_id.is_empty() or str(offer.get(option_key, "")) == option_id:
				candidates.append(offer)
	# 여러 후보의 첫 항목을 임의로 고르지 않고 게임이 가격·조건을 선택하게 한다.
	if candidates.size() != 1:
		_fail("purchase_options_required")
		return
	option_id = str(candidates[0].get(option_key, ""))
	_stage = "flow"
	var response: Dictionary = _plugin.call("purchaseSubscription" if subscription else "purchase", str(_product.store_id), option_id, offer_id, bool(_product.get("is_offer_personalized", false)))
	var code := int(response.get("response_code", -1))
	if code != 0:
		if code == 1:
			_cancel()
		else:
			_fail(_native_reason(code))

func _purchase_updated(response: Dictionary) -> void:
	var code := int(response.get("response_code", -1))
	if code != 0:
		if _operation == "purchase":
			if code == 1:
				_cancel()
			else:
				_fail(_native_reason(code))
		return
	var matched := false
	for raw in response.get("purchases", []):
		var transaction := _receive(raw)
		if transaction.get("logical_id", "") == _logical_id and not _logical_id.is_empty():
			matched = true
	if _operation == "purchase" and matched:
		_clear()
	_drain()

func _purchases(response: Dictionary) -> void:
	if _operation not in ["restore", "sync"]:
		return
	if _expired:
		_clear()
		_drain()
		return
	if int(response.get("response_code", -1)) != 0:
		_fail(_native_reason(response.get("response_code", -1)))
		return
	for raw in response.get("purchases", []):
		var transaction := _receive(raw, true)
		if not transaction.is_empty() and transaction.type != "consumable":
			_items.append(transaction)
	if _stage == "inapp":
		_stage = "subs"
		_dispatch()
	else:
		var items := _items.duplicate(true)
		var silent := _operation == "sync"
		_clear()
		if not silent:
			restore_completed.emit(items)
		_drain()

func _receive(raw: Dictionary, replay: bool = false) -> Dictionary:
	var token := str(raw.get("purchase_token", ""))
	var ids: Variant = raw.get("product_ids", [])
	if token.is_empty() or _finalized.has(token) or not (ids is Array or ids is PackedStringArray) or ids.size() != 1:
		return {}
	for logical_id in _catalog:
		var product: Dictionary = _catalog[logical_id]
		if str(product.store_id) != str(ids[0]):
			continue
		var state := int(raw.get("purchase_state", 0))
		if state not in [1, 2]:
			return {}
		var transaction := raw.duplicate(true)
		transaction.merge({"logical_id": logical_id, "store_id": product.store_id, "type": product.type, "verified": false, "mock": false}, true)
		if state == 1 and not bool(raw.get("is_suspended", false)):
			if _awaiting.has(token):
				if replay:
					_deliveries.append(transaction)
				return transaction
			_awaiting[token] = transaction
		_deliveries.append(transaction)
		return transaction
	return {}

func _drain() -> void:
	while _operation.is_empty() and not _deliveries.is_empty():
		var transaction: Dictionary = _deliveries.pop_front()
		if int(transaction.purchase_state) == 2 or bool(transaction.get("is_suspended", false)):
			purchase_pending.emit(str(transaction.logical_id), transaction.duplicate(true))
		else:
			transaction_received.emit(str(transaction.logical_id), transaction.duplicate(true))

func _finished(response: Dictionary) -> void:
	var token := str(response.get("token", ""))
	if _operation != "finish" or token != _finishing_token:
		return
	if int(response.get("response_code", -1)) != 0:
		_fail("finish_failed:%s" % response.get("response_code", -1))
		return
	var transaction: Dictionary = _awaiting[token].duplicate(true)
	transaction["verified"] = true
	transaction["finished"] = true
	_finalized[token] = true
	_awaiting.erase(token)
	var expired := _expired
	_clear()
	if not expired:
		purchase_completed.emit(str(transaction.logical_id), transaction)
	_drain()

func _cancel() -> void:
	var logical_id := _logical_id
	var expired := _expired
	_clear()
	if not expired:
		purchase_cancelled.emit(logical_id)
	_drain()

func _fail(reason: String) -> void:
	var kind := _operation
	var logical_id := _logical_id
	var expired := _expired
	_clear()
	if not expired:
		_emit_failure(kind, logical_id, reason)
	_drain()

func _emit_failure(kind: String, logical_id: String, reason: String) -> void:
	match kind:
		"sync": AppLogger.info("AndroidBilling", "Purchase sync skipped: " + reason)
		"restore": restore_failed.emit(reason)
		"products": products_failed.emit(reason)
		_: purchase_failed.emit(logical_id, reason)

func _clear() -> void:
	_timer.stop()
	_operation = ""
	_logical_id = ""
	_finishing_token = ""
	_expired = false
	_waiting_connection = false

func _timeout() -> void:
	# SDK 응답에 요청 ID가 없으므로 늦은 응답이 올 때까지 잠금을 보존한다.
	_expired = true
	_emit_failure(_operation, _logical_id, "timeout")

func _disconnected() -> void:
	if not _operation.is_empty():
		if _waiting_connection:
			_fail("disconnected")
		elif not _expired:
			# 이전 native 응답이 새 요청으로 오인되지 않게 잠금을 보존한다.
			_expired = true
			_timer.stop()
			_emit_failure(_operation, _logical_id, "disconnected")

func _connect_error(code: int, _message: String) -> void:
	if not _operation.is_empty():
		_fail("connection_failed:%s" % code)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED and is_instance_valid(_plugin) and _operation.is_empty():
		sync_purchases()

func _exit_tree() -> void:
	if is_instance_valid(_plugin):
		_plugin.call("endConnection")
