## RefCounted가 아닌 게임 초기화 script를 거절하는지 확인하는 fixture이다.
extends Node

## 호출되면 안 되는 hook이다.
func before_app_initialize() -> void:
	pass
