## 게임 로직 없이 공통 기능의 입력과 결과를 확인하는 검증 화면이다.
extends Control

var output: Label
var content: VBoxContainer

func _ready() -> void:
	App.initialize()
	var safe := SafeArea.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(safe)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	safe.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)
	_label("MOBILE TEMPLATE  /  " + GameConfig.TEMPLATE_VERSION, 28)
	_label("Godot %s · %s · %s" % [Engine.get_version_info().string, MobilePlatform.current(), "MOCK" if GameConfig.use_mocks() else "UNAVAILABLE"], 18)
	_label("Framework validation • Scroll for settings", 18)
	output = _label("Ready. Request mock consent before showing ads.", 20)
	output.custom_minimum_size.y = 80
	_button("Save Test", _save_test)
	_button("Load Test", _load_test)
	_button("Play BGM", func():
		var stream := preload("res://assets/demo/bgm.wav").duplicate() as AudioStreamWAV
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = stream.data.size() / 2
		AudioManager.play_bgm(stream)
		_log("BGM playing"))
	_button("Play SFX", func(): AudioManager.play_sfx(preload("res://assets/demo/tone.wav")); _log("SFX playing"))
	_button("Play UI Sound", func(): AudioManager.play_ui(preload("res://assets/demo/tone.wav")); _log("UI sound playing"))
	_button("Stop BGM", AudioManager.stop_bgm)
	_button("Request Mock Consent", App.privacy.request_consent)
	_button("Deny Mock Consent", func(): App.privacy.set_mock_status("denied"); App.privacy.request_consent())
	_button("Grant Mock Consent", func(): App.privacy.set_mock_status("granted"); App.privacy.request_consent())
	_button("Show Mock Rewarded Ad", func(): _log("Mock Rewarded Advertisement…"); App.ads.show_rewarded("demo_reward"))
	_button("Show Mock Interstitial", func(): _log("Mock Interstitial…"); App.ads.show_interstitial("demo_pause"))
	_button("Mock Rewarded Error", func(): App.ads.set_mock_result("error"); App.ads.show_rewarded("demo_error"))
	for result in ["success", "cancel", "error"]:
		_button("Mock Purchase " + result.capitalize(), func(): App.billing.set_mock_result(result); App.billing.purchase("REMOVE_ADS"))
	_button("Restore Mock Purchases", App.billing.restore_purchases)
	_button("Analytics Event", func(): _log("Analytics accepted: %s" % App.analytics.track_event("demo_test")))
	_button("Mock In-App Review", App.review.request_review)
	_button("Game Services Sign In", func(): App.game_services.set_mock_result("success"); App.game_services.authenticate())
	_button("Game Services Sign In Cancel", func(): App.game_services.set_mock_result("cancel"); App.game_services.authenticate())
	_button("Game Services Sign In Error", func(): App.game_services.set_mock_result("error"); App.game_services.authenticate())
	_button("Submit Demo Score", func(): App.game_services.set_mock_result("success"); App.game_services.submit_score("DEMO_SCORE", 100))
	_button("Unlock Demo Achievement", func(): App.game_services.set_mock_result("success"); App.game_services.unlock_achievement("DEMO_FIRST_WIN"))
	_button("Show Leaderboard", func(): App.game_services.show_leaderboard("DEMO_SCORE"))
	_button("Show Achievements", App.game_services.show_achievements)
	_button("Vibrate", func(): MobilePlatform.vibrate(); _log("Vibration requested (mobile only)"))
	_button("Scene Transition", func(): SceneManager.change_scene("res://scenes/transition_demo.tscn"))
	_label("SETTINGS", 24)
	content.add_child(SettingsPanel.new())
	App.ads.rewarded_completed.connect(func(id: String): _log("rewarded_completed: " + id))
	App.ads.rewarded_failed.connect(func(id: String, reason: String): _log("rewarded_failed: %s / %s" % [id, reason]))
	App.ads.interstitial_closed.connect(func(id: String): _log("interstitial_closed: " + id))
	App.ads.ad_failed.connect(func(id: String, reason: String): _log("ad_failed: %s / %s" % [id, reason]))
	App.billing.purchase_completed.connect(func(id: String, _transaction: Dictionary): _log("purchase_completed: " + id))
	App.billing.purchase_cancelled.connect(func(id: String): _log("purchase_cancelled: " + id))
	App.billing.purchase_failed.connect(func(id: String, reason: String): _log("purchase_failed: %s / %s" % [id, reason]))
	App.billing.restore_completed.connect(func(items: Array): _log("restore_completed: %s item(s)" % items.size()))
	App.billing.restore_failed.connect(func(reason: String): _log("restore_failed: " + reason))
	App.privacy.consent_updated.connect(func(status: String): _log("Mock consent: " + status))
	App.review.request_finished.connect(func(status: String): _log("Review: " + status))
	App.game_services.request_completed.connect(func(operation: String, details: Dictionary): _log("Game services: %s / %s" % [operation, details]))
	App.game_services.request_failed.connect(func(operation: String, reason: String): _log("Game services failed: %s / %s" % [operation, reason]))
	App.back_requested.connect(_back)
	SaveManager.save_failed.connect(func(error: int): _log("Save failed: %s" % error))
	Settings.save_failed.connect(func(error: int): _log("Settings failed: %s" % error))

func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	content.add_child(label)
	return label

func _button(text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 56
	button.pressed.connect(action)
	content.add_child(button)

func _log(message: String) -> void:
	output.text = message
	AppLogger.info("Demo", message)

func _save_test() -> void:
	SaveManager.set_value("demo_counter", int(SaveManager.data.get("demo_counter", 0)) + 1)
	_log("Save result: %s, data: %s" % [SaveManager.save_slot(), SaveManager.data])

func _load_test() -> void:
	_log("Load result: %s, data: %s" % [SaveManager.load_slot(), SaveManager.data])

func _back() -> void:
	_log("Android back received; game/UI decides navigation.")
