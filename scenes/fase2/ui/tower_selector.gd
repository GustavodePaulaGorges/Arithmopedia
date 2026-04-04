class_name TowerSelector2
extends Control

signal tower_selected(tower_type: TowerTypes.TowerType)

@onready var tower1_aspect = $HBoxContainer/Tower1Container/MarginContainer/AspectRatioContainer
@onready var tower2_aspect = $HBoxContainer/Tower2Container/MarginContainer/AspectRatioContainer
@onready var tower1_container = $HBoxContainer/Tower1Container
@onready var tower2_container = $HBoxContainer/Tower2Container

var selected_tower: TowerTypes.TowerType = TowerTypes.TowerType.ADDITION
var building_manager: BuildingManager2
var tower_count_internal: Dictionary = {}
var tower_buttons = []

# Configuração das torres
var tower_configs = [
	{
		"type": TowerTypes.TowerType.ADDITION,
		"texture": "res://assets/sprites/TorreAdd.png",
		"name": "Addition"
	},
	{
		"type": TowerTypes.TowerType.SUBTRACTION,
		"texture": "res://assets/sprites/TorreSub.png",
		"name": "Subtraction"
	}
]

func _ready():
	call_deferred("_connect_to_building_manager")
	_update_visual_selection()

func _connect_to_building_manager():
	building_manager = get_tree().get_first_node_in_group("building_manager")
	if building_manager:
		building_manager.tower_count_updated.connect(_on_tower_count_updated)
		_on_tower_count_updated(building_manager.tower_count)

func _on_tower_count_updated(tower_count: Dictionary):
	# Limpa containers anteriores
	for child in tower1_aspect.get_children():
		child.queue_free()
	for child in tower2_aspect.get_children():
		child.queue_free()
	
	tower_buttons.clear()
	
	# Cria botão para Addition se disponível
	var add_count = tower_count.get(TowerTypes.TowerType.ADDITION, 0)
	if add_count > 0:
		_create_tower_button(tower1_aspect, tower_configs[0], add_count)
	
	# Cria botão para Subtraction se disponível
	var sub_count = tower_count.get(TowerTypes.TowerType.SUBTRACTION, 0)
	if sub_count > 0:
		_create_tower_button(tower2_aspect, tower_configs[1], sub_count)
	
	tower_count_internal = tower_count
	_update_visual_selection()

func _create_tower_button(aspect_container: AspectRatioContainer, config: Dictionary, count: int):
	var button = TextureButton.new()
	button.texture_normal = load(config.texture)
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_COVERED
	button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Cria o label de contagem
	var count_label = Label.new()
	count_label.text = str(count)
	count_label.add_theme_font_override("font", load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf"))
	count_label.add_theme_font_size_override("font_size", 9)
	count_label.position = Vector2(-3, 35)
	
	button.add_child(count_label)
	button.pressed.connect(_on_tower_button_pressed.bind(config.type))
	
	aspect_container.add_child(button)
	
	# Guarda referência para seleção visual
	var container = aspect_container.get_parent().get_parent()
	tower_buttons.append([container, config.type, count_label])

func _on_tower_button_pressed(tower_type: TowerTypes.TowerType):
	selected_tower = tower_type
	_update_visual_selection()
	tower_selected.emit(selected_tower)

func _update_visual_selection():
	for button_data in tower_buttons:
		var container = button_data[0]
		container.modulate = Color.WHITE
		
		# Remove outline do botão se existir
		var aspect_container = container.get_child(0).get_child(0)
		if aspect_container.get_child_count() > 0:
			var texture_button = aspect_container.get_child(0)
			texture_button.add_theme_color_override("outline_color", Color.TRANSPARENT)
			texture_button.add_theme_constant_override("outline_size", 0)
	
	for button_data in tower_buttons:
		if button_data[1] == selected_tower:
			if (tower_count_internal.get(selected_tower, 0) == 0):
				button_data[0].modulate = Color(1.468, 0.0, 0.0, 1.0)
			else:
				button_data[0].modulate = Color(1.892, 1.892, 1.892, 1.0)
			break
