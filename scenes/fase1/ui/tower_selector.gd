class_name TowerSelector
extends Control

signal tower_selected(tower_type: TowerTypes.TowerType)

@onready var addition_button: TextureButton = $HBoxContainer/AdditionButton
@onready var subtraction_button: TextureButton = $HBoxContainer/SubtractionButton

var selected_tower: TowerTypes.TowerType = TowerTypes.TowerType.ADDITION

func _ready():
	addition_button.pressed.connect(_on_addition_button_pressed)
	subtraction_button.pressed.connect(_on_subtraction_button_pressed)
	
	_update_visual_selection()

func _on_addition_button_pressed():
	selected_tower = TowerTypes.TowerType.ADDITION
	_update_visual_selection()
	tower_selected.emit(selected_tower)

func _on_subtraction_button_pressed():
	selected_tower = TowerTypes.TowerType.SUBTRACTION
	_update_visual_selection()
	tower_selected.emit(selected_tower)

func _update_visual_selection():
	addition_button.modulate = Color.WHITE
	subtraction_button.modulate = Color.WHITE
	
	match selected_tower:
		TowerTypes.TowerType.ADDITION:
			addition_button.modulate = Color.RED
		TowerTypes.TowerType.SUBTRACTION:
			subtraction_button.modulate = Color.RED
