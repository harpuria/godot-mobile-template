## 공개 config를 Godot 프로젝트 및 export preset에 동기화하는 개발 도구이다.
## 개발용 Android/iOS preset과 스토어 배포 preset(Google Play AAB, ONE store APK)을 함께 관리한다.
extends SceneTree

const DEMO_SCENE := "res://scenes/main.tscn"
const BASE_EXCLUDE := "tests/*,tools/*,docs/*,examples/*,native/*,*.md,config/*.local.*"
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
	ProjectSettings.set_setting("application/config/name", _config.get_value("app", "name"))
	ProjectSettings.set_setting("application/config/version", _config.get_value("app", "version"))
	ProjectSettings.set_setting("display/window/handheld/orientation", orientations[orientation])
	if ProjectSettings.save() != OK:
		push_error("Cannot save project.godot")
		quit(1)
		return
	var presets := ConfigFile.new()
	presets.load("res://export_presets.cfg")
	_ensure_base(presets, 0, "Android", "build/android/mobile-template.apk")
	_ensure_base(presets, 1, "iOS", "build/ios/mobile-template.zip")
	for preset_name in STORE_PRESETS:
		_ensure_store(presets, preset_name)
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
	var error := presets.save("res://export_presets.cfg")
	if error != OK:
		push_error("Cannot save export_presets.cfg")
	print("Configuration synchronized: %s, build %s" % [orientation, build_number])
	quit(0 if error == OK else 1)

## preset.N 섹션만 번호 순서로 반환한다.
func _preset_sections(presets: ConfigFile) -> Array[String]:
	var result: Array[String] = []
	var index := 0
	while presets.has_section("preset.%s" % index):
		result.append("preset.%s" % index)
		index += 1
	return result

## 개발용 기본 preset의 이름·경로·필터를 고정한다. signing·Gradle 선택은 유지한다.
func _ensure_base(presets: ConfigFile, index: int, platform: String, path: String) -> void:
	var section := "preset.%s" % index
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

## 스토어 preset이 없으면 Android 기본 preset을 복제해 만든다.
func _ensure_store(presets: ConfigFile, preset_name: String) -> void:
	for section in _preset_sections(presets):
		if presets.get_value(section, "name", "") == preset_name:
			return
	var target := "preset.%s" % _preset_sections(presets).size()
	for suffix in ["", ".options"]:
		for key in presets.get_section_keys("preset.0" + suffix):
			presets.set_value(target + suffix, key, presets.get_value("preset.0" + suffix, key))
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
