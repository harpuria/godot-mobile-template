## Android JNI 메서드와 신호 계약을 검사한다. SDK 인스턴스의 소유권은 각 어댑터에 있다.
class_name AndroidPlugin
extends RefCounted

## Godot JNI 메서드는 일반 Object 메서드 목록과 별도로 조회한다.
static func supports(candidate: Object, method: String) -> bool:
	if not is_instance_valid(candidate):
		return false
	if candidate.has_method("has_java_method"):
		return bool(candidate.call("has_java_method", method))
	return candidate.has_method(method)

## 플랫폼과 전체 API 계약이 맞을 때만 native singleton을 반환한다.
static func find_plugin(plugin_name: String, methods: Array, events: Array) -> Object:
	if OS.get_name() != "Android" or not Engine.has_singleton(plugin_name):
		return null
	var candidate := Engine.get_singleton(plugin_name)
	return candidate if matches(candidate, methods, events) else null

## 가짜 SDK 검사에서도 같은 메서드·신호 검사를 사용한다.
static func matches(candidate: Object, methods: Array, events: Array) -> bool:
	if not is_instance_valid(candidate):
		return false
	for method in methods:
		if not supports(candidate, str(method)):
			return false
	for event in events:
		if not candidate.has_signal(str(event)):
			return false
	return true
