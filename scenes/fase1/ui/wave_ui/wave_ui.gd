class_name WaveUI
extends Control

@onready var wave_label: RichTextLabel = $WaveLabel

func update_wave_display(wave_data_array: Array[int], current_data_index: int) -> void:
	if wave_data_array.is_empty():
		wave_label.text = "horda:\n[]"
		return
	
	var formatted_text = "horda:\n["
	for i in range(wave_data_array.size()):
		var enemy_value = wave_data_array[i]
		if i == current_data_index and i < wave_data_array.size():
			formatted_text += "[color=red]" + str(enemy_value) + "[/color]"
		else:
			formatted_text += str(enemy_value)
		
		if i < wave_data_array.size() - 1:
			formatted_text += ", "
	
	formatted_text += "]"
	wave_label.text = formatted_text
