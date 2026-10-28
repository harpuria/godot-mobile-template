## 스토어 구매와 복원 구현 계약이다. 검증되지 않은 구매를 성공으로 처리하지 않는다.
class_name BillingAdapter
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

## 활성 서비스만 SDK 초기화를 요청한다.
func initialize() -> void:
	pass

## 스토어의 현재 상품·가격·구매 옵션을 조회한다.
func query_products() -> void:
	products_failed.emit("unavailable")

## 게임이 서버 검증과 지급 기록 저장을 마친 거래만 acknowledge/consume한다.
func finish_purchase(_purchase_token: String) -> Error:
	return ERR_UNAVAILABLE

## logical ID와 플랫폼별 Store ID가 분리된 상품 정보를 받는다.
func purchase(product_id: String, _product: Dictionary) -> void:
	purchase_failed.emit(product_id, "unavailable")

func restore_purchases() -> void:
	restore_failed.emit("unavailable")
