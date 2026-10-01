## 별도 Android 진단 빌드에서 실제 singleton 로딩과 미설정 경로를 검사한다.
extends Control

var _checks := 0
var _failures := 0
var _results: Array[String] = []
var _content: VBoxContainer
var _output: Label

func _ready() -> void:
	var safe := SafeArea.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(safe)
	var scroll := ScrollContainer.new()
	safe.add_child(scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_content)
	_label("PLAY GAMES NATIVE PROBE")
	_label("Debug: %s / Godot %s" % [OS.is_debug_build(), Engine.get_version_info().string])
	_output = _label("Checking native plugin…")
	for feature in ["ads", "iap", "analytics", "privacy", "review"]:
		GameConfig.config.set_value("features", feature + "_enabled", false)
	GameConfig.config.set_value("features", "game_services_enabled", true)
	GameConfig.config.set_value("services", "mode", "mock")
	GameConfig.config.set_value("game_services", "android_mode", "native")
	# 검증 전용 gate이며 이 플래그 자체를 Verified 증거로 해석하지 않는다.
	GameConfig.config.set_value("game_services", "android_native_verified", true)
	_check(OS.get_name() == "Android", "Android platform")
	_check(Engine.has_singleton("GodotPlayGameServices"), "Native singleton registered")
	if Engine.has_singleton("GodotPlayGameServices"):
		var plugin := Engine.get_singleton("GodotPlayGameServices")
		for method in ["initialize", "isAuthenticated", "signIn", "submitScore", "unlockAchievement", "showLeaderboard", "showAchievements"]:
			_check(AndroidGameServicesAdapter.supports_plugin_method(plugin, method), "Native method " + method)
		for event in ["userAuthenticated", "scoreSubmitted", "achievementUnlocked"]:
			_check(plugin.has_signal(event), "Native signal " + event)
	App.initialize()
	_check(App.game_services.adapter is AndroidGameServicesAdapter, "App owns Android adapter")
	_check(not App.game_services.adapter is MockGameServicesAdapter, "Android native override skips Mock")
	if not OS.is_debug_build():
		_check(not GameConfig.use_mocks(), "Release blocks configured Mock mode")
		var mock := MockGameServicesAdapter.new()
		_check(not mock.is_available(), "Release Mock game services unavailable")
		mock.free()
	App.game_services.request_failed.connect(func(operation: String, reason: String):
		_results.append(reason)
		_log("%s failed: %s" % [operation, reason]))
	App.game_services.request_completed.connect(func(operation: String, details: Dictionary): _log("%s completed: %s" % [operation, details]))
	if str(GameConfig.value("game_services", "android_game_id", "")).is_empty():
		_check(not App.game_services.adapter.is_available(), "Missing Game ID blocks SDK initialization")
		_check(not App.game_services.is_authenticated(), "No fake authentication")
		App.game_services.authenticate()
		_check(_results.back() == "unavailable", "Unconfigured sign in fails explicitly")
		App.game_services.submit_score("DEMO_SCORE", 100)
		_check(_results.back() == "unavailable", "Unconfigured score cannot succeed")
		App.game_services.unlock_achievement("DEMO_FIRST_WIN")
		_check(_results.back() == "unavailable", "Unconfigured achievement cannot succeed")
		_label("Game ID not configured. Native loading checked; account tests pending.")
	else:
		_check(App.game_services.adapter.is_available(), "Configured SDK initialized")
		_label("Use the buttons with a registered tester account.")
	_check(not App.billing.adapter is MockBillingAdapter, "No Mock billing in native probe")
	var disabled := GameServicesService.new()
	add_child(disabled)
	disabled.initialize(false, AndroidGameServicesAdapter.new(), {}, {}, "android")
	_check(not disabled.adapter.is_available(), "Disabled service skips SDK initialization")
	disabled.queue_free()
	_button("Sign In", func(): App.game_services.authenticate())
	_button("Submit Demo Score", func(): App.game_services.submit_score("DEMO_SCORE", 100))
	_button("Unlock Demo Achievement", func(): App.game_services.unlock_achievement("DEMO_FIRST_WIN"))
	_button("Show Leaderboard", func(): App.game_services.show_leaderboard("DEMO_SCORE"))
	_button("Show Achievements", func(): App.game_services.show_achievements())
	var summary := "PGS_PROBE: %s checks, %s failures; debug=%s" % [_checks, _failures, OS.is_debug_build()]
	_label(summary)
	print(summary)

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print("PGS_PROBE %s: %s" % ["PASS" if condition else "FAIL", message])

func _label(message: String) -> Label:
	var label := Label.new()
	label.text = message
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 22)
	_content.add_child(label)
	return label

func _button(text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 64
	button.pressed.connect(callback)
	_content.add_child(button)

func _log(message: String) -> void:
	_output.text = message
	print("PGS_PROBE " + message)
