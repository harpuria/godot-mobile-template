## 공개 config를 Godot 프로젝트 및 export preset에 동기화하는 개발 도구이다.
extends SceneTree

func _initialize() -> void:
	var config := ConfigFile.new()
	if config.load("res://config/game.cfg") != OK:
		push_error("Cannot load config/game.cfg")
		quit(1)
		return
	var orientations := {"landscape": 0, "portrait": 1, "sensor_landscape": 4, "sensor_portrait": 5, "sensor": 6}
	var orientation := str(config.get_value("app", "orientation", "sensor"))
	if not orientations.has(orientation):
		push_error("Invalid orientation: " + orientation)
		quit(1)
		return
	ProjectSettings.set_setting("application/config/name", config.get_value("app", "name"))
	ProjectSettings.set_setting("application/config/version", config.get_value("app", "version"))
	ProjectSettings.set_setting("display/window/handheld/orientation", orientations[orientation])
	if ProjectSettings.save() != OK:
		push_error("Cannot save project.godot")
		quit(1)
		return
	var presets := ConfigFile.new()
	presets.load("res://export_presets.cfg")
	for index in range(2):
		var section := "preset.%s" % index
		var android := index == 0
		presets.set_value(section, "name", "Android" if android else "iOS")
		presets.set_value(section, "platform", "Android" if android else "iOS")
		presets.set_value(section, "runnable", true)
		presets.set_value(section, "export_filter", "all_resources")
		presets.set_value(section, "include_filter", "config/game.cfg,config/products.json")
		presets.set_value(section, "exclude_filter", "tests/*,tools/*,docs/*,*.md,config/*.local.*")
		presets.set_value(section, "export_path", "build/android/mobile-template.apk" if android else "build/ios/mobile-template.zip")
		presets.set_value(section, "script_export_mode", 2)
		var options := section + ".options"
		if android:
			presets.set_value(options, "package/unique_name", config.get_value("app", "android_package"))
			presets.set_value(options, "package/name", config.get_value("app", "name"))
			presets.set_value(options, "version/name", config.get_value("app", "version"))
			# 사용자가 선택한 Gradle 및 version code는 재실행해도 유지한다.
			if not presets.has_section_key(options, "gradle_build/use_gradle_build"):
				presets.set_value(options, "gradle_build/use_gradle_build", false)
			if not presets.has_section_key(options, "version/code"):
				presets.set_value(options, "version/code", 1)
			presets.set_value(options, "permissions/vibrate", true)
		else:
			presets.set_value(options, "application/bundle_identifier", config.get_value("app", "ios_bundle"))
			presets.set_value(options, "application/short_version", config.get_value("app", "version"))
			if not presets.has_section_key(options, "application/version"):
				presets.set_value(options, "application/version", "1")
	var error := presets.save("res://export_presets.cfg")
	if error != OK:
		push_error("Cannot save export_presets.cfg")
	print("Configuration synchronized: " + orientation)
	quit(0 if error == OK else 1)
