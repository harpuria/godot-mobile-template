## 게임 저장 데이터와 버전 migration을 관리한다. 사용자 설정은 Settings가 담당한다.
extends Node

signal saved
signal loaded
signal save_failed(error: int)
signal load_failed(error: int)
## 원본을 읽지 못해 `.bak`에서 복구했을 때 원본의 오류 코드와 함께 알린다.
signal recovered_from_backup(error: int)
const UNREADABLE_SUFFIX := ".unreadable"
var data: Dictionary = {}
var schema_version: int = 1
var storage_path: String = "user://save.json"
var dirty := false
var write_blocked := false
var migrations: Dictionary = {}
var _skip_backup_once := false

func _ready() -> void:
	var timer := Timer.new()
	timer.wait_time = maxf(1.0, float(GameConfig.value("save", "autosave_seconds", 30.0)))
	timer.timeout.connect(flush)
	add_child(timer)
	timer.start()

## from_version에서 다음 버전으로 변환하는 Callable(Dictionary)->Dictionary를 등록한다.
func register_migration(from_version: int, migration: Callable) -> void:
	migrations[from_version] = migration

## 게임이 정의한 JSON 호환 값을 저장한다. 직접 data를 수정한 경우 mark_dirty를 호출한다.
func set_value(key: String, value: Variant) -> void:
	data[key] = value
	mark_dirty()

## 직접 수정한 게임 데이터를 다음 자동 저장 대상으로 표시한다.
func mark_dirty() -> void:
	dirty = true

## 변경된 데이터만 자동 저장한다.
func flush() -> Error:
	return save_slot() if dirty else OK

## 기본 슬롯에 버전과 데이터를 함께 기록하고 실패를 신호로 알린다.
## 직전 저장 파일은 `.bak`으로 남긴다. 손상된 원본은 백업으로 복사하지 않는다.
func save_slot() -> Error:
	var error := ERR_UNAUTHORIZED if write_blocked else JsonStore.write(storage_path, {"version": schema_version, "data": data}, not _skip_backup_once)
	if error != OK:
		save_failed.emit(error)
		return error
	_skip_backup_once = false
	dirty = false
	saved.emit()
	return OK

## 원본을 읽지 못하면 `.bak`을 시도한다. 둘 다 실패하면 메모리와 파일을 보존하고 자동 덮어쓰기를 차단한다.
func load_slot() -> Error:
	var primary := _read_slot(storage_path)
	if primary.error == OK:
		_accept(primary.data, primary.migrated)
		return OK
	# 버전·migration 오류는 파일 손상이 아니므로 예전 백업으로 되돌리지 않는다.
	var backup := _read_slot(storage_path + JsonStore.BACKUP_SUFFIX) if primary.unreadable else {"error": primary.error}
	if backup.error != OK:
		if primary.error == ERR_FILE_NOT_FOUND:
			_accept({}, false)
			return OK
		write_blocked = true
		load_failed.emit(primary.error)
		return primary.error as Error
	# 읽지 못한 원본은 보관하고, 다음 저장이 정상 백업을 덮어쓰지 않게 한다.
	_keep_unreadable_copy()
	_skip_backup_once = true
	_accept(backup.data, true)
	recovered_from_backup.emit(primary.error)
	return OK

## 파일 하나를 읽어 envelope 검사와 migration까지 마친 결과 {error, data, migrated}를 반환한다.
## 파일이 없거나 JSON으로 읽지 못하면 unreadable을 표시한다.
func _read_slot(path: String) -> Dictionary:
	var result := JsonStore.read(path)
	if result.error != OK:
		return {"error": result.error, "unreadable": true}
	var document: Dictionary = result.document
	if not document.get("data") is Dictionary:
		return {"error": ERR_INVALID_DATA, "unreadable": false}
	var raw_version: Variant = document.get("version", -1)
	if not (raw_version is int or raw_version is float):
		return {"error": ERR_INVALID_DATA, "unreadable": false}
	if float(raw_version) != floorf(float(raw_version)):
		return {"error": ERR_INVALID_DATA, "unreadable": false}
	var version := int(raw_version)
	if version < 1 or version > schema_version:
		return {"error": ERR_INVALID_DATA, "unreadable": false}
	var candidate: Dictionary = document.data.duplicate(true)
	var migrated := version != schema_version
	while version < schema_version:
		if not migrations.has(version):
			return {"error": ERR_UNAVAILABLE, "unreadable": false}
		var next: Variant = migrations[version].call(candidate)
		if not next is Dictionary:
			return {"error": ERR_INVALID_DATA, "unreadable": false}
		candidate = next
		version += 1
	return {"error": OK, "data": candidate, "migrated": migrated}

func _accept(loaded_data: Dictionary, needs_save: bool) -> void:
	data = loaded_data
	dirty = needs_save
	write_blocked = false
	loaded.emit()

func _keep_unreadable_copy() -> void:
	if FileAccess.file_exists(storage_path):
		DirAccess.copy_absolute(storage_path, storage_path + UNREADABLE_SUFFIX)

## 게임이 사용자 확인 후 새 저장을 시작할 때만 호출한다. 다음 저장 시 기존 파일을 교체한다.
## load 실패 상태였다면 읽지 못한 원본을 `.unreadable`로 보관하고 백업 파일은 그대로 둔다.
func reset_slot(initial_data: Dictionary = {}) -> void:
	if write_blocked:
		_keep_unreadable_copy()
		_skip_backup_once = true
	data = initial_data.duplicate(true)
	write_blocked = false
	dirty = true
