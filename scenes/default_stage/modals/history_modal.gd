extends Control

@export var history_data: HistoryData

@onready var next_button: Button = $CenterContainer/Panel/VBoxContainer/NextButton
@onready var title: Label = $CenterContainer/Panel/VBoxContainer/Title
@onready var history: Label = $CenterContainer/Panel/VBoxContainer/History
@onready var image: TextureRect = $CenterContainer/Panel/VBoxContainer/PanelContainer/Image

var current_index = 0

func _ready():
	next_button.pressed.connect(_on_next_button_pressed)
	render_history_page(history_data.pages[current_index])

func _on_next_button_pressed():
	current_index += 1
	
	if (current_index + 1 > history_data.pages.size()):
		hide_modal()
	else:
		render_history_page(history_data.pages[current_index])

func show_modal():
	visible = true

func hide_modal():
	visible = false
	
func render_history_page(page: HistoryPageData):
	if title:
		title.text = page.title
	
	if history:
		history.text = page.history
	
	if image:
		image.texture = page.texture
