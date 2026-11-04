## 고정 결제·AdMob AAR와 로컬 공개 설정을 명시적으로 선택한 Android Gradle export에 연결한다.
## Google Play Billing과 ONE store IAP는 한 배포물에 함께 넣지 않는다.
@tool
extends EditorPlugin

var _exporter: AndroidServicesExport

func _enter_tree() -> void:
	_exporter = AndroidServicesExport.new()
	add_export_plugin(_exporter)

func _exit_tree() -> void:
	remove_export_plugin(_exporter)
	_exporter = null

class AndroidServicesExport extends EditorExportPlugin:
	const KEYS := {
		"billing": ["android_mode", "android_native_verified", "timeout_seconds", "android_product_ids", "onestore_product_ids", "onestore_public_key"],
		"ads": ["android_mode", "android_native_verified", "use_test_ads", "android_app_id", "rewarded_unit_id", "interstitial_unit_id", "test_device_ids", "retry_seconds"],
		"privacy": ["tag_for_under_age_of_consent"],
	}
	const TEST_APP_ID := "ca-app-pub-3940256099942544~3347511713"
	const ONESTORE_SDK := "com.onestorecorp.sdk:sdk-iap:21.04.00"
	## native/android/onestore_iap/build.sh가 만드는 로컬 AAR. 기기 검증 전까지 Git에 넣지 않는다.
	const ONESTORE_AAR := "android_services/onestore/bin/GodotOneStoreIap.aar"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _get_name() -> String:
		return "TemplateAndroidServices"

	func _get_export_options(_platform: EditorExportPlatform) -> Array[Dictionary]:
		return [
			{"option": {"name": "billing/include_sdk", "type": TYPE_BOOL}, "default_value": false},
			{"option": {"name": "billing/onestore_include_sdk", "type": TYPE_BOOL}, "default_value": false},
			{"option": {"name": "ads/include_sdk", "type": TYPE_BOOL}, "default_value": false},
		]

	func _get_android_libraries(_platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		var result := PackedStringArray()
		var variant := "debug" if debug else "release"
		if get_option("billing/include_sdk"):
			result.append("android_services/billing/bin/GodotGooglePlayBilling-%s.aar" % variant)
		elif get_option("billing/onestore_include_sdk"):
			result.append(ONESTORE_AAR)
		if get_option("ads/include_sdk"):
			for module in ["ads", "core"]:
				result.append("android_services/admob/bin/poing-godot-admob-%s-%s.aar" % [module, variant])
		return result

	func _get_android_dependencies(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		var result := PackedStringArray()
		if get_option("billing/include_sdk"):
			result.append("com.android.billingclient:billing-ktx:9.1.0")
		elif get_option("billing/onestore_include_sdk"):
			result.append(ONESTORE_SDK)
		if get_option("ads/include_sdk"):
			result.append("com.google.android.libraries.ads.mobile.sdk:ads-mobile-sdk:1.4.0")
			result.append("androidx.constraintlayout:constraintlayout:2.2.0")
		return result

	func _get_android_manifest_application_element_contents(_platform: EditorExportPlatform, _debug: bool) -> String:
		if not get_option("ads/include_sdk"):
			return ""
		var config := _build_config()
		var app_id := TEST_APP_ID if bool(config.get_value("ads", "use_test_ads", true)) else str(config.get_value("ads", "android_app_id", ""))
		var pattern := RegEx.new()
		pattern.compile("^ca-app-pub-[0-9]{16}~[0-9]{10}$")
		if pattern.search(app_id) == null:
			push_error("AdMob requires a valid Android app ID or use_test_ads=true")
			return ""
		return '<meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" android:value="%s"/>' % app_id

	## 비밀 파일 전체를 복사하지 않고 허용한 공개 런타임 설정만 빌드에 넣는다.
	func _export_begin(features: PackedStringArray, debug: bool, _path: String, _flags: int) -> void:
		if not get_export_platform() is EditorExportPlatformAndroid:
			return
		var google_billing := bool(get_option("billing/include_sdk"))
		var onestore_billing := bool(get_option("billing/onestore_include_sdk"))
		if not google_billing and not onestore_billing and not get_option("ads/include_sdk"):
			return
		if not get_option("gradle_build/use_gradle_build"):
			push_error("Android native services require a Gradle export preset")
			return
		if google_billing and onestore_billing:
			push_error("Google Play Billing and ONE store IAP cannot share one export; select one store per preset")
		if onestore_billing and not FileAccess.file_exists("res://addons/" + ONESTORE_AAR):
			push_error("ONE store AAR missing; run native/android/onestore_iap/build.sh first: res://addons/" + ONESTORE_AAR)
		if onestore_billing and not features.has("onestore"):
			push_error("ONE store billing preset needs custom feature 'onestore'")
		var config := _build_config()
		# 포함하지 않은 SDK의 native gate가 로컬 설정으로 열리지 않도록 한다.
		if not google_billing and not onestore_billing:
			config.set_value("billing", "android_native_verified", false)
		if not get_option("ads/include_sdk"):
			config.set_value("ads", "android_native_verified", false)
		if not debug:
			_warn_release(config, google_billing or onestore_billing)
		add_file("res://config/android_services.build.cfg", config.encode_to_text().to_utf8_buffer(), false)

	## 스토어 배포 빌드가 테스트 광고나 닫힌 gate로 나가지 않도록 경고한다. 실패시키지는 않는다.
	func _warn_release(config: ConfigFile, billing: bool) -> void:
		if billing and not _native_open(config, "billing"):
			push_warning("Release export: billing SDK included but billing native gate is closed; purchases will be unavailable")
		if get_option("ads/include_sdk"):
			if not _native_open(config, "ads"):
				push_warning("Release export: ads SDK included but ads native gate is closed; ads will be unavailable")
			if bool(config.get_value("ads", "use_test_ads", true)):
				push_warning("Release export uses Google sample ads (ads/use_test_ads=true); set real IDs in config/android.local.cfg before store upload")

	## App._android_native()와 같은 규칙으로 release에서 native가 선택될지 판단한다.
	func _native_open(config: ConfigFile, section: String) -> bool:
		var mode := str(config.get_value(section, "android_mode", "inherit"))
		if mode == "inherit":
			var game := ConfigFile.new()
			game.load("res://config/game.cfg")
			mode = str(game.get_value("services", "mode", "native"))
		return mode == "native" and bool(config.get_value(section, "android_native_verified", false))

	func _build_config() -> ConfigFile:
		var result := ConfigFile.new()
		for path in ["res://config/game.cfg", "res://config/android.local.cfg"]:
			var source := ConfigFile.new()
			if source.load(path) != OK:
				continue
			for section in KEYS:
				for key in KEYS[section]:
					if source.has_section_key(section, key):
						result.set_value(section, key, source.get_value(section, key))
		return result
