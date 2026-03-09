extends Control

@onready var main_menu_label = $MainMenuLabel
var rotation_speed = 2.0
var max_rotation = 3
var time = 0.0

func _ready():
	$VBoxContainer/StartButton.pressed.connect(_on_start_button_pressed)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit_button_pressed)

func _process(delta):
	time += delta
	
	var rotation_rad = deg_to_rad(max_rotation * sin(time * rotation_speed))
	main_menu_label.rotation = rotation_rad

func _on_start_button_pressed():
	get_tree().change_scene_to_file("res://scenes/fase1/fase1.tscn")

func _on_quit_button_pressed():
	get_tree().quit()
