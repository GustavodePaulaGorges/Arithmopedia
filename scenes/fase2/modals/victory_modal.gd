extends Control

func _ready():
	$CenterContainer/Panel/VBoxContainer/OKButton.pressed.connect(_on_ok_button_pressed)

func _on_ok_button_pressed():
	get_tree().paused = false
	ProgressManager.complete_stage(2)
	get_tree().change_scene_to_file("res://scenes/stage_selector/stage_selector.tscn")

func show_modal():
	visible = true
	get_tree().paused = true

func hide_modal():
	visible = false
	get_tree().paused = false
