## logical 상품 ID, 중복 요청 방지, 구매/복원 결과를 게임 계층에 제공한다.
class_name BillingService
extends Node

signal purchase_completed(product_id: String, transaction: Dictionary)
signal purchase_cancelled(product_id: String)
signal purchase_failed(product_id: String, reason: String)
signal restore_completed(transactions: Array)
signal restore_failed(reason: String)
signal products_updated(products: Array)
signal products_failed(reason: String)
signal purchase_pending(product_id: String, transaction: Dictionary)
signal transaction_received(product_id: String, transaction: Dictionary)
var adapter: BillingAdapter
var enabled := false
var busy := false

## 기능 활성화 값과 adapter를 연결하고 결과 신호를 서비스에 전달한다.
func initialize(active: bool, implementation: BillingAdapter) -> void:
	enabled = active
	adapter = implementation
	add_child(adapter)
	adapter.purchase_completed.connect(_completed)
	adapter.purchase_cancelled.connect(_cancelled)
	adapter.purchase_failed.connect(_failed)
	adapter.restore_completed.connect(func(transactions: Array):
		busy = false
		restore_completed.emit(transactions))
	adapter.restore_failed.connect(func(reason: String):
		busy = false
		restore_failed.emit(reason))
	adapter.products_updated.connect(func(items: Array):
		busy = false
		products_updated.emit(items))
	adapter.products_failed.connect(func(reason: String):
		busy = false
		products_failed.emit(reason))
	adapter.purchase_pending.connect(func(id: String, transaction: Dictionary):
		busy = false
		purchase_pending.emit(id, transaction))
	adapter.transaction_received.connect(func(id: String, transaction: Dictionary):
		busy = false
		transaction_received.emit(id, transaction))
	if enabled:
		adapter.initialize()

## 플랫폼 Store ID와 상품 타입을 검증한 다음 adapter로 요청을 전달한다.
func purchase(product_id: String, options: Dictionary = {}) -> void:
	if not enabled or busy:
		purchase_failed.emit(product_id, "busy" if busy else "disabled")
		return
	var product: Dictionary = GameConfig.products.get(product_id, {}).duplicate(true)
	if product.is_empty() or product.get("type", "") not in ["consumable", "non_consumable", "subscription"]:
		purchase_failed.emit(product_id, "invalid_product")
		return
	product["store"] = GameConfig.store()
	product["store_id"] = GameConfig.store_product_id(product_id)
	if str(product.store_id).is_empty():
		purchase_failed.emit(product_id, "missing_store_id")
		return
	for key in ["purchase_option_id", "base_plan_id", "offer_id", "is_offer_personalized"]:
		if options.has(key):
			product[key] = options[key]
	busy = true
	adapter.purchase(product_id, product)

## 가격·구매 옵션은 SDK 조회 결과를 사용한다.
func query_products() -> void:
	if not enabled or busy:
		products_failed.emit("busy" if busy else "disabled")
		return
	busy = true
	adapter.query_products()

## transaction_received를 검증하고 지급 기록을 저장한 뒤 호출한다. 자동 검증·지급은 하지 않는다.
func finish_purchase(purchase_token: String) -> Error:
	if not enabled:
		return ERR_UNAVAILABLE
	return adapter.finish_purchase(purchase_token)

## 신호 연결 전에 수신된 미검증 거래를 포함해 finish 대기 거래를 반환한다.
## 게임은 시작 시 transaction_received를 연결한 뒤 이 목록도 같은 검증 경로로 처리한다.
func get_unfinished_transactions() -> Array:
	return adapter.get_unfinished_transactions() if enabled else []

## 구매와 복원 작업은 한 번에 하나만 허용한다.
func restore_purchases() -> void:
	if not enabled or busy:
		restore_failed.emit("busy" if busy else "disabled")
		return
	busy = true
	adapter.restore_purchases()

## 다음 Mock 요청에 적용할 개발용 결과를 지정한다.
func set_mock_result(result: String) -> void:
	if adapter is MockBillingAdapter:
		adapter.set_next_result(result)

func _completed(product_id: String, transaction: Dictionary) -> void:
	busy = false
	purchase_completed.emit(product_id, transaction)

func _cancelled(product_id: String) -> void:
	busy = false
	purchase_cancelled.emit(product_id)

func _failed(product_id: String, reason: String) -> void:
	busy = false
	purchase_failed.emit(product_id, reason)
