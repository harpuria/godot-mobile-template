## 게임 시작 전 초기화 hook. 저장 schema와 번역을 등록한다.
## config/game.cfg: init_script="res://examples/game_skeleton/game_init.gd"
extends RefCounted

const Session := preload("res://examples/game_skeleton/game_session.gd")
const LOCALES := ["en", "ko"]

## bootstrap이 App.initialize()(저장 load 포함) 전에 한 번 호출한다.
func before_app_initialize() -> void:
	SaveManager.schema_version = 1
	# 저장 구조를 바꾸면 schema_version을 올리고 변환 함수를 등록한다.
	# SaveManager.register_migration(1, func(old: Dictionary) -> Dictionary: return old)
	for code in LOCALES:
		var translation := load(Session.ROOT + "/locale/%s.po" % code) as Translation
		if translation != null:
			TranslationServer.add_translation(translation)
