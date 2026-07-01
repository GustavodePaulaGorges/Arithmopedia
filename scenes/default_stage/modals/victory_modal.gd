extends Control

@onready var prize_label: Label = $CenterContainer/Panel/VBoxContainer/PrizeLabel
@onready var button_click = $ButtonClick
@onready var button_hover = $ButtonHover

func _ready():
	$CenterContainer/Panel/VBoxContainer/OKButton.pressed.connect(_on_ok_button_pressed)

func _on_ok_button_pressed():
	button_click.play()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/stage_selector/stage_selector.tscn")

func _on_ok_button_mouse_entered() -> void:
	button_hover.play()

func show_modal():
	visible = true
	get_tree().paused = true

func hide_modal():
	visible = false
	get_tree().paused = false

func set_prize_text(text: String):
	prize_label.text = text
