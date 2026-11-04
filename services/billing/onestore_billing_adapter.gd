## ONE store IAP SDK v21을 GodotOneStoreIap 플러그인으로 연결한다.
## 플러그인은 GodotGooglePlayBilling 3.3.0과 같은 JNI 계약을 제공하므로 수신·검증·완료 흐름을 그대로 재사용한다.
class_name OneStoreBillingAdapter
extends AndroidBillingAdapter

const ONESTORE_METHODS := ["setPublicKey"]
## ONE store PurchaseClient.ResponseCode 중 게임이 안내를 바꿔야 하는 코드.
const RECOVERY_REASONS := {10: "store_login_required", 11: "store_update_required", 13: "store_blocked_app", 14: "store_sandbox_unsupported"}

func _plugin_name() -> String:
	return "GodotOneStoreIap"

func _required_methods() -> Array:
	return METHODS + ONESTORE_METHODS

func _store() -> String:
	return "onestore"

## ONE store 개발자 센터의 라이선스 공개 키를 SDK 서명 검증에 전달한다. 비어 있으면 생략한다.
func _configure_plugin() -> void:
	var key := str(GameConfig.value("billing", "onestore_public_key", ""))
	if not key.is_empty():
		_plugin.call("setPublicKey", key)

## 로그인·업데이트 필요는 플러그인이 ONE store 화면을 띄운 뒤 실패로 알린다. 게임은 재시도를 안내한다.
func _native_reason(code: Variant) -> String:
	return RECOVERY_REASONS.get(int(code), "native_error:%s" % code)
