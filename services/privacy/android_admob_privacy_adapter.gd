## Poing AdMob 5.1.0의 UMP를 연결한다. 광고 요청 자격을 분석·개인화 동의로 해석하지 않는다.
class_name AndroidAdmobPrivacyAdapter
extends PrivacyAdapter

const INFO_METHODS := ["update", "get_consent_status", "get_is_consent_form_available", "get_privacy_options_requirement_status"]
const INFO_EVENTS := ["on_consent_info_updated_success", "on_consent_info_updated_failure"]
const FORM_METHODS := ["load_consent_form", "show", "show_privacy_options_form"]
const FORM_EVENTS := ["on_consent_form_load_success_listener", "on_consent_form_load_failure_listener", "on_consent_form_dismissed", "on_privacy_options_form_dismissed_listener"]
var _info: Object
var _forms: Object
var _allowed := false
var _busy := false
var _expired := false
var _form_id := -1
var _phase := ""
var _timer: Timer

## SDK 검색은 활성화된 Android 서비스에서만 수행한다.
func initialize() -> void:
	var info := AndroidPlugin.find_plugin("PoingGodotAdMobConsentInformation", INFO_METHODS, INFO_EVENTS)
	var forms := AndroidPlugin.find_plugin("PoingGodotAdMobUserMessagingPlatform", FORM_METHODS, FORM_EVENTS)
	if info != null and forms != null:
		_bind_plugins(info, forms)

func _bind_plugins(info: Object, forms: Object) -> void:
	if not AndroidPlugin.matches(info, INFO_METHODS, INFO_EVENTS) or not AndroidPlugin.matches(forms, FORM_METHODS, FORM_EVENTS):
		return
	_info = info
	_forms = forms
	_info.connect("on_consent_info_updated_success", _updated)
	_info.connect("on_consent_info_updated_failure", _failed)
	_forms.connect("on_consent_form_load_success_listener", _loaded)
	_forms.connect("on_consent_form_load_failure_listener", _failed)
	_forms.connect("on_consent_form_dismissed", _dismissed)
	_forms.connect("on_privacy_options_form_dismissed_listener", _options_dismissed)
	_timer = Timer.new()
	_timer.one_shot = true
	add_child(_timer)
	_timer.timeout.connect(func():
		_expired = true
		_allowed = false
		consent_updated.emit("unavailable"))

## 세션마다 최신 UMP 상태를 가져오고 필요한 경우에만 동의 화면을 표시한다.
func request_consent() -> void:
	if not _begin("update"):
		return
	_info.call("update", {"tag_for_under_age_of_consent": bool(GameConfig.value("privacy", "tag_for_under_age_of_consent", false)), "consent_debug_settings": null})

func can_request_ads() -> bool:
	return _allowed and not _busy

## UMP가 요구한 개인정보 선택 화면을 이용자가 다시 열 수 있다.
func show_privacy_options() -> void:
	if not is_instance_valid(_info):
		consent_updated.emit("unavailable")
		return
	if int(_info.call("get_privacy_options_requirement_status")) != 2:
		return
	if _begin("options"):
		_forms.call("show_privacy_options_form")

func _begin(phase: String) -> bool:
	if _busy:
		return false
	if not is_instance_valid(_info) or not is_instance_valid(_forms):
		consent_updated.emit("unavailable")
		return false
	_busy = true
	_expired = false
	_allowed = false
	_phase = phase
	_timer.start(120.0)
	consent_updated.emit("unknown")
	return true

func _updated() -> void:
	if not _busy or _phase != "update":
		return
	if _expired:
		_complete(false)
	elif int(_info.call("get_consent_status")) == 2 and bool(_info.call("get_is_consent_form_available")):
		_phase = "load"
		_forms.call("load_consent_form")
	else:
		_complete(true)

func _loaded(uid: int) -> void:
	if not _busy or _phase != "load":
		return
	if _expired:
		_complete(false)
		return
	_form_id = uid
	_phase = "show"
	_forms.call("show", uid)

func _dismissed(uid: int, error: Dictionary) -> void:
	if _busy and _phase == "show" and uid == _form_id:
		_complete(error.is_empty())

func _options_dismissed(error: Dictionary) -> void:
	if _busy and _phase == "options":
		_complete(error.is_empty())

func _failed(_error: Dictionary) -> void:
	if _busy:
		_complete(false)

func _complete(success: bool) -> void:
	_timer.stop()
	# 이 버전은 canRequestAds를 공개하지 않는다. 갱신 후 NOT_REQUIRED/OBTAINED만 허용한다.
	_allowed = success and not _expired and int(_info.call("get_consent_status")) in [1, 3]
	_busy = false
	_phase = ""
	consent_updated.emit("ads_allowed" if _allowed else "denied" if success and not _expired else "unavailable")
