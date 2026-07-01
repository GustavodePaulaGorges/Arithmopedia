extends Control

@onready var title_label: Label = $CenterContainer/Panel/VBoxContainer/TitleLabel
@onready var criteria_label: Label = $CenterContainer/Panel/VBoxContainer/CriteriaLabel
@onready var history_label: Label = $CenterContainer/Panel/VBoxContainer/HistoryLabel
@onready var start_button: Button = $CenterContainer/Panel/VBoxContainer/StartButton
@onready var button_click = $ButtonClick
@onready var button_hover = $ButtonHover

func _ready():
	start_button.pressed.connect(_on_start_button_pressed)

func _on_start_button_pressed():
	button_click.play()
	hide_modal()

func _on_start_button_mouse_entered() -> void:
	button_hover.play()

func show_modal():
	visible = true
	get_tree().paused = true

func hide_modal():
	visible = false
	get_tree().paused = false

func set_stage_info(title: String, criteria: String, history: String):
	if title_label:
		title_label.text = title
	if criteria_label:
		criteria_label.text = criteria
	if history_label:
		history_label.text = history
