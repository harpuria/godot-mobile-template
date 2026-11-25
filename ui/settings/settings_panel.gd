## 재사용 가능한 볼륨, 진동 및 언어 설정 UI이다.
class_name SettingsPanel
extends VBoxContainer

## 선택 목록에 표시할 언어 코드와 이름. 게임이 번역을 추가하면 패널 생성 전에 고친다.
static var languages := {"en": "English", "ko": "한국어"}

func _ready() -> void:
	for bus in ["bgm", "sfx", "ui"]:
		var label := Label.new()
		label.text = bus.to_upper() + " Volume"
		add_child(label)
		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.05
		slider.custom_minimum_size.y = 48
		slider.value = float(Settings.get_setting(bus + "_volume", 0.8))
		slider.value_changed.connect(func(value: float): Settings.set_setting(bus + "_volume", value))
		add_child(slider)
	var haptics := CheckButton.new()
	haptics.text = "Haptics"
	haptics.custom_minimum_size.y = 52
	haptics.button_pressed = bool(Settings.get_setting("haptics_enabled", true))
	haptics.toggled.connect(func(value: bool): Settings.set_setting("haptics_enabled", value))
	add_child(haptics)
	var language := OptionButton.new()
	language.custom_minimum_size.y = 52
	# 첫 항목(빈 값)은 기기 언어를 따른다.
	var codes := [""]
	language.add_item("System")
	for code in languages:
		codes.append(code)
		language.add_item(languages[code])
	language.selected = maxi(0, codes.find(str(Settings.get_setting("language", ""))))
	language.item_selected.connect(func(index: int): Settings.set_setting("language", codes[index]))
	add_child(language)
