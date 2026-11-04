## 서버 검증이 없는 소규모 게임을 위한 구매 처리 레퍼런스다. game/로 복사해 게임 규칙에 맞게 고친다.
## 흐름: transaction_received → token 기준 중복 확인 → 지급·기록 저장 성공 → finish_purchase().
## 로컬 기록은 변조를 막지 못한다. 유료 재화가 중요하면 서버에서 purchase token을 검증한 뒤 finish한다.
extends Node

## 지급 결과를 UI에 알린다. owned는 비소모성·구독 보유 여부다.
signal entitlement_changed(logical_id: String, owned: bool)
signal currency_granted(logical_id: String, amount: int)

const SAVE_KEY := "purchase_ledger"
## 게임 규칙 예시. logical 상품 ID → 소모성 재화 수량. 비소모성·구독은 보유 표시만 한다.
const CURRENCY := {"COIN_SMALL": 100, "COIN_LARGE": 1200}

var billing: BillingService

## App.initialize() 이후 한 번 호출한다. 신호 연결 전에 수신된 미완료 거래도 같은 경로로 처리한다.
func attach(service: BillingService) -> void:
	billing = service
	billing.transaction_received.connect(_on_transaction_received)
	billing.purchase_completed.connect(_on_purchase_completed)
	billing.restore_completed.connect(_on_restore_completed)
	for transaction in billing.get_unfinished_transactions():
		_on_transaction_received(str(transaction.get("logical_id", "")), transaction)

## 비소모성 상품(예: REMOVE_ADS)이나 구독을 보유했는지 반환한다.
func owns(logical_id: String) -> bool:
	return _ledger().owned.has(logical_id)

## 미검증 native 거래를 한 번만 지급하고 저장이 끝난 뒤 스토어 완료를 요청한다.
func _on_transaction_received(logical_id: String, transaction: Dictionary) -> void:
	var token := _token(transaction)
	if token.is_empty():
		return
	if not _ledger().granted.has(token):
		# 서버 검증을 쓴다면 여기서 token·product·package를 서버에 보내 확인한다.
		if _grant(logical_id, transaction, token) != OK:
			# 기록이 저장되지 않았으면 finish하지 않는다. 다음 sync/restore에서 다시 수신된다.
			return
	billing.finish_purchase(token)

## Mock은 transaction_received 없이 바로 완료되므로 같은 지급 규칙을 적용한다.
## native 완료는 이미 지급·기록한 token이므로 보유 상태만 확인한다.
func _on_purchase_completed(logical_id: String, transaction: Dictionary) -> void:
	var token := _token(transaction)
	if not token.is_empty() and not _ledger().granted.has(token):
		_grant(logical_id, transaction, token)

## 복원 목록은 비소모성·구독만 포함한다. 재화는 다시 지급하지 않는다.
func _on_restore_completed(transactions: Array) -> void:
	var ledger := _ledger().duplicate(true)
	var changed: Array[String] = []
	for transaction in transactions:
		var logical_id := str(transaction.get("logical_id", transaction.get("product_id", "")))
		if not logical_id.is_empty() and not ledger.owned.has(logical_id):
			ledger.owned[logical_id] = true
			changed.append(logical_id)
	if changed.is_empty() or _store(ledger) != OK:
		return
	for logical_id in changed:
		entitlement_changed.emit(logical_id, true)

## 사본에 지급을 기록하고 저장에 성공했을 때만 메모리 상태로 확정한다.
func _grant(logical_id: String, transaction: Dictionary, token: String) -> Error:
	var ledger := _ledger().duplicate(true)
	var amount := int(CURRENCY.get(logical_id, 0))
	var type := str(transaction.get("type", ""))
	if type == "consumable":
		ledger["currency"] = int(ledger.get("currency", 0)) + amount
	else:
		ledger.owned[logical_id] = true
	ledger.granted[token] = {"product": logical_id, "time": int(Time.get_unix_time_from_system())}
	var error := _store(ledger)
	if error != OK:
		return error
	if type == "consumable":
		currency_granted.emit(logical_id, amount)
	else:
		entitlement_changed.emit(logical_id, true)
	return OK

## 구매 기록은 즉시 저장한다. 자동 저장 주기를 기다리면 앱 종료 시 중복 지급이나 누락이 생길 수 있다.
## 저장에 실패하면 이전 기록으로 되돌려 다음 재수신 때 다시 지급·저장을 시도한다.
func _store(ledger: Dictionary) -> Error:
	var previous: Variant = SaveManager.data.get(SAVE_KEY)
	SaveManager.set_value(SAVE_KEY, ledger)
	var error := SaveManager.save_slot()
	if error != OK:
		if previous == null:
			SaveManager.data.erase(SAVE_KEY)
		else:
			SaveManager.data[SAVE_KEY] = previous
	return error

func _ledger() -> Dictionary:
	var ledger: Dictionary = SaveManager.data.get(SAVE_KEY, {})
	for key in ["granted", "owned"]:
		if not ledger.get(key) is Dictionary:
			ledger[key] = {}
	return ledger

## native는 purchase_token, Mock은 transaction_id가 중복 지급 기준이다.
func _token(transaction: Dictionary) -> String:
	return str(transaction.get("purchase_token", transaction.get("transaction_id", "")))
