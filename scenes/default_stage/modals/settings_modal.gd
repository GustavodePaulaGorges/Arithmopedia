extends Control

@onready var volume_slider: HSlider = $MarginContainer/VBoxContainer/Volume
@onready var mute_check_box: CheckBox = $MarginContainer/VBoxContainer/CheckBox
@onready var button_click = $ButtonClick
@onready var button_hover = $ButtonHover

const MASTER_BUS := 0
const MAX_SLIDER_VALUE := 10.0

const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(304, 224),    # 1x
	Vector2i(608, 448),    # 2x
	Vector2i(912, 672),    # 3x
	Vector2i(1216, 896),   # 4x
	Vector2i(1520, 1120),  # 5x
	Vector2i(1824, 1344),  # 6x
]

func _ready() -> void:
	volume_slider.min_value = 0
	volume_slider.max_value = MAX_SLIDER_VALUE

	var current_volume_linear := AudioServer.get_bus_volume_linear(MASTER_BUS)
	var slider_value := current_volume_linear * MAX_SLIDER_VALUE

	volume_slider.set_value_no_signal(slider_value)
	mute_check_box.button_pressed = AudioServer.is_bus_mute(MASTER_BUS)


func _on_volume_value_changed(value: float) -> void:
	var volume_percent := value / MAX_SLIDER_VALUE

	if volume_percent <= 0.0:
		AudioServer.set_bus_mute(MASTER_BUS, true)
	else:
		AudioServer.set_bus_mute(MASTER_BUS, false)
		AudioServer.set_bus_volume_db(MASTER_BUS, linear_to_db(volume_percent))

func show_modal():
	visible = true

func hide_modal():
	visible = false

func _on_check_box_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(MASTER_BUS, toggled_on)


func _on_close_button_pressed() -> void:
	button_click.play()
	hide_modal()


func _on_close_button_mouse_entered() -> void:
	button_hover.play()

func _on_resolutions_item_selected(index: int) -> void:
	if index < 0 or index >= RESOLUTIONS.size():
		return

	DisplayServer.window_set_size(RESOLUTIONS[index])


func _on_return_button_pressed() -> void:
	button_click.play()
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")


func _on_return_button_mouse_entered() -> void:
	button_hover.play()
