## 공통 게임 서비스와 공개 native 계약을 가짜 SDK로 검증한다. 기기 검증은 별도다.
extends Node

class FakeAndroidSDK extends Node:
	signal userAuthenticated(success: bool)
	signal achievementUnlocked(success: bool, native_id: String)
	signal scoreSubmitted(success: bool, native_id: String)
	var calls: Array = []
	var authenticated := true
	func initialize() -> void:
		calls.append(["initialize"])
	func signIn() -> void:
		calls.append(["signIn"])
	func isAuthenticated() -> void:
		userAuthenticated.emit(authenticated)
	func unlockAchievement(native_id: String) -> void:
		calls.append(["unlockAchievement", native_id])
	func submitScore(native_id: String, score: int) -> void:
		calls.append(["submitScore", native_id, score])
	func showLeaderboard(native_id: String) -> void:
		calls.append(["showLeaderboard", native_id])
	func showAchievements() -> void:
		calls.append(["showAchievements"])

class AndroidHarness extends AndroidGameServicesAdapter:
	var sdk := FakeAndroidSDK.new()
	func initialize() -> void:
		add_child(sdk)
		_bind_plugin(sdk)

class FakeJNIMethodTable extends Node:
	func has_java_method(method: String) -> bool:
		return method == "initialize"

class FakeIOSSDK extends Node:
	var authenticated := false
	var calls: Array = []
	var events: Array[Dictionary] = []
	var immediate_error := OK
	func authenticate() -> Error:
		calls.append(["authenticate"])
		return immediate_error
	func is_authenticated() -> bool:
		return authenticated
	func post_score(data: Dictionary) -> Error:
		calls.append(["post_score", data])
		return immediate_error
	func award_achievement(data: Dictionary) -> Error:
		calls.append(["award_achievement", data])
		return immediate_error
	func show_game_center(data: Dictionary) -> Error:
		calls.append(["show_game_center", data])
		return immediate_error
	func get_pending_event_count() -> int:
		return events.size()
	func pop_pending_event() -> Dictionary:
		return events.pop_front()

class IOSHarness extends IOSGameServicesAdapter:
	var sdk := FakeIOSSDK.new()
	func initialize() -> void:
		add_child(sdk)
		_bind_plugin(sdk)

var results: Array = []

## 로그인, 실패, 논리 ID, 중복/지연 콜백과 OS 계약을 SceneTree에서 검사한다.
func run(test: Node) -> void:
	var service := App.game_services
	_watch(service)
	test.check(service.adapter is MockGameServicesAdapter, "Game services Mock selected")
	test.check(service.submit_score("DEMO_SCORE", 100) == ERR_UNAUTHORIZED, "Game services requires authentication")
	test.check(results.back() == ["error", "submit_score", "not_authenticated"], "Unauthenticated failure signal")
	service.authenticate()
	test.check(service.authenticate() == ERR_BUSY, "Game services duplicate sign in rejected")
	await test.get_tree().create_timer(0.08).timeout
	test.check(service.is_authenticated() and results.back()[0] == "success", "Mock game services sign in")
	service.submit_score("DEMO_SCORE", 123)
	await test.get_tree().create_timer(0.08).timeout
	test.check(results.back()[2].logical_id == "DEMO_SCORE" and results.back()[2].mock, "Score logical ID and Mock marker")
	test.check(service.adapter.scores.DEMO_SCORE == 123, "Mock score received")
	service.unlock_achievement("DEMO_FIRST_WIN")
	await test.get_tree().create_timer(0.08).timeout
	test.check(service.adapter.achievements.DEMO_FIRST_WIN, "Mock achievement unlocked")
	service.show_leaderboard("DEMO_SCORE")
	await test.get_tree().create_timer(0.08).timeout
	test.check(results.back()[2].ui_status == "requested", "Mock leaderboard reports request only")
	service.show_achievements()
	await test.get_tree().create_timer(0.08).timeout
	test.check(results.back()[1] == "show_achievements", "Mock achievements UI request")
	test.check(service.submit_score("UNKNOWN", 1) == ERR_INVALID_PARAMETER, "Unknown leaderboard rejected")
	test.check(service.unlock_achievement("UNKNOWN") == ERR_INVALID_PARAMETER, "Unknown achievement rejected")
	for outcome in ["cancel", "error"]:
		service.set_mock_result(outcome)
		service.authenticate()
		await test.get_tree().create_timer(0.08).timeout
		test.check(not service.is_authenticated() and results.back()[2] == ("cancelled" if outcome == "cancel" else "mock_error"), "Mock authentication " + outcome)
	service.set_mock_result("success")
	service.authenticate()
	await test.get_tree().create_timer(0.08).timeout
	await _android(test)
	await _ios(test)
	# 실제 플랫폼 adapter도 Desktop에서 SDK가 없으면 안전하게 실패해야 한다.
	for implementation in [AndroidGameServicesAdapter.new(), IOSGameServicesAdapter.new()]:
		var unavailable := _service(test, implementation, "android")
		test.check(unavailable.authenticate() == ERR_UNAVAILABLE, "Absent platform plugin fails explicitly")
		unavailable.queue_free()
	var disabled_adapter := AndroidHarness.new()
	var disabled := GameServicesService.new()
	test.add_child(disabled)
	disabled.initialize(false, disabled_adapter, {}, {}, "android")
	test.check(disabled_adapter.sdk.calls.is_empty(), "Feature off does not initialize SDK")
	disabled_adapter.sdk.free()
	disabled.queue_free()

