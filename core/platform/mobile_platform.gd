## 운영체제 구분과 기초 진동 기능을 Godot API 뒤에 캡슐화한다.
class_name MobilePlatform
extends RefCounted

## Android, iOS, Desktop 중 하나를 반환한다.
static func current() -> String:
	var platform := OS.get_name()
	return platform if platform in ["Android", "iOS"] else "Desktop"

## 현재 플랫폼이 Android 또는 iOS인지 반환한다.
static func is_mobile() -> bool:
	return current() != "Desktop"

## 사용자 설정을 존중하는 기본 진동이다. 정교한 haptic 패턴은 native adapter 확장 대상이다.
static func vibrate(duration_ms: int = 100) -> void:
	if Settings.get_setting("haptics_enabled", true) and is_mobile():
		Input.vibrate_handheld(clampi(duration_ms, 1, 1000))
