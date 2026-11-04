# Purchase ledger 예제

서버 검증 없이 출시하는 소규모 게임을 위한 구매 처리 레퍼런스다. `examples/`는 export에서 제외되며 `tests/purchase_ledger_checks.gd`가 동작을 검사한다.

## 쓰는 법

1. `purchase_ledger.gd`를 `game/` 아래로 복사한다. 예: `game/purchase_ledger.gd`.
2. `CURRENCY`와 `_grant()`를 게임의 상품 규칙에 맞게 고친다.
3. 게임 첫 장면에서 `App.initialize()` 이후 붙인다.

```gdscript
var ledger := preload("res://game/purchase_ledger.gd").new()

func _ready() -> void:
	add_child(ledger)
	ledger.entitlement_changed.connect(func(id: String, owned: bool): print(id, owned))
	ledger.attach(App.billing)
	if ledger.owns("REMOVE_ADS"):
		pass # 광고 숨김
```

## 보장하는 것

- `purchase_token`(native) 또는 `transaction_id`(Mock) 기준으로 한 번만 지급한다.
- 지급 기록을 `SaveManager`에 **즉시 저장**한 뒤에만 `finish_purchase()`를 호출한다. 저장에 실패하면 메모리 기록을 되돌리고 finish하지 않는다. 다음 sync·restore에서 다시 처리한다.
- 신호 연결 전에 수신된 거래(`get_unfinished_transactions()`)도 처리한다.
- 복원은 비소모성·구독 보유 표시만 갱신하고 재화를 다시 주지 않는다.

## 보장하지 않는 것

- 로컬 저장은 기기 변조를 막지 못한다. 유료 재화가 중요하면 `_on_transaction_received()`에서 서버로 token을 보내 Google Play Developer API 또는 ONE store 서버 API로 검증한 뒤 finish한다.
- 구독 만료·환불 처리. 서버 알림(RTDN 등)이 필요하다.
- 기기 변경 시 소모성 재화 이전. 클라우드 저장 또는 계정 시스템이 필요하다.