func _watch(service: GameServicesService) -> void:
	service.request_completed.connect(func(kind: String, details: Dictionary): results.append(["success", kind, details]))
	service.request_failed.connect(func(kind: String, reason: String): results.append(["error", kind, reason]))

func _service(test: Node, implementation: GameServicesAdapter, platform: String) -> GameServicesService:
	var service := GameServicesService.new()
	test.add_child(service)
	service.initialize(true, implementation, {"SCORE": {platform: "native.score"}, "EMPTY": {platform: ""}},
		{"WIN": {platform: "native.win"}}, platform, 0.05)
	_watch(service)
	return service

func _android(test: Node) -> void:
	var jni := FakeJNIMethodTable.new()
	test.check(not jni.has_method("initialize") and AndroidGameServicesAdapter.supports_plugin_method(jni, "initialize"), "JNI methods use has_java_method instead of Object.has_method")
	test.check(not AndroidGameServicesAdapter.supports_plugin_method(jni, "submitScore"), "Missing JNI method rejected")
	jni.free()
	var implementation := AndroidHarness.new()
	var service := _service(test, implementation, "android")
	var sdk := implementation.sdk
	service.authenticate()
	sdk.userAuthenticated.emit(true)
	test.check(service.is_authenticated(), "Android authentication callback translated")
	test.check(service.submit_score("EMPTY", 1) == ERR_UNCONFIGURED, "Empty native ID rejected")
	service.submit_score("SCORE", 321)
	test.check(sdk.calls.back() == ["submitScore", "native.score", 321], "Android native score mapping")
	var before := results.size()
	sdk.scoreSubmitted.emit(true, "other.score")
	test.check(results.size() == before and service.show_achievements() == ERR_BUSY, "Wrong Android callback cannot complete request")
	sdk.scoreSubmitted.emit(false, "native.score")
	test.check(results.back()[2] == "native_error", "Android native error translated")
	service.unlock_achievement("WIN")
	test.check(sdk.calls.back() == ["unlockAchievement", "native.win"], "Android achievement mapping")
	sdk.achievementUnlocked.emit(true, "native.win")
	test.check(results.back()[2].logical_id == "WIN", "Android achievement completion translated")
	service.show_leaderboard("SCORE")
	test.check(results.back()[2].ui_status == "requested", "Android UI does not claim display or close")
	service.show_achievements()
	test.check(sdk.calls.back() == ["showAchievements"], "Android achievements screen routed")
	service.submit_score("SCORE", 22)
	await test.get_tree().create_timer(0.08).timeout
	test.check(results.back()[2] == "timeout", "Native request timeout surfaced")
	var retry_error := service.submit_score("SCORE", 23)
	test.check(retry_error == ERR_BUSY and results.back()[2] == "busy", "Unfinished OS request blocks retry after timeout")
	before = results.size()
	sdk.scoreSubmitted.emit(true, "native.score")
	test.check(results.size() == before, "Timed out native callback cannot succeed")
	service.submit_score("SCORE", 24)
	sdk.scoreSubmitted.emit(true, "native.score")
	test.check(results.back()[0] == "success", "Request recovers after abandoned callback")
	before = results.size()
	sdk.scoreSubmitted.emit(true, "native.score")
	test.check(results.size() == before, "Duplicate native completion ignored")
	sdk.authenticated = false
	service.submit_score("SCORE", 25)
	test.check(results.back()[2] == "not_authenticated" and not service.is_authenticated(), "Android checks current authentication before native dispatch")
	service.queue_free()

