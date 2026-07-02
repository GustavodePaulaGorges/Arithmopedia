extends Control

@export var dialogue_data: DialogueData

@onready var character_name: Label = $OuterMargin/VBoxContainer/DialoguePanel/ContentMargin/HBoxContainer/TextContainer/CharacterName
@onready var history: Label = $OuterMargin/VBoxContainer/DialoguePanel/ContentMargin/HBoxContainer/TextContainer/History
@onready var image: TextureRect = $OuterMargin/VBoxContainer/DialoguePanel/ContentMargin/HBoxContainer/PortraitFrame/Image
@onready var button_click = $ButtonClick
@onready var button_hover = $ButtonHover

var current_index: int = 0

func _ready() -> void:
	render_current_dialogue()

func show_modal():
	visible = true

func hide_modal():
	visible = false

func render_current_dialogue() -> void:
	if dialogue_data == null:
		return

	if dialogue_data.dialogue_list.is_empty():
		return

	if current_index < 0 or current_index >= dialogue_data.dialogue_list.size():
		return

	var item: DialogueItem = dialogue_data.dialogue_list[current_index]

	character_name.text = item.char_name
	history.text = item.text
	image.texture = item.texture
	
func next_dialogue() -> void:
	if dialogue_data == null:
		return

	current_index += 1

	if current_index >= dialogue_data.dialogue_list.size():
		hide_modal()
		return

	render_current_dialogue()

func _on_button_pressed() -> void:
	button_click.play()
	next_dialogue()

func _on_button_mouse_entered() -> void:
	button_hover.play()
