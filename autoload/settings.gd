## 오디오, 언어, 진동과 게임 확장 설정을 게임 저장과 분리해서 보관한다.
extends Node

signal changed(key: String, value: Variant)
signal save_failed(error: int)
var storage_path := "user://settings.cfg"
## language가 빈 값이면 기기 언어를 따른다. 번역이 없는 언어는 프로젝트 fallback locale로 표시된다.
var values := {"bgm_volume": 0.8, "sfx_volume": 0.8, "ui_volume": 0.8, "haptics_enabled": true, "language": ""}

func _ready() -> void:
	load_settings()

## 별도 ConfigFile을 읽으며, 실패하면 기본값을 사용한다.
func load_settings() -> Error:
	var file := ConfigFile.new()
	var error := file.load(storage_path)
	if error == OK:
		for key in file.get_section_keys("settings"):
			var value: Variant = file.get_value("settings", key)
			if key.ends_with("_volume"):
				if not (value is float or value is int):
					continue
				value = clampf(float(value), 0.0, 1.0)
			if key == "haptics_enabled" and not value is bool:
				continue
			if key == "language" and not value is String:
				continue
			values[key] = value
			changed.emit(key, value)
	_apply_language()
	return error

## 사용자가 고른 언어가 없으면 기기 locale을 적용한다.
func _apply_language() -> void:
	var language := str(values.get("language", ""))
	TranslationServer.set_locale(OS.get_locale() if language.is_empty() else language)

## 설정 값을 조회하며 없으면 기본값을 반환한다.
func get_setting(key: String, fallback: Variant = null) -> Variant:
	return values.get(key, fallback)

## 설정 변경을 즉시 저장하고 UI 및 AudioManager에 알린다.
func set_setting(key: String, value: Variant) -> Error:
	if key.ends_with("_volume"):
		value = clampf(float(value), 0.0, 1.0)
	values[key] = value
	if key == "language":
		_apply_language()
	changed.emit(key, value)
	return save_settings()

## 설정을 임시 파일에 쓴 뒤 교체하고 실패를 알린다.
func save_settings() -> Error:
	var file := ConfigFile.new()
	for key in values:
		file.set_value("settings", key, values[key])
	var error := file.save(storage_path + ".tmp")
	if error == OK:
		error = DirAccess.rename_absolute(storage_path + ".tmp", storage_path)
	if error != OK:
		save_failed.emit(error)
	return error
