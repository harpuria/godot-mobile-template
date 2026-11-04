## examples/purchase_ledger의 중복 지급 방지·저장 후 finish 순서를 가짜 결제 어댑터로 검사한다.
extends Node

class FakeBilling extends BillingAdapter:
	var finished: Array[String] = []
	var unfinished: Array = []
	func finish_purchase(token: String) -> Error:
		finished.append(token)
		return OK
	func get_unfinished_transactions() -> Array:
		return unfinished

func run(test: Node) -> void:
	var saved_data := SaveManager.data.duplicate(true)
	SaveManager.reset_slot({})
	var service := BillingService.new()
	test.add_child(service)
	var adapter := FakeBilling.new()
	adapter.unfinished = [{"logical_id": "COIN_SMALL", "purchase_token": "late", "type": "consumable"}]
	service.initialize(true, adapter)
	var ledger: Node = preload("res://examples/purchase_ledger/purchase_ledger.gd").new()
	test.add_child(ledger)
	var granted: Array = []
	ledger.currency_granted.connect(func(id: String, amount: int): granted.append([id, amount]))
	ledger.attach(service)
	test.check(granted == [["COIN_SMALL", 100]] and adapter.finished == ["late"], "Ledger processes transactions received before it connected")
	adapter.transaction_received.emit("COIN_SMALL", {"logical_id": "COIN_SMALL", "purchase_token": "late", "type": "consumable"})
	test.check(granted.size() == 1 and adapter.finished == ["late", "late"], "Redelivered token is finished again without a second grant")
	adapter.transaction_received.emit("REMOVE_ADS", {"logical_id": "REMOVE_ADS", "purchase_token": "ads", "type": "non_consumable"})
	test.check(ledger.owns("REMOVE_ADS") and adapter.finished.back() == "ads", "Non-consumable is owned before finish")
	var stored := JsonStore.read(SaveManager.storage_path)
	test.check(stored.error == OK and stored.document.data.purchase_ledger.granted.has("ads"), "Ledger record is saved before finish")
	SaveManager.write_blocked = true
	adapter.transaction_received.emit("COIN_LARGE", {"logical_id": "COIN_LARGE", "purchase_token": "blocked", "type": "consumable"})
	test.check(not adapter.finished.has("blocked") and granted.size() == 1, "Unsaved grant never reaches finish_purchase")
	SaveManager.write_blocked = false
	adapter.transaction_received.emit("COIN_LARGE", {"logical_id": "COIN_LARGE", "purchase_token": "blocked", "type": "consumable"})
	test.check(adapter.finished.back() == "blocked" and granted.back() == ["COIN_LARGE", 1200] and int(SaveManager.data.purchase_ledger.currency) == 1300, "Failed save is rolled back and retried on redelivery")
	adapter.purchase_completed.emit("COIN_LARGE", {"transaction_id": "mock-1", "product_id": "COIN_LARGE", "type": "consumable", "mock": true})
	adapter.purchase_completed.emit("COIN_LARGE", {"transaction_id": "mock-1", "product_id": "COIN_LARGE", "type": "consumable", "mock": true})
	test.check(granted.size() == 3 and int(SaveManager.data.purchase_ledger.currency) == 2500, "Mock completion grants once per transaction_id")
	adapter.restore_completed.emit([{"logical_id": "PREMIUM", "type": "subscription"}])
	test.check(ledger.owns("PREMIUM"), "Restore marks subscription ownership without currency")
	ledger.queue_free()
	service.queue_free()
	SaveManager.reset_slot(saved_data)
	SaveManager.save_slot()
