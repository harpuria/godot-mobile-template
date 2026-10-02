## 게임 초기화 hook 호출을 기록하는 통합 검사용 fixture이다.
extends RefCounted

static var calls := 0

## bootstrap이 App.initialize() 전에 호출하는 hook이다.
func before_app_initialize() -> void:
	calls += 1
