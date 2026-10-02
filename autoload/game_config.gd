## 게임별 공개 설정과 기능 플래그를 읽는다. 비밀 키를 보관하지 않는다.
extends Node

const ENGINE_VERSION = "4.7.2"
const TEMPLATE_VERSION = "0.2.0"
var config := ConfigFile.new()
var products: Dictionary = {}

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
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://config/products.json"))
	if parsed is Dictionary:
		products = parsed

## 설정 키가 없으면 호출자가 지정한 기본값을 반환한다.
func value(section: String, key: String, fallback: Variant = null) -> Variant:
	return config.get_value(section, key, fallback)

## 기능 플래그를 조회한다. 정의하지 않은 기능은 비활성화한다.
func enabled(feature: String) -> bool:
	return bool(value("features", feature + "_enabled", false))

## 배포 빌드에서는 Mock 서비스 사용을 허용하지 않는다.
func use_mocks() -> bool:
	if not OS.is_debug_build() or value("services", "mode", "native") != "mock":
		return false
	return not MobilePlatform.is_mobile() or bool(value("services", "allow_mobile_debug_mocks", false))
