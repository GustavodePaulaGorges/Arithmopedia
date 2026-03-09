extends Control

func _ready():
	$CenterContainer/Panel/VBoxContainer/OKButton.pressed.connect(_on_ok_button_pressed)

func _on_ok_button_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func show_modal():
	visible = true
	get_tree().paused = true

func hide_modal():
	visible = false
	get_tree().paused = false
