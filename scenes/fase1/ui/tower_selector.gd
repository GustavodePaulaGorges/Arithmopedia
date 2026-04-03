class_name TowerSelector
extends Control

signal tower_selected(tower_type: TowerTypes.TowerType)

@onready var addition_button: TextureButton = $HBoxContainer/AdditionButton
@onready var subtraction_button: TextureButton = $HBoxContainer/SubtractionButton
@onready var addition_count_label: Label = $HBoxContainer/AdditionButton/CountLabel
@onready var subtraction_count_label: Label = $HBoxContainer/SubtractionButton/CountLabel

var selected_tower: TowerTypes.TowerType = TowerTypes.TowerType.ADDITION
var building_manager: BuildingManager
var tower_count_internal: Dictionary = {}
var tower_buttons = []

func _initialize_tower_buttons():
	tower_buttons = [
		[addition_button, TowerTypes.TowerType.ADDITION, addition_count_label],
		[subtraction_button, TowerTypes.TowerType.SUBTRACTION, subtraction_count_label]
	]

func _ready():
	_initialize_tower_buttons()

	for button in tower_buttons:
		button[0].pressed.connect(_on_tower_button_pressed.bind(button[1]))

	call_deferred("_connect_to_building_manager")
	_update_visual_selection()

func _connect_to_building_manager():
	building_manager = get_tree().get_first_node_in_group("building_manager")
	if building_manager:
		building_manager.tower_count_updated.connect(_on_tower_count_updated)
		_on_tower_count_updated(building_manager.tower_count)

func _on_tower_count_updated(tower_count: Dictionary):
	for button in tower_buttons:
		button[2].text = str(tower_count.get(button[1], 0))

	tower_count_internal = tower_count
	_update_visual_selection()

func _on_tower_button_pressed(tower_type: TowerTypes.TowerType):
	selected_tower = tower_type
	_update_visual_selection()
	tower_selected.emit(selected_tower)

func _update_visual_selection():
	for button in tower_buttons:
		button[0].modulate = Color.WHITE
		button[0].add_theme_color_override("outline_color", Color.TRANSPARENT)
		button[0].add_theme_constant_override("outline_size", 0)
	
	for button in tower_buttons:
		if button[1] == selected_tower:
			if (tower_count_internal.get(selected_tower, 0) == 0):
				button[0].modulate = Color(1.468, 0.0, 0.0, 1.0)
			else:
				button[0].modulate = Color(1.892, 1.892, 1.892, 1.0)
			break
