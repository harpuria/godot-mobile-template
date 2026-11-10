## 저장 load 실패 시 다시 시도 또는 새로 시작을 고르게 하는 기본 복구 팝업이다.
## bootstrap이 첫 장면 진입 전에 표시한다. `[save] recovery_popup=false`면 게임이 직접 처리한다.
class_name SaveRecoveryPopup
extends CanvasLayer

## 사용자가 복구를 마쳤을 때 "retried" 또는 "reset"을 전달한다.
signal resolved(action: String)

## 번역 키 → 번역이 없을 때 쓰는 기본 문구. 게임 번역에 같은 키를 추가하면 대체된다.
const TEXTS := {
	"SAVE_RECOVERY_MESSAGE": "Your save data could not be loaded.",
	"SAVE_RECOVERY_RETRY": "Try again",
	"SAVE_RECOVERY_RESET": "Start new game",
	"SAVE_RECOVERY_CONFIRM": "Tap again to erase progress",
	"SAVE_RECOVERY_RETRY_FAILED": "Still unable to load the save data.",
	"SAVE_RECOVERY_RESET_FAILED": "Could not write new save data.",
}

var message := Label.new()
var retry_button := Button.new()
var reset_button := Button.new()
var _reset_armed := false

func _ready() -> void:
	layer = 110
	process_mode = Node.PROCESS_MODE_ALWAYS
	var background := ColorRect.new()
	background.color = Color(0.035, 0.05, 0.08, 1.0)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var safe := SafeArea.new()
	safe.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.add_child(safe)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 24)
	safe.add_child(box)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.text = _text("SAVE_RECOVERY_MESSAGE")
	box.add_child(message)
	for button in [retry_button, reset_button]:
		button.custom_minimum_size.y = 72
		box.add_child(button)
	retry_button.text = _text("SAVE_RECOVERY_RETRY")
	reset_button.text = _text("SAVE_RECOVERY_RESET")
	retry_button.pressed.connect(retry)
	reset_button.pressed.connect(request_reset)

## 저장을 다시 읽는다. 성공하면 닫고, 실패하면 팝업을 유지한다.
func retry() -> void:
	_disarm()
	if SaveManager.load_slot() == OK:
		_finish("retried")
	else:
		message.text = _text("SAVE_RECOVERY_RETRY_FAILED")

## 첫 호출은 확인 문구만 표시하고, 연속 두 번째 호출에서 새 저장으로 교체한다.
## 읽지 못한 원본은 SaveManager가 `.unreadable`로 보관한다.
func request_reset() -> void:
	if not _reset_armed:
		_reset_armed = true
		reset_button.text = _text("SAVE_RECOVERY_CONFIRM")
		return
	SaveManager.reset_slot()
	if SaveManager.save_slot() == OK:
		_finish("reset")
		return
	SaveManager.write_blocked = true
	_disarm()
	message.text = _text("SAVE_RECOVERY_RESET_FAILED")

func _disarm() -> void:
	_reset_armed = false
	reset_button.text = _text("SAVE_RECOVERY_RESET")

func _finish(action: String) -> void:
	resolved.emit(action)
	queue_free()

func _text(key: String) -> String:
	var translated := tr(key)
	return TEXTS[key] if translated == key else translated
