## Poing AdMob 5.1.0의 보상형·전면 광고를 연결하고 동의·광고 수명·중복 보상을 관리한다.
class_name AndroidAdmobAdapter
extends AdsAdapter

const TEST_UNITS := {"rewarded": "ca-app-pub-3940256099942544/5224354917", "interstitial": "ca-app-pub-3940256099942544/1033173712"}
const CORE_METHODS := ["initialize", "set_request_configuration"]
const AD_METHODS := ["create", "load", "show", "destroy"]
var _core: Object
var _plugins: Dictionary = {}
var _privacy: PrivacyService
var _initialized := false
var _initializing := false
var _uids := {"rewarded": -1, "interstitial": -1}
var _loaded_at: Dictionary = {}
var _loading := {"rewarded": false, "interstitial": false}
var _retry_timers: Dictionary = {}
var _active := ""
var _placement := ""
var _earned := false

## 동의가 확정되기 전에는 SDK initialize/load를 호출하지 않는다.
func initialize(privacy: PrivacyService) -> void:
	var core := AndroidPlugin.find_plugin("PoingGodotAdMob", CORE_METHODS, ["on_initialization_complete"])
	var rewarded := AndroidPlugin.find_plugin("PoingGodotAdMobRewardedAd", AD_METHODS, _events("rewarded"))
	var interstitial := AndroidPlugin.find_plugin("PoingGodotAdMobInterstitialAd", AD_METHODS, _events("interstitial"))
	if core != null and rewarded != null and interstitial != null:
		_bind_plugins(core, rewarded, interstitial, privacy)

static func _events(kind: String) -> Array:
	var prefix := "on_" + kind + "_ad_"
	var events: Array = [prefix + "loaded", prefix + "failed_to_load", prefix + "dismissed_full_screen_content", prefix + "failed_to_show_full_screen_content"]
	if kind == "rewarded":
		events.append(prefix + "user_earned_reward")
	return events

func _bind_plugins(core: Object, rewarded: Object, interstitial: Object, privacy: PrivacyService) -> void:
	if not AndroidPlugin.matches(core, CORE_METHODS, ["on_initialization_complete"]):
		return
	for pair in [["rewarded", rewarded], ["interstitial", interstitial]]:
		if not AndroidPlugin.matches(pair[1], AD_METHODS, _events(pair[0])):
			return
	_core = core
	_privacy = privacy
	_plugins = {"rewarded": rewarded, "interstitial": interstitial}
	_core.connect("on_initialization_complete", _initialized_callback, CONNECT_DEFERRED)
	for kind in _plugins:
		var plugin: Object = _plugins[kind]
		var prefix := "on_" + str(kind) + "_ad_"
		plugin.connect(prefix + "loaded", _loaded.bind(kind), CONNECT_DEFERRED)
		plugin.connect(prefix + "failed_to_load", _load_failed.bind(kind), CONNECT_DEFERRED)
		plugin.connect(prefix + "dismissed_full_screen_content", _dismissed.bind(kind), CONNECT_DEFERRED)
		plugin.connect(prefix + "failed_to_show_full_screen_content", _show_failed.bind(kind), CONNECT_DEFERRED)
		var timer := Timer.new()
		timer.one_shot = true
		add_child(timer)
		timer.timeout.connect(_retry_load.bind(kind))
		_retry_timers[kind] = timer
	rewarded.connect("on_rewarded_ad_user_earned_reward", _rewarded, CONNECT_DEFERRED)
	_privacy.consent_updated.connect(_consent_changed)
	_consent_changed(_privacy.status)

func _consent_changed(_status: String) -> void:
	if not _privacy.can_request_ads():
		for kind in _plugins:
			_retry_timers[kind].stop()
			if kind != _active:
				_destroy(kind)
		return
	if not _initialized and not _initializing:
		_initializing = true
		_core.call("set_request_configuration", {"max_ad_content_rating": "", "tag_for_child_directed_treatment": -1, "tag_for_under_age_of_consent": -1}, PackedStringArray(GameConfig.value("ads", "test_device_ids", [])))
		_core.call("initialize")
	elif _initialized:
		_load("rewarded")
		_load("interstitial")

func _initialized_callback(_status: Dictionary) -> void:
	_initialized = true
	_initializing = false
	if _privacy.can_request_ads():
		_load("rewarded")
		_load("interstitial")

