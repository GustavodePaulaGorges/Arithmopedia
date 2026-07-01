class_name WaveUI
extends Control

@onready var wave_label: RichTextLabel = $MarginContainer/WaveLabel
@onready var background: Panel = $Background
@onready var margin_container: MarginContainer = $MarginContainer
@onready var toggle_button: Button = $ToggleButton
@onready var button_click = $ButtonClick
@onready var button_hover = $ButtonHover

func _ready() -> void:
	toggle_button.toggled.connect(_on_toggle_button_toggled)

func _on_toggle_button_toggled(button_pressed: bool) -> void:
	button_click.play()
	var collapsed := button_pressed
	background.visible = not collapsed
	margin_container.visible = not collapsed
	toggle_button.text = "+" if collapsed else "-"
	mouse_filter = Control.MOUSE_FILTER_IGNORE if collapsed else Control.MOUSE_FILTER_STOP

func _on_toggle_button_mouse_entered() -> void:
	button_hover.play()

func update_wave_display(wave_data_array: Array[int], current_data_index: int) -> void:
	wave_label.text = _format_line("horda", wave_data_array, current_data_index)

func update_wave_display_dual(
		upper_array: Array[int], upper_index: int,
		lower_array: Array[int], lower_index: int) -> void:
	var upper_line := _format_line("superior", upper_array, upper_index)
	var lower_line := _format_line("inferior", lower_array, lower_index)
	wave_label.text = upper_line + "\n" + lower_line

func _format_line(label: String, arr: Array[int], current_index: int) -> String:
	if arr.is_empty():
		return label + ":\n[]"
	var formatted_text := label + ":\n["
	for i in range(arr.size()):
		var enemy_value = arr[i]
		if i == current_index and i < arr.size():
			formatted_text += "[color=red]" + str(enemy_value) + "[/color]"
		else:
			formatted_text += str(enemy_value)
		if i < arr.size() - 1:
			formatted_text += ", "
	formatted_text += "]"
	return formatted_text
