extends Control

@onready var hint_text: Label = $CenterContainer/Panel/VBoxContainer/HintText
@onready var ok_button: Button = $CenterContainer/Panel/VBoxContainer/OKButton
@onready var button_click = $ButtonClick
@onready var button_hover = $ButtonHover


func _ready():
	ok_button.pressed.connect(_on_ok_button_pressed)

func _on_ok_button_pressed():
	button_click.play()
	hide_modal()

func show_modal():
	visible = true
	get_tree().paused = true

func hide_modal():
	visible = false
	get_tree().paused = false

func set_stage_info(hint: String):
	if hint_text:
		hint_text.text = hint

func _on_ok_button_mouse_entered() -> void:
	button_hover.play()
