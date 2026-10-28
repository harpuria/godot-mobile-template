## 고정 Play Games AAR와 SDK 의존성을 Android export에 연결한다. singleton은 추가하지 않는다.
@tool
extends EditorPlugin

var _exporter: PlayGamesExport

func _enter_tree() -> void:
	_exporter = PlayGamesExport.new()
	add_export_plugin(_exporter)

func _exit_tree() -> void:
	remove_export_plugin(_exporter)
	_exporter = null

class PlayGamesExport extends EditorExportPlugin:
	## Android preset에서 명시적으로 선택한 경우에만 네이티브 SDK를 포함한다.
	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _get_name() -> String:
		return "TemplatePlayGamesExport"

	func _get_export_options(platform: EditorExportPlatform) -> Array[Dictionary]:
		if not _supports_platform(platform):
			return []
		return [{"option": {"name": "game_services/include_sdk", "type": TYPE_BOOL}, "default_value": false}]

	func _get_android_libraries(_platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		if not get_option("game_services/include_sdk"):
			return []
		var variant := "debug" if debug else "release"
		return ["play_game_services/bin/GodotPlayGameServices-%s.aar" % variant]

	func _get_android_dependencies(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		if not get_option("game_services/include_sdk"):
			return []
		return ["com.google.code.gson:gson:2.14.0", "com.google.android.gms:play-services-games-v2:22.1.0"]

	## Game ID가 없으면 APP_ID를 만들지 않는다. 잘못된 운영 ID를 생성하지 않는다.
	func _get_android_manifest_application_element_contents(_platform: EditorExportPlatform, _debug: bool) -> String:
		if not get_option("game_services/include_sdk"):
			return ""
		var config := _build_config()
		if not _valid_id(str(config.get_value("game_services", "android_game_id", ""))):
			return ""
		return '<meta-data android:name="com.google.android.gms.games.APP_ID" android:value="@string/pgs_game_id"/>'

	## 로컬 설정은 export에만 주입하고 소스 config나 다른 Android 리소스를 덮어쓰지 않는다.
	func _export_begin(_features: PackedStringArray, _debug: bool, _path: String, _flags: int) -> void:
		if not get_export_platform() is EditorExportPlatformAndroid or not get_option("game_services/include_sdk"):
			return
		var config := _build_config()
		add_file("res://config/game_services.build.cfg", config.encode_to_text().to_utf8_buffer(), false)
		var directory := str(get_option("gradle_build/gradle_build_directory"))
		if directory.is_empty():
			directory = "res://android/build"
		var resource_path := directory.path_join("res/values/pgs_game_id.xml")
		var id := str(config.get_value("game_services", "android_game_id", ""))
		if not _valid_id(id):
			if FileAccess.file_exists(resource_path):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(resource_path))
			print("[PlayGamesExport] Game ID unset; native loading probe only.")
			return
		var file := FileAccess.open(resource_path, FileAccess.WRITE)
		if file == null:
			push_error("Cannot write Play Games Android resource: " + resource_path)
			return
		file.store_string('<?xml version="1.0" encoding="utf-8"?><resources><string name="pgs_game_id" translatable="false">%s</string></resources>' % id)

	func _build_config() -> ConfigFile:
		var result := ConfigFile.new()
		var keys := ["android_game_id", "android_mode", "android_native_verified", "leaderboard_ids", "achievement_ids"]
		for path in ["res://config/game.cfg", "res://config/game_services.local.cfg"]:
			var source := ConfigFile.new()
			if source.load(path) != OK:
				continue
			for key in keys:
				if source.has_section_key("game_services", key):
					result.set_value("game_services", key, source.get_value("game_services", key))
		return result

	func _valid_id(id: String) -> bool:
		return not id.is_empty() and id.is_valid_int() and id.to_int() > 0 and id == str(id.to_int())
