extends Control

@onready var main_menu_label = $MainMenuLabel
@onready var stage_info_modal: Control = $HistoryModal
@onready var button_click = $ButtonClick
@onready var button_hover = $ButtonHover
@onready var settings_modal = $SettingsModal

var rotation_speed = 2.0
var max_rotation = 3
var time = 0.0
var cursor = load("res://assets/light_cursor_1.png")
var point = load("res://assets/light_cursor_point.png")

func _ready():
	$VBoxContainer/StartButton.pressed.connect(_on_start_button_pressed)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit_button_pressed)
	
	Input.set_custom_mouse_cursor(cursor)
	Input.set_custom_mouse_cursor(point, Input.CURSOR_POINTING_HAND)
	
	if has_node("/root/ProgressManager"):
		var progress_manager = get_node("/root/ProgressManager")
		
		if (progress_manager.return_completed_stages() == []):
			show_history_modal()

func _process(delta):
	time += delta
	
	var rotation_rad = deg_to_rad(max_rotation * sin(time * rotation_speed))
	main_menu_label.rotation = rotation_rad

func _on_start_button_pressed():
	button_click.play()
	get_tree().change_scene_to_file("res://scenes/stage_selector/stage_selector.tscn")

func _on_quit_button_pressed():
	button_click.play()
	get_tree().quit()
	
func show_history_modal():
	stage_info_modal.show_modal()


func _on_start_button_mouse_entered() -> void:
	button_hover.play()


func _on_quit_button_mouse_entered() -> void:
	button_hover.play()


func _on_settings_button_pressed() -> void:
	button_click.play()
	settings_modal.show_modal()


func _on_settings_button_mouse_entered() -> void:
	button_hover.play()
