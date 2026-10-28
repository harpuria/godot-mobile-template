## 별도 테스트 APK에서 Android SDK 등록·실패 경로와 Google 샘플 광고를 진단한다. 실제 결제는 시작하지 않는다.
extends Control

var _content: VBoxContainer
var _output: Label
var _rewarded_button: Button
var _interstitial_button: Button
var _checks := 0
var _failures := 0
var _seen := {"rewarded": false, "interstitial": false}
var _elapsed := 0.0

func _ready() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 14)
	scroll.add_child(_content)
	_label("Android SDK Probe — Google sample ads only")
	_label("Purchases are queried only. This APK never launches a purchase flow.")
	_output = _label("")
	for feature in ["iap", "ads", "privacy", "game_services"]:
		GameConfig.config.set_value("features", feature + "_enabled", true)
	for feature in ["analytics", "review"]:
		GameConfig.config.set_value("features", feature + "_enabled", false)
	for section in ["billing", "ads", "game_services"]:
		GameConfig.config.set_value(section, "android_mode", "native")
		GameConfig.config.set_value(section, "android_native_verified", true)
	GameConfig.config.set_value("ads", "use_test_ads", true)
	_check(OS.get_name() == "Android", "Android platform")
	_check(AndroidPlugin.find_plugin("GodotGooglePlayBilling", AndroidBillingAdapter.METHODS, AndroidBillingAdapter.EVENTS) != null, "Billing JNI methods and signals")
	_check(AndroidPlugin.find_plugin("PoingGodotAdMob", AndroidAdmobAdapter.CORE_METHODS, ["on_initialization_complete"]) != null, "AdMob core JNI contract")
	for kind in ["Rewarded", "Interstitial"]:
		_check(AndroidPlugin.find_plugin("PoingGodotAdMob" + kind + "Ad", AndroidAdmobAdapter.AD_METHODS, AndroidAdmobAdapter._events(kind.to_lower())) != null, kind + " JNI contract")
	_check(AndroidPlugin.find_plugin("PoingGodotAdMobConsentInformation", AndroidAdmobPrivacyAdapter.INFO_METHODS, AndroidAdmobPrivacyAdapter.INFO_EVENTS) != null, "UMP information JNI contract")
	_check(AndroidPlugin.find_plugin("PoingGodotAdMobUserMessagingPlatform", AndroidAdmobPrivacyAdapter.FORM_METHODS, AndroidAdmobPrivacyAdapter.FORM_EVENTS) != null, "UMP forms JNI contract")
	_check(AndroidPlugin.find_plugin("GodotPlayGameServices", ["initialize", "isAuthenticated", "signIn", "submitScore", "unlockAchievement", "showLeaderboard", "showAchievements"], ["userAuthenticated", "scoreSubmitted", "achievementUnlocked"]) != null, "GPGS JNI contract alongside billing and ads")
	App.initialize()
	_check(App.billing.adapter is AndroidBillingAdapter and App.billing.adapter._plugin != null, "App owns bound native billing")
	_check(App.ads.adapter is AndroidAdmobAdapter and App.ads.adapter._core != null, "App owns bound native ads")
	_check(App.privacy.adapter is AndroidAdmobPrivacyAdapter and App.privacy.adapter._info != null, "App owns bound native UMP")
	_check(not App.ads.adapter._initialized, "Ads wait for consent before initialization")
	_check(not App.game_services.is_authenticated(), "No fabricated game account")
	if not OS.is_debug_build():
		_check(not GameConfig.use_mocks(), "Release excludes configured mocks")
		var mock := MockBillingAdapter.new()
		add_child(mock)
		var failures: Array = []
		var completions: Array = []
		var restore_failures: Array = []
		mock.purchase_failed.connect(func(_id: String, reason: String): failures.append(reason))
		mock.purchase_completed.connect(func(_id: String, _transaction: Dictionary): completions.append("purchase"))
		mock.restore_completed.connect(func(_items: Array): completions.append("restore"))
		mock.restore_failed.connect(func(reason: String): restore_failures.append(reason))
		mock.purchase("REMOVE_ADS", {"store_id": "unused", "type": "non_consumable"})
		mock.owned["REMOVE_ADS"] = {"mock": true}
		mock.restore_purchases()
		await get_tree().create_timer(0.3).timeout
		_check(failures == ["mock_not_allowed"] and completions.is_empty(), "Release direct Mock purchase cannot succeed")
		_check(restore_failures == ["mock_not_allowed"] and completions.is_empty(), "Release direct Mock restore cannot succeed")
		mock.queue_free()
	App.billing.products_updated.connect(func(items: Array): _log("Billing query returned %s products" % items.size()))
	App.billing.products_failed.connect(func(reason: String): _log("Billing query failed explicitly: " + reason))
	App.privacy.consent_updated.connect(func(status: String): _log("UMP status: " + status))
	App.ads.rewarded_completed.connect(func(id: String): _log("NATIVE_REWARD " + id))
	App.ads.rewarded_failed.connect(func(id: String, reason: String): _log("Rewarded %s: %s" % [id, reason]))
	App.ads.interstitial_closed.connect(func(id: String): _log("NATIVE_INTERSTITIAL_CLOSED " + id))
	App.ads.ad_failed.connect(func(id: String, reason: String): _log("Ad %s: %s" % [id, reason]))
	_button("Refresh UMP consent", func(): App.privacy.request_consent())
	_button("Privacy options", func(): App.privacy.show_privacy_options())
	_button("Query store products (no purchase)", func(): App.billing.query_products())
	_rewarded_button = _button("Show Google sample rewarded", func(): App.ads.show_rewarded("probe_reward"))
	_interstitial_button = _button("Show Google sample interstitial", func(): App.ads.show_interstitial("probe_break"))
	_log("ANDROID_SERVICES_PROBE: %s checks, %s failures; debug=%s" % [_checks, _failures, OS.is_debug_build()])
	App.billing.query_products()
	App.privacy.request_consent()

func _process(delta: float) -> void:
	if _rewarded_button == null:
		return
	_rewarded_button.disabled = not App.ads.is_rewarded_ready()
	_interstitial_button.disabled = not App.ads.is_interstitial_ready()
	_elapsed += delta
	if _elapsed < 1.0:
		return
	_elapsed = 0.0
	for kind in ["rewarded", "interstitial"]:
		var ready: bool = App.ads.is_rewarded_ready() if kind == "rewarded" else App.ads.is_interstitial_ready()
		if ready and not _seen[kind]:
			_seen[kind] = true
			_log("NATIVE_AD_LOADED " + kind)

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
	print("ANDROID_SERVICES_PROBE %s: %s" % ["PASS" if condition else "FAIL", message])

func _label(message: String) -> Label:
	var label := Label.new()
	label.text = message
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 22)
	_content.add_child(label)
	return label

func _button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 72
	button.pressed.connect(action)
	_content.add_child(button)
	return button

func _log(message: String) -> void:
	_output.text = message
	print("ANDROID_SERVICES_PROBE " + message)
