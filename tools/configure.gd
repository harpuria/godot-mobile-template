## 공개 config를 Godot 프로젝트 및 export preset에 동기화하는 개발 도구이다.
## 개발용 Android/iOS preset과 스토어 배포 preset(Google Play AAB, ONE store APK)을 함께 관리한다.
extends SceneTree

const DEMO_SCENE := "res://scenes/main.tscn"
const PRESETS_PATH := "res://export_presets.cfg"
const BASE_EXCLUDE := "tests/*,game/tests/*,tools/*,docs/*,examples/*,native/*,addons/godot_ai/*,*.md,config/*.local.*"
## 게임 main_scene이 데모가 아니면 배포 preset에서 데모·진단 장면과 음원을 제외한다.
const RELEASE_EXCLUDE := "scenes/main.tscn,scenes/demo.gd,scenes/transition_demo.*,scenes/android_services_probe.*,scenes/android_game_services_probe.*,assets/demo/*"
const INCLUDE := "config/game.cfg,config/products.json"
## 스토어 preset 이름 → 배포 설정. 이름이 preset 식별자이므로 바꾸지 않는다.
const STORE_PRESETS := {
	"Android Google Play": {"store": "google_play", "export_format": 1, "export_path": "build/android/game-google-play.aab"},
	"Android ONE store": {"store": "onestore", "export_format": 0, "export_path": "build/android/game-onestore.apk"},
}

var _config := ConfigFile.new()

func _initialize() -> void:
	if _config.load("res://config/game.cfg") != OK:
		push_error("Cannot load config/game.cfg")
		quit(1)
		return
	var orientations := {"landscape": 0, "portrait": 1, "sensor_landscape": 4, "sensor_portrait": 5, "sensor": 6}
	var orientation := str(_config.get_value("app", "orientation", "sensor"))
	if not orientations.has(orientation):
		push_error("Invalid orientation: " + orientation)
		quit(1)
		return
	var build_number := int(_config.get_value("app", "build_number", 1))
	if build_number < 1:
		push_error("app/build_number must be a positive integer")
		quit(1)
		return
	var presets := ConfigFile.new()
	var error := presets.load(PRESETS_PATH)
	if error != OK and error != ERR_FILE_NOT_FOUND:
		push_error("Cannot load %s: %s" % [PRESETS_PATH, error_string(error)])
		quit(1)
		return
	var managed := _managed_sections(presets)
	if managed.is_empty():
		quit(1)
		return
	ProjectSettings.set_setting("application/config/name", _config.get_value("app", "name"))
	ProjectSettings.set_setting("application/config/version", _config.get_value("app", "version"))
	ProjectSettings.set_setting("display/window/handheld/orientation", orientations[orientation])
	if ProjectSettings.save() != OK:
		push_error("Cannot save project.godot")
		quit(1)
		return
	_ensure_base(presets, managed["Android"], "Android", "build/android/mobile-template.apk")
	_ensure_base(presets, managed["iOS"], "iOS", "build/ios/mobile-template.zip")
	for preset_name in STORE_PRESETS:
		if not presets.has_section(managed[preset_name]):
			_add_store(presets, preset_name, managed[preset_name], managed["Android"])
	var release_exclude := BASE_EXCLUDE
	var main_scene := str(_config.get_value("app", "main_scene", DEMO_SCENE))
	if main_scene != DEMO_SCENE:
		release_exclude += "," + RELEASE_EXCLUDE
	else:
		print("main_scene is the template demo; store presets keep demo files.")
	for section in _preset_sections(presets):
		var preset_name := str(presets.get_value(section, "name", ""))
		var options := section + ".options"
		# 진단 preset은 별도 package와 feature를 쓰므로 사용자 설정을 그대로 둔다.
		if "probe" in str(presets.get_value(section, "custom_features", "")):
			continue
		match str(presets.get_value(section, "platform", "")):
			"Android":
				presets.set_value(options, "package/unique_name", _config.get_value("app", "android_package"))
				presets.set_value(options, "package/name", _config.get_value("app", "name"))
				presets.set_value(options, "version/name", _config.get_value("app", "version"))
				presets.set_value(options, "version/code", build_number)
				presets.set_value(options, "permissions/vibrate", true)
				if STORE_PRESETS.has(preset_name):
					_apply_store(presets, section, STORE_PRESETS[preset_name], release_exclude)
			"iOS":
				presets.set_value(options, "application/bundle_identifier", _config.get_value("app", "ios_bundle"))
				presets.set_value(options, "application/short_version", _config.get_value("app", "version"))
				presets.set_value(options, "application/version", str(build_number))
				presets.set_value(section, "exclude_filter", release_exclude)
	error = presets.save(PRESETS_PATH)
	if error != OK:
		push_error("Cannot save %s: %s" % [PRESETS_PATH, error_string(error)])
		quit(1)
		return
	print("Configuration synchronized: %s, build %s" % [orientation, build_number])
	quit(0)