func _ios(test: Node) -> void:
	var implementation := IOSHarness.new()
	var service := _service(test, implementation, "ios")
	var sdk := implementation.sdk
	service.authenticate()
	sdk.authenticated = true
	sdk.events.append({"type": "authentication", "result": "ok"})
	implementation._process(0.0)
	test.check(service.is_authenticated() and results.back()[0] == "success", "iOS authentication event translated")
	service.submit_score("SCORE", 456)
	test.check(sdk.calls.back() == ["post_score", {"category": "native.score", "score": 456}], "iOS native score mapping")
	sdk.events.append({"type": "achievements", "result": "ok"})
	sdk.events.append({"type": "post_score", "result": "error", "error_code": 9})
	implementation._process(0.0)
	test.check(results.back()[2] == "native_error:9", "Unrelated iOS event ignored and error surfaced")
	service.unlock_achievement("WIN")
	test.check(sdk.calls.back()[1].name == "native.win" and sdk.calls.back()[1].progress == 100.0, "iOS achievement uses full completion")
	sdk.events.append({"type": "award_achievement", "result": "ok"})
	implementation._process(0.0)
	service.show_leaderboard("SCORE")
	test.check(sdk.calls.back()[1].leaderboard_name == "native.score", "iOS leaderboard UI mapping")
	sdk.events.append({"type": "show_game_center", "result": "ok"})
	implementation._process(0.0)
	test.check(results.back()[2].ui_status == "closed", "iOS UI close event translated")
	service.show_achievements()
	test.check(sdk.calls.back()[1].view == "achievements", "iOS achievements UI routed")
	sdk.events.append({"type": "show_game_center", "result": "ok"})
	implementation._process(0.0)
	service.submit_score("SCORE", 16777217)
	test.check(results.back()[2] == "score_out_of_range", "iOS score float precision protected")
	service.submit_score("SCORE", -9223372036854775807 - 1)
	test.check(results.back()[2] == "score_out_of_range", "iOS minimum int cannot bypass score range")
	sdk.immediate_error = ERR_UNAVAILABLE
	service.submit_score("SCORE", 1)
	test.check(results.back()[2].begins_with("native_error:"), "iOS immediate SDK error surfaced")
	sdk.immediate_error = OK
	service.submit_score("SCORE", 2)
	await test.get_tree().create_timer(0.08).timeout
	test.check(results.back()[2] == "timeout", "iOS missing callback timeout")
	var before := results.size()
	sdk.events.append({"type": "post_score", "result": "ok"})
	implementation._process(0.0)
	test.check(results.size() == before, "iOS abandoned event cannot succeed")
	# 이전 큐에 들어 있던 중복 결과는 완료 신호에서 시작한 다음 요청에 전달하지 않는다.
	var restart := func(kind: String, _details: Dictionary):
		if kind == "submit_score":
			service.submit_score("SCORE", 4)
	service.request_completed.connect(restart, CONNECT_ONE_SHOT)
	service.submit_score("SCORE", 3)
	sdk.events.append({"type": "post_score", "result": "ok"})
	sdk.events.append({"type": "post_score", "result": "ok"})
	before = results.size()
	implementation._process(0.0)
	implementation._process(0.0)
	test.check(results.size() == before + 1 and service.show_achievements() == ERR_BUSY, "iOS queued duplicate cannot complete reentrant request")
	sdk.events.append({"type": "post_score", "result": "ok"})
	implementation._process(0.0)
	service.queue_free()
