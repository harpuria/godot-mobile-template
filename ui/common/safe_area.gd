## 모바일 화면의 안전 영역을 Control 좌표로 변환하여 콘텐츠 여백에 반영한다.
class_name SafeArea
extends MarginContainer

func _ready() -> void:
	get_viewport().size_changed.connect(update_margins)
	update_margins.call_deferred()

## 노치와 화면 회전에 맞춰 여백을 갱신한다. 데스크톱은 기본 여백만 적용한다.
func update_margins() -> void:
	var margins := [16, 16, 16, 16]
	if MobilePlatform.is_mobile():
		var safe := DisplayServer.get_display_safe_area()
		var screen := DisplayServer.screen_get_size()
		var viewport := get_viewport_rect().size
		if screen.x > 0 and screen.y > 0 and safe.size.x > 0 and safe.size.y > 0:
			var scale := viewport / Vector2(screen)
			margins = [int(safe.position.x * scale.x) + 16, int(safe.position.y * scale.y) + 16,
				int((screen.x - safe.end.x) * scale.x) + 16, int((screen.y - safe.end.y) * scale.y) + 16]
	for i in range(4):
		add_theme_constant_override(["margin_left", "margin_top", "margin_right", "margin_bottom"][i], maxi(16, margins[i]))