## 옵션이나 메타데이터를 제외한 preset.N 섹션을 반환한다.
func _preset_sections(presets: ConfigFile) -> Array[String]:
	var result: Array[String] = []
	for section in presets.get_sections():
		if section.begins_with("preset.") and section.trim_prefix("preset.").is_valid_int():
			result.append(section)
	return result

## 이름과 플랫폼이 일치하는 기존 섹션을 유지하고, 누락된 preset에만 빈 번호를 배정한다.
func _managed_sections(presets: ConfigFile) -> Dictionary:
	var names := ["Android", "iOS"] + STORE_PRESETS.keys()
	var managed := {}
	for section in _preset_sections(presets):
		var preset_name := str(presets.get_value(section, "name", ""))
		if preset_name not in names:
			continue
		var platform := "iOS" if preset_name == "iOS" else "Android"
		var is_probe := "probe" in str(presets.get_value(section, "custom_features", ""))
		if managed.has(preset_name) or is_probe or presets.get_value(section, "platform", "") != platform:
			push_error("Conflicting export preset '%s' in [%s]. Expected one non-probe %s preset." % [preset_name, section, platform])
			return {}
		managed[preset_name] = section
	var index := 0
	for preset_name in names:
		if managed.has(preset_name):
			continue
		while presets.has_section("preset.%d" % index) or presets.has_section("preset.%d.options" % index):
			index += 1
		managed[preset_name] = "preset.%d" % index
		index += 1
	return managed

## 개발용 기본 preset의 이름·경로·필터를 고정한다. signing·Gradle 선택은 유지한다.
func _ensure_base(presets: ConfigFile, section: String, platform: String, path: String) -> void:
	presets.set_value(section, "name", platform)
	presets.set_value(section, "platform", platform)
	presets.set_value(section, "runnable", true)
	presets.set_value(section, "export_filter", "all_resources")
	presets.set_value(section, "include_filter", INCLUDE)
	presets.set_value(section, "exclude_filter", BASE_EXCLUDE)
	presets.set_value(section, "export_path", path)
	presets.set_value(section, "script_export_mode", 2)
	if platform == "Android" and not presets.has_section_key(section + ".options", "gradle_build/use_gradle_build"):
		presets.set_value(section + ".options", "gradle_build/use_gradle_build", false)

## 새 스토어 preset은 현재 Android 기본 preset의 설정을 상속한다.
func _add_store(presets: ConfigFile, preset_name: String, target: String, android: String) -> void:
	for suffix in ["", ".options"]:
		for key in presets.get_section_keys(android + suffix):
			presets.set_value(target + suffix, key, presets.get_value(android + suffix, key))
	presets.set_value(target, "name", preset_name)

## Gradle·배포 형식·SDK 포함 여부를 기능 플래그와 스토어 정책에 맞춘다.
func _apply_store(presets: ConfigFile, section: String, store: Dictionary, exclude: String) -> void:
	var options := section + ".options"
	var google: bool = store.store == "google_play"
	presets.set_value(section, "runnable", false)
	presets.set_value(section, "custom_features", store.store)
	presets.set_value(section, "export_filter", "all_resources")
	presets.set_value(section, "include_filter", INCLUDE)
	presets.set_value(section, "exclude_filter", exclude)
	presets.set_value(section, "export_path", store.export_path)
	presets.set_value(section, "script_export_mode", 2)
	presets.set_value(options, "gradle_build/use_gradle_build", true)
	presets.set_value(options, "gradle_build/export_format", store.export_format)
	# ONE store 배포물에는 Google Play Billing·Play Games를 넣지 않는다.
	presets.set_value(options, "billing/include_sdk", google and _feature("iap"))
	presets.set_value(options, "billing/onestore_include_sdk", not google and _feature("iap"))
	presets.set_value(options, "ads/include_sdk", _feature("ads"))
	presets.set_value(options, "game_services/include_sdk", google and _feature("game_services"))

func _feature(feature: String) -> bool:
	return bool(_config.get_value("features", feature + "_enabled", false))
