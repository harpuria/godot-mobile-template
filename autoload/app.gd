## 앱 초기화 순서, 플랫폼 설정, 서비스 소유권 및 모바일 lifecycle을 관리한다.
extends Node

signal initialized
signal paused
signal resumed
signal back_requested
signal quitting
var ready_for_game := false
var ads: AdsService
var billing: BillingService
var analytics: Analytics
var privacy: PrivacyService
var review: ReviewService
var game_services: GameServicesService

## bootstrap에서 한 번 호출한다. native 미설치 기능은 unavailable adapter를 사용한다.
func initialize() -> void:
	if ready_for_game:
		return
	var actual := Engine.get_version_info()
	if "%s.%s.%s" % [actual.major, actual.minor, actual.patch] != GameConfig.ENGINE_VERSION:
		push_warning("Template requires Godot " + GameConfig.ENGINE_VERSION)
	_apply_orientation()
	var mock := GameConfig.use_mocks()
	privacy = PrivacyService.new()
	add_child(privacy)
	privacy.initialize(GameConfig.enabled("privacy"), _privacy_adapter(mock))
	ads = AdsService.new()
	add_child(ads)
	ads.initialize(GameConfig.enabled("ads"), _ads_adapter(mock), privacy)
	billing = BillingService.new()
	add_child(billing)
	billing.initialize(GameConfig.enabled("iap"), _billing_adapter(mock))
	analytics = Analytics.new()
	add_child(analytics)
	analytics.initialize(GameConfig.enabled("analytics") and mock, MockAnalyticsAdapter.new() if mock and GameConfig.enabled("analytics") else AnalyticsAdapter.new(), privacy)
	review = ReviewService.new()
	add_child(review)
	review.initialize(GameConfig.enabled("review"), MockReviewAdapter.new() if mock and GameConfig.enabled("review") else ReviewAdapter.new())
	game_services = GameServicesService.new()
	add_child(game_services)
	game_services.initialize(GameConfig.enabled("game_services"), _game_services_adapter(mock),
		GameConfig.value("game_services", "leaderboard_ids", {}),
		GameConfig.value("game_services", "achievement_ids", {}), MobilePlatform.current().to_lower(),
		float(GameConfig.value("game_services", "timeout_seconds", 120.0)))
	SaveManager.load_slot()
	ready_for_game = true
	AppLogger.info("App", "Platform=%s Mock=%s" % [MobilePlatform.current(), mock])
	initialized.emit()

## 기능별 override와 검증 gate가 모두 열린 Android에서만 네이티브를 선택한다.
func _android_native(section: String) -> bool:
	if MobilePlatform.current() != "Android":
		return false
	var mode := str(GameConfig.value(section, "android_mode", "inherit"))
	if mode == "inherit":
		mode = str(GameConfig.value("services", "mode", "native"))
	return mode == "native" and bool(GameConfig.value(section, "android_native_verified", false))

func _section_mock(section: String, mock: bool) -> bool:
	return mock and (MobilePlatform.current() != "Android" or GameConfig.value(section, "android_mode", "inherit") == "inherit")

func _billing_adapter(mock: bool) -> BillingAdapter:
	if not GameConfig.enabled("iap"):
		return BillingAdapter.new()
	if _android_native("billing"):
		return OneStoreBillingAdapter.new() if GameConfig.store() == "onestore" else AndroidBillingAdapter.new()
	return MockBillingAdapter.new() if _section_mock("billing", mock) else BillingAdapter.new()

func _ads_adapter(mock: bool) -> AdsAdapter:
	if not GameConfig.enabled("ads"):
		return AdsAdapter.new()
	if _android_native("ads"):
		return AndroidAdmobAdapter.new()
	return MockAdsAdapter.new() if _section_mock("ads", mock) else AdsAdapter.new()

func _privacy_adapter(mock: bool) -> PrivacyAdapter:
	if not GameConfig.enabled("privacy"):
		return PrivacyAdapter.new()
	if GameConfig.enabled("ads") and _android_native("ads"):
		return AndroidAdmobPrivacyAdapter.new()
	return MockPrivacyAdapter.new() if _section_mock("ads", mock) else PrivacyAdapter.new()

## 기능 off와 미검증 native 구성은 SDK를 초기화하지 않는다.
func _game_services_adapter(mock: bool) -> GameServicesAdapter:
	if not GameConfig.enabled("game_services"):
		return GameServicesAdapter.new()
	var android_mode := str(GameConfig.value("game_services", "android_mode", "inherit")) if MobilePlatform.current() == "Android" else "inherit"
	if mock and android_mode == "inherit":
		return MockGameServicesAdapter.new()
	if android_mode != "native" and GameConfig.value("services", "mode", "native") != "native":
		return GameServicesAdapter.new()
	if not bool(GameConfig.value("game_services", MobilePlatform.current().to_lower() + "_native_verified", false)):
		return GameServicesAdapter.new()
	match MobilePlatform.current().to_lower():
		"android":
			return AndroidGameServicesAdapter.new()
		"ios":
			return IOSGameServicesAdapter.new()
	return GameServicesAdapter.new()

func _apply_orientation() -> void:
	if not MobilePlatform.is_mobile():
		return
	var orientations := {"portrait": DisplayServer.SCREEN_PORTRAIT, "landscape": DisplayServer.SCREEN_LANDSCAPE,
		"sensor": DisplayServer.SCREEN_SENSOR, "sensor_portrait": DisplayServer.SCREEN_SENSOR_PORTRAIT,
		"sensor_landscape": DisplayServer.SCREEN_SENSOR_LANDSCAPE}
	var selected := str(GameConfig.value("app", "orientation", "sensor"))
	DisplayServer.screen_set_orientation(orientations.get(selected, DisplayServer.SCREEN_SENSOR))

## Android back은 게임/UI가 처리하도록 전달한다. iOS에는 강제 종료 UI를 제공하지 않는다.
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			AudioManager.set_suspended(true)
			paused.emit()
			SaveManager.flush()
		NOTIFICATION_APPLICATION_RESUMED:
			AudioManager.set_suspended(false)
			resumed.emit()
		NOTIFICATION_WM_GO_BACK_REQUEST:
			back_requested.emit()
		NOTIFICATION_WM_CLOSE_REQUEST:
			request_quit()

## 종료 전에 변경된 데이터를 저장한다. 저장 실패 시 호출자에게 알리고 종료를 보류한다.
func request_quit() -> Error:
	var error := SaveManager.flush()
	if error != OK:
		return error
	quitting.emit()
	get_tree().quit()
	return OK
