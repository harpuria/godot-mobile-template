## 재사용 가능한 볼륨, 진동 및 언어 설정 UI이다.
class_name SettingsPanel
extends VBoxContainer

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
	language.add_item("English")
	language.add_item("한국어")
	language.selected = 1 if Settings.get_setting("language") == "ko" else 0
	language.item_selected.connect(func(index: int): Settings.set_setting("language", "ko" if index == 1 else "en"))
	add_child(language)
