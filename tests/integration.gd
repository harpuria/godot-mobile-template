## 실제 SceneTree에서 저장, 서비스 결과, lifecycle 및 장면 전환을 검증한다.
extends Node

var failures := 0
var checks := 0
var results: Array = []
var test_dir := ""

func _ready() -> void:
	# 장면 교체 중에도 검증 실행기를 유지한다.
	get_parent().remove_child.call_deferred(self)
	get_tree().root.add_child.call_deferred(self)
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + message)
	else:
		print("PASS: " + message)

func _run() -> void:
	test_dir = OS.get_environment("TMPDIR").path_join("godot-mobile-test-%s" % Time.get_ticks_usec())
	if test_dir.is_empty() or not test_dir.is_absolute_path():
		test_dir = "/tmp/godot-mobile-test-%s" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(test_dir)
	SaveManager.storage_path = test_dir.path_join("save.json")
	Settings.storage_path = test_dir.path_join("settings.cfg")
	if "--disabled" in OS.get_cmdline_user_args() or "--native" in OS.get_cmdline_user_args():
		_check_unavailable_initialization()
		return
	_check_game_init_hook()
	App.initialize()
	check(App.ready_for_game, "App initialization")
	var billing_before := App.billing
	App.initialize()
	check(App.billing == billing_before, "Idempotent initialization")
	check(GameConfig.use_mocks(), "Desktop debug Mock selected")
	var game_services_checks := preload("res://tests/game_services_checks.gd").new()
	add_child(game_services_checks)
	await game_services_checks.run(self)
	game_services_checks.queue_free()
	var android_checks := preload("res://tests/android_services_checks.gd").new()
	add_child(android_checks)
	await android_checks.run(self)
	android_checks.queue_free()
	var ledger_checks := preload("res://tests/purchase_ledger_checks.gd").new()
	add_child(ledger_checks)
	await ledger_checks.run(self)
	ledger_checks.queue_free()
	SaveManager.set_value("progress", {"level": 3, "flags": [true, false]})
	check(SaveManager.save_slot() == OK, "Save succeeds")
	SaveManager.data.clear()
	check(SaveManager.load_slot() == OK and SaveManager.data.progress.level == 3, "JSON round trip")
	SaveManager.set_value("autosaved", true)
	check(SaveManager.flush() == OK and not SaveManager.dirty, "Autosave flush")
	SaveManager.set_value("timer_autosave", true)
	var autosave_timer := SaveManager.get_child(0) as Timer
	autosave_timer.start(0.05)
	await get_tree().create_timer(0.1).timeout
	check(not SaveManager.dirty, "Autosave timer writes changed data")
	autosave_timer.start(30.0)
	SaveManager.schema_version = 2
	SaveManager.register_migration(1, func(data: Dictionary) -> Dictionary:
		data["migrated"] = true
		return data)
	check(SaveManager.load_slot() == OK and SaveManager.data.migrated, "Version migration")
	check(SaveManager.dirty and SaveManager.flush() == OK, "Migrated data persisted")
	JsonStore.write(SaveManager.storage_path, {"version": 99, "data": {}})
	check(SaveManager.load_slot() != OK and SaveManager.write_blocked, "Future version protected")
	check(SaveManager.save_slot() != OK, "Rejected load cannot be overwritten")
	var file := FileAccess.open(SaveManager.storage_path, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	check(SaveManager.load_slot() == ERR_PARSE_ERROR, "Corrupt save detected")
	SaveManager.reset_slot({"fresh": true})
	check(SaveManager.save_slot() == OK, "Explicit reset restores writing")
	JsonStore.write(SaveManager.storage_path, {"version": 1.5, "data": {}})
	check(SaveManager.load_slot() == ERR_INVALID_DATA, "Fractional schema rejected")
	SaveManager.reset_slot({"fresh": true})
	SaveManager.save_slot()
	var valid_path := SaveManager.storage_path
	SaveManager.storage_path = test_dir.path_join("missing/save.json")
	check(SaveManager.save_slot() != OK, "Write failure surfaced")
	SaveManager.storage_path = valid_path
	check(Settings.set_setting("bgm_volume", 0.25) == OK, "Settings save")
	Settings.values.bgm_volume = 0.9
	check(Settings.load_settings() == OK and Settings.get_setting("bgm_volume") == 0.25, "Settings round trip")
	check(Settings.set_setting("custom_option", 7) == OK, "Game settings extension")
	Settings.set_setting("sfx_volume", 0.0)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")), "Zero volume mutes SFX")
	var tone := preload("res://assets/demo/tone.wav")
	AudioManager.play_bgm(tone)
	check(AudioManager.bgm.playing, "BGM playback starts")
	App.notification(NOTIFICATION_APPLICATION_PAUSED)
	check(AudioManager.bgm.stream_paused, "Pause suspends audio")
	App.notification(NOTIFICATION_APPLICATION_RESUMED)
	check(not AudioManager.bgm.stream_paused, "Resume restores audio")
	AudioManager.stop_bgm()
	check(not AudioManager.bgm.playing, "BGM stop")
	AudioManager.play_sfx(tone)
	AudioManager.play_ui(tone)
	check(AudioManager.effect_players.size() == 2, "SFX and UI playback")
	await get_tree().create_timer(0.4).timeout
	check(AudioManager.effect_players.is_empty(), "Finished effects cleaned up")
	App.ads.rewarded_completed.connect(func(id: String): results.append(["reward", id]))
	App.ads.rewarded_failed.connect(func(id: String, reason: String): results.append(["ad_error", id, reason]))
	App.ads.interstitial_closed.connect(func(id: String): results.append(["interstitial", id]))
	App.ads.show_rewarded("blocked")
	check(results.back()[0] == "ad_error", "Unknown consent blocks ads")
	check(not App.analytics.track_event("blocked"), "Unknown consent blocks analytics")
	App.privacy.request_consent()
	check(App.ads.is_rewarded_ready(), "Mock consent permits ads")
	App.ads.show_rewarded("revive")
	check(not App.ads.is_rewarded_ready(), "Ad busy guard")
	await get_tree().create_timer(0.4).timeout
	check(results.back() == ["reward", "revive"], "Rewarded completion")
	App.ads.set_mock_result("error")
	App.ads.show_rewarded("failure")
	await get_tree().create_timer(0.4).timeout
	check(results.back()[0] == "ad_error", "Rewarded failure")
	App.ads.show_interstitial("break")
	await get_tree().create_timer(0.4).timeout
	check(results.back() == ["interstitial", "break"], "Interstitial completion")
	check(App.analytics.track_event("test", {"source": "integration"}), "Mock analytics")
	App.privacy.set_mock_status("denied")
	App.privacy.request_consent()
	check(not App.ads.is_rewarded_ready(), "Denied consent blocks ads")
	App.billing.purchase_completed.connect(func(id: String, tx: Dictionary): results.append(["purchase", id, tx]))
	App.billing.purchase_cancelled.connect(func(id: String): results.append(["cancel", id]))
	App.billing.purchase_failed.connect(func(id: String, reason: String): results.append(["billing_error", id, reason]))
	App.billing.restore_completed.connect(func(items: Array): results.append(["restore", items]))
	App.billing.purchase("REMOVE_ADS")
	App.billing.purchase("COIN_SMALL")
	check(results.back()[2] == "busy", "Concurrent purchase rejected")
	await get_tree().create_timer(0.3).timeout
	check(results.back()[0] == "purchase" and results.back()[2].mock, "Mock purchase success")
	check(results.back()[2].store_id == "com.example.game.remove_ads", "Logical product maps to store ID")
	for outcome in ["cancel", "error"]:
		App.billing.set_mock_result(outcome)
		App.billing.purchase("REMOVE_ADS")
		await get_tree().create_timer(0.3).timeout
		check(results.back()[0] == ("cancel" if outcome == "cancel" else "billing_error"), "Purchase " + outcome)
	App.billing.purchase("COIN_SMALL")
	await get_tree().create_timer(0.3).timeout
	App.billing.restore_purchases()
	await get_tree().create_timer(0.3).timeout
	check(results.back()[0] == "restore" and results.back()[1].size() == 1, "Restore excludes consumables")
	App.billing.purchase("UNKNOWN")
	check(results.back()[2] == "invalid_product", "Unknown product rejected")
	App.billing.enabled = false
	App.billing.purchase("REMOVE_ADS")
	check(results.back()[2] == "disabled", "Billing feature off")
	App.ads.enabled = false
	check(not App.ads.is_rewarded_ready(), "Ads feature off")
	App.review.request_finished.connect(func(status: String): results.append(["review", status]))
	App.review.request_review()
	check(results.back()[1] == "mock_requested", "Mock review")
	# 기본 adapter는 native가 없는 경우 가짜 성공을 만들지 않는다.
	var unavailable := BillingAdapter.new()
	add_child(unavailable)
	unavailable.purchase_failed.connect(func(_id: String, reason: String): results.append(["unavailable", reason]))
	unavailable.purchase("REMOVE_ADS", {})
	check(results.back()[1] == "unavailable", "Missing native SDK fails explicitly")
	unavailable.queue_free()
	check(SceneManager.change_scene("res://missing.tscn") == ERR_FILE_NOT_FOUND, "Missing scene rejected")
	check(SceneManager.change_scene("res://scenes/transition_demo.tscn") == OK, "Transition accepted")
	check(SceneManager.change_scene("res://scenes/main.tscn") == ERR_BUSY, "Duplicate transition rejected")
	await SceneManager.transition_completed
	check(get_tree().current_scene.name == "TransitionDemo", "Scene transition completed")
	SceneManager.change_scene("res://scenes/main.tscn", false)
	await SceneManager.transition_completed
	check(get_tree().current_scene.name == "Demo", "Demo instantiated")
	# 실제 데모 버튼의 Callable을 실행해 UI 배선을 함께 검사한다.
	var demo := get_tree().current_scene
	for text in ["Save Test", "Load Test", "Play SFX", "Play UI Sound", "Play BGM", "Stop BGM"]:
		for child in demo.content.get_children():
			if child is Button and child.text == text:
				child.pressed.emit()
	await get_tree().create_timer(0.4).timeout
	check(not AudioManager.bgm.playing, "Demo audio buttons wired")
	App.game_services.request_completed.connect(func(operation: String, details: Dictionary): results.append(["game_services", operation, details]))
	var game_buttons := {"Game Services Sign In": "authenticate", "Submit Demo Score": "submit_score",
		"Unlock Demo Achievement": "unlock_achievement", "Show Leaderboard": "show_leaderboard", "Show Achievements": "show_achievements"}
	for text in game_buttons:
		var before := results.size()
		for child in demo.content.get_children():
			if child is Button and child.text == text:
				child.pressed.emit()
		await get_tree().create_timer(0.08).timeout
		check(results.size() > before and results.back()[0] == "game_services" and results.back()[1] == game_buttons[text], "Demo game services button: " + text)
	if "--capture" in OS.get_cmdline_user_args():
		var scroll := demo.content.get_parent() as ScrollContainer
		for child in demo.content.get_children():
			if child is Button and child.text == "Game Services Sign In":
				scroll.ensure_control_visible(child)
		await get_tree().process_frame
		RenderingServer.force_draw(false)
		var image := get_viewport().get_texture().get_image()
		check(image.save_png("/tmp/mobile-template-demo.png") == OK, "Rendered screenshot saved")
	# 검증용 파일은 일반 user:// 저장 슬롯과 격리되어 있다.
	for entry in DirAccess.get_files_at(test_dir):
		DirAccess.remove_absolute(test_dir.path_join(entry))
	DirAccess.remove_absolute(test_dir)
	print("INTEGRATION: %s checks, %s failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)

## bootstrap의 게임 초기화 hook 호출과 잘못된 script 거절을 검증한다.
func _check_game_init_hook() -> void:
	var bootstrap := preload("res://scenes/bootstrap.gd")
	var fixture := preload("res://tests/fixtures/game_init_fixture.gd")
	check(bootstrap.run_init_script(str(GameConfig.value("app", "init_script", ""))) == OK, "Configured game init script runs")
	check(bootstrap.run_init_script("") == OK, "Empty game init script skipped")
	var calls_before: int = fixture.calls
	check(bootstrap.run_init_script("res://tests/fixtures/game_init_fixture.gd") == OK and fixture.calls == calls_before + 1, "Game init hook called once")
	check(bootstrap.run_init_script("res://tests/fixtures/missing_init.gd") == ERR_FILE_NOT_FOUND, "Missing game init script reported")
	check(bootstrap.run_init_script("res://tests/fixtures/game_init_invalid_node.gd") == ERR_INVALID_PARAMETER, "Node game init script rejected")
	check(bootstrap.run_init_script("res://tests/fixtures/game_init_missing_method.gd") == ERR_METHOD_NOT_FOUND, "Game init script without hook rejected")

## 플래그가 모두 꺼지거나 native SDK가 없는 별도 초기화 경로를 검증한다.
func _check_unavailable_initialization() -> void:
	var disabled := "--disabled" in OS.get_cmdline_user_args()
	if disabled:
		for feature in ["ads", "iap", "analytics", "privacy", "review", "game_services"]:
			GameConfig.config.set_value("features", feature + "_enabled", false)
	else:
		GameConfig.config.set_value("services", "mode", "native")
	App.initialize()
	check(not App.ads.adapter is MockAdsAdapter, "No Mock ads initialized")
	check(not App.billing.adapter is MockBillingAdapter, "No Mock billing initialized")
	App.billing.purchase_failed.connect(func(_id: String, reason: String): results.append(reason))
	App.billing.purchase("REMOVE_ADS")
	check(results.back() == ("disabled" if disabled else "unavailable"), "No fake purchase success")
	App.billing.restore_failed.connect(func(reason: String): results.append(reason))
	App.billing.restore_purchases()
	check(results.back() == ("disabled" if disabled else "unavailable"), "Restore unavailable")
	App.privacy.request_consent()
	check(not App.privacy.can_use_services(), "No fake consent")
	check(not App.ads.is_rewarded_ready(), "No ad readiness")
	check(not App.analytics.track_event("test"), "No analytics dispatch")
	App.review.request_finished.connect(func(status: String): results.append(status))
	App.review.request_review()
	check(results.back() == ("disabled" if disabled else "unavailable"), "Review unavailable")
	check(not App.game_services.adapter is MockGameServicesAdapter, "No Mock game services initialized")
	App.game_services.request_failed.connect(func(_operation: String, reason: String): results.append(reason))
	App.game_services.authenticate()
	check(results.back() == ("disabled" if disabled else "unavailable"), "Game services authentication unavailable")
	App.game_services.submit_score("DEMO_SCORE", 100)
	check(results.back() == ("disabled" if disabled else "unavailable"), "Game services score unavailable")
	App.game_services.unlock_achievement("DEMO_FIRST_WIN")
	check(results.back() == ("disabled" if disabled else "unavailable"), "Game services achievement unavailable")
	check(not App.game_services.is_authenticated(), "No fake game services authentication")
	DirAccess.remove_absolute(test_dir)
	print("INTEGRATION %s: %s checks, %s failures" % ["disabled" if disabled else "native", checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
