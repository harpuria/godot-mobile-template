## success/cancel/error 및 현재 실행 세션의 비소모성 구매 복원을 제공한다.
class_name MockBillingAdapter
extends BillingAdapter

var next_result := "success"
var owned: Dictionary = {}
var sequence := 0

## 다음 구매에 적용할 결과를 지정한다. 이후에는 success로 돌아간다.
func set_next_result(result: String) -> void:
	next_result = result if result in ["success", "cancel", "error"] else "error"

func purchase(product_id: String, product: Dictionary) -> void:
	var result := next_result
	next_result = "success"
	AppLogger.info("MockBilling", "Purchase: %s (%s)" % [product_id, result])
	await get_tree().create_timer(0.2).timeout
	match result:
		"cancel": purchase_cancelled.emit(product_id)
		"error": purchase_failed.emit(product_id, "mock_error")
		_:
			sequence += 1
			var transaction := {"transaction_id": "mock-%s-%s" % [Time.get_ticks_usec(), sequence],
				"product_id": product_id, "store_id": product.store_id, "type": product.type, "mock": true}
			if product.type != "consumable":
				if owned.has(product_id):
					transaction = owned[product_id].duplicate(true)
				else:
					owned[product_id] = transaction.duplicate(true)
			purchase_completed.emit(product_id, transaction)

## 소모성 상품은 복원하지 않는다. 구독 갱신/만료는 이 Mock의 범위 밖이다.
func restore_purchases() -> void:
	await get_tree().create_timer(0.2).timeout
	restore_completed.emit(owned.values().duplicate(true))
