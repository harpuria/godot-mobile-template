## 게임별 공개 설정과 기능 플래그를 읽는다. 비밀 키를 보관하지 않는다.
extends Node

const ENGINE_VERSION = "4.7.2"
const TEMPLATE_VERSION = "0.5.0"
var config := ConfigFile.new()
var products: Dictionary = {}
## 테스트 전용 스토어 지정. 비어 있으면 플랫폼과 export feature로 판단한다.
var store_override := ""

func _ready() -> void:
	var error := config.load("res://config/game.cfg")
	if error != OK:
		push_error("Configuration load failed: %s" % error)
	# Android exporter가 허용한 게임 서비스 로컬 설정만 빌드에 주입한다.
	var build_config := ConfigFile.new()
	if build_config.load("res://config/game_services.build.cfg") == OK and build_config.has_section("game_services"):
		for key in build_config.get_section_keys("game_services"):
			if key in ["android_game_id", "android_mode", "android_native_verified", "leaderboard_ids", "achievement_ids"]:
				config.set_value("game_services", key, build_config.get_value("game_services", key))
	var android_config := ConfigFile.new()
	if android_config.load("res://config/android_services.build.cfg") == OK:
		var allowed := {
			"billing": ["android_mode", "android_native_verified", "timeout_seconds", "android_product_ids", "onestore_product_ids", "onestore_public_key"],
			"ads": ["android_mode", "android_native_verified", "use_test_ads", "android_app_id", "rewarded_unit_id", "interstitial_unit_id", "test_device_ids", "retry_seconds"],
			"privacy": ["tag_for_under_age_of_consent"],
		}
		for section in allowed:
			for key in allowed[section]:
				if android_config.has_section_key(section, key):
					config.set_value(section, key, android_config.get_value(section, key))
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://config/products.json"))
	if parsed is Dictionary:
		products = parsed

## 설정 키가 없으면 호출자가 지정한 기본값을 반환한다.
func value(section: String, key: String, fallback: Variant = null) -> Variant:
	return config.get_value(section, key, fallback)

## 기능 플래그를 조회한다. 정의하지 않은 기능은 비활성화한다.
func enabled(feature: String) -> bool:
	return bool(value("features", feature + "_enabled", false))

## 현재 빌드의 배포 스토어(google_play, onestore, app_store)를 반환한다.
## Android 스토어는 export preset의 custom feature `onestore`로 구분한다.
func store() -> String:
	if not store_override.is_empty():
		return store_override
	if MobilePlatform.current() == "iOS":
		return "app_store"
	return "onestore" if OS.has_feature("onestore") else "google_play"

## logical 상품의 스토어별 ID를 반환한다. 로컬 override가 products.json보다 우선한다.
## ONE store는 `onestore` 키가 없으면 Google Play ID로 대체하지 않고 빈 값을 반환한다.
func store_product_id(logical_id: String, target_store: String = "") -> String:
	var selected := store() if target_store.is_empty() else target_store
	var product: Dictionary = products.get(logical_id, {})
	match selected:
		"app_store":
			return str(product.get("ios", ""))
		"onestore":
			var onestore: Dictionary = value("billing", "onestore_product_ids", {})
			return str(onestore.get(logical_id, product.get("onestore", "")))
	var android: Dictionary = value("billing", "android_product_ids", {})
	return str(android.get(logical_id, product.get("android", "")))

## 배포 빌드에서는 Mock 서비스 사용을 허용하지 않는다.
func use_mocks() -> bool:
	if not OS.is_debug_build() or value("services", "mode", "native") != "mock":
		return false
	return not MobilePlatform.is_mobile() or bool(value("services", "allow_mobile_debug_mocks", false))