func _unit(kind: String) -> String:
	if bool(GameConfig.value("ads", "use_test_ads", true)):
		return TEST_UNITS[kind]
	return str(GameConfig.value("ads", kind + "_unit_id", ""))

func _load(kind: String) -> void:
	if not _initialized or not _privacy.can_request_ads() or _loading[kind] or _loaded_at.has(kind) or kind == _active or _unit(kind).is_empty():
		return
	_uids[kind] = int(_plugins[kind].call("create"))
	_loading[kind] = true
	_retry_timers[kind].start(60.0)
	_plugins[kind].call("load", _unit(kind), {"mediation_extras": {}, "extras": {}, "google_request_agent": "Godot-PoingStudios-5.1.0"}, PackedStringArray(), int(_uids[kind]))

func _retry_load(kind: String) -> void:
	if _loading[kind]:
		_destroy(kind)
	_load(kind)

func _loaded(uid: int, kind: String) -> void:
	if uid != _uids[kind] or not _privacy.can_request_ads():
		_plugins[kind].call("destroy", uid)
		return
	_loading[kind] = false
	_retry_timers[kind].stop()
	_loaded_at[kind] = Time.get_ticks_msec()

func _load_failed(uid: int, _error: Dictionary, kind: String) -> void:
	if uid != _uids[kind]:
		return
	_destroy(kind)
	if _privacy.can_request_ads():
		_retry_timers[kind].start(maxf(1.0, float(GameConfig.value("ads", "retry_seconds", 30.0))))

func _ready_to_show(kind: String) -> bool:
	if _privacy == null or not _privacy.can_request_ads() or not _active.is_empty() or not _loaded_at.has(kind):
		return false
	if Time.get_ticks_msec() - int(_loaded_at[kind]) > 55 * 60 * 1000:
		_destroy(kind)
		_load(kind)
		return false
	return true

func is_rewarded_ready() -> bool:
	return _ready_to_show("rewarded")

func is_interstitial_ready() -> bool:
	return _ready_to_show("interstitial")

## 완료 신호는 유효한 SDK 보상 콜백에서만 한 번 보낸다.
func show_rewarded(placement_id: String) -> void:
	_show("rewarded", placement_id)

func show_interstitial(placement_id: String) -> void:
	_show("interstitial", placement_id)

func _show(kind: String, placement_id: String) -> void:
	if placement_id.is_empty() or not _ready_to_show(kind):
		if kind == "rewarded":
			rewarded_failed.emit(placement_id, "not_ready")
		else:
			ad_failed.emit(placement_id, "not_ready")
		return
	_active = kind
	_placement = placement_id
	_earned = false
	_loaded_at.erase(kind)
	_plugins[kind].call("show", int(_uids[kind]))

func _rewarded(uid: int, reward: Dictionary) -> void:
	if _active != "rewarded" or uid != _uids.rewarded or _earned or float(reward.get("amount", 0)) <= 0:
		return
	_earned = true
	rewarded_completed.emit(_placement)

func _dismissed(uid: int, kind: String) -> void:
	if kind != _active or uid != _uids[kind]:
		return
	var placement := _placement
	var earned := _earned
	_active = ""
	_placement = ""
	_destroy(kind)
	_load(kind)
	if kind == "interstitial":
		interstitial_closed.emit(placement)
	elif not earned:
		rewarded_failed.emit(placement, "reward_not_earned")

func _show_failed(uid: int, _error: Dictionary, kind: String) -> void:
	if kind != _active or uid != _uids[kind]:
		return
	var placement := _placement
	var earned := _earned
	_active = ""
	_placement = ""
	_destroy(kind)
	_load(kind)
	if kind == "rewarded":
		if not earned:
			rewarded_failed.emit(placement, "show_failed")
	else:
		ad_failed.emit(placement, "show_failed")

func _destroy(kind: String) -> void:
	if int(_uids[kind]) >= 0:
		_plugins[kind].call("destroy", int(_uids[kind]))
	_uids[kind] = -1
	_loading[kind] = false
	_loaded_at.erase(kind)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED and is_instance_valid(_core) and _privacy.can_request_ads():
		for kind in _plugins:
			if _loaded_at.has(kind) and Time.get_ticks_msec() - int(_loaded_at[kind]) > 55 * 60 * 1000:
				_destroy(kind)
			_load(kind)

func _exit_tree() -> void:
	for kind in _plugins:
		_destroy(kind)
