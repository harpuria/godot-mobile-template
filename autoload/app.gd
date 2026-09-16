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
	privacy.initialize(GameConfig.enabled("privacy"), MockPrivacyAdapter.new() if mock and GameConfig.enabled("privacy") else PrivacyAdapter.new())
	ads = AdsService.new()
	add_child(ads)
	ads.initialize(GameConfig.enabled("ads"), MockAdsAdapter.new() if mock and GameConfig.enabled("ads") else AdsAdapter.new(), privacy)
	billing = BillingService.new()
	add_child(billing)
	billing.initialize(GameConfig.enabled("iap"), MockBillingAdapter.new() if mock and GameConfig.enabled("iap") else BillingAdapter.new())
	analytics = Analytics.new()
	add_child(analytics)
	analytics.initialize(GameConfig.enabled("analytics") and mock, MockAnalyticsAdapter.new() if mock and GameConfig.enabled("analytics") else AnalyticsAdapter.new(), privacy)
	review = ReviewService.new()
	add_child(review)
	review.initialize(GameConfig.enabled("review"), MockReviewAdapter.new() if mock and GameConfig.enabled("review") else ReviewAdapter.new())
	SaveManager.load_slot()
	ready_for_game = true
	AppLogger.info("App", "Platform=%s Mock=%s" % [MobilePlatform.current(), mock])
	initialized.emit()

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
			SaveManager.flush()
			AudioManager.set_suspended(true)
			paused.emit()
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
