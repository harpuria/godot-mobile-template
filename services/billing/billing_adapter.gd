## 스토어 구매와 복원 구현 계약이다. 검증되지 않은 구매를 성공으로 처리하지 않는다.
class_name BillingAdapter
extends Node

signal purchase_completed(product_id: String, transaction: Dictionary)
signal purchase_cancelled(product_id: String)
signal purchase_failed(product_id: String, reason: String)
signal restore_completed(transactions: Array)
signal restore_failed(reason: String)

## logical ID와 플랫폼별 Store ID가 분리된 상품 정보를 받는다.
func purchase(product_id: String, _product: Dictionary) -> void:
	purchase_failed.emit(product_id, "unavailable")

func restore_purchases() -> void:
	restore_failed.emit("unavailable")
