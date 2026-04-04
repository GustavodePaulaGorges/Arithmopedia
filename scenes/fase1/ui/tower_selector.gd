class_name TowerSelector
extends Control

signal tower_selected(tower_type: TowerTypes.TowerType)

@onready var hbox_container: HBoxContainer = $HBoxContainer

var selected_tower: TowerTypes.TowerType = TowerTypes.TowerType.ADDITION
var building_manager: BuildingManager1
var tower_count_internal: Dictionary = {}
var tower_buttons = []

# Configuração das torres - facilmente escalável para novas torres
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

func _initialize_tower_buttons():
	# Limpa botões existentes
	for child in hbox_container.get_children():
		child.queue_free()
	
	tower_buttons.clear()

func _ready():
	_initialize_tower_buttons()
	call_deferred("_connect_to_building_manager")
	_update_visual_selection()

func _connect_to_building_manager():
	building_manager = get_tree().get_first_node_in_group("building_manager")
	if building_manager:
		building_manager.tower_count_updated.connect(_on_tower_count_updated)
		_on_tower_count_updated(building_manager.tower_count)

func _on_tower_count_updated(tower_count: Dictionary):
	# Limpa e recria os botões baseado no tower_count
	_initialize_tower_buttons()
	
	for config in tower_configs:
		var tower_type = config.type
		var count = tower_count.get(tower_type, 0)
		
		# Só cria botão se o count for maior que 0
		if count > 0:
			_create_tower_button(config, count)
	
	tower_count_internal = tower_count
	_update_visual_selection()

func _create_tower_button(config: Dictionary, count: int):
	var button = TextureButton.new()
	button.texture_normal = load(config.texture)
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.custom_minimum_size = Vector2(48, 48)
	
	# Cria o label de contagem
	var count_label = Label.new()
	count_label.text = str(count)
	count_label.add_theme_font_override("font", load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf"))
	count_label.add_theme_font_size_override("font_size", 9)
	count_label.position = Vector2(-3, 35)
	
	button.add_child(count_label)
	button.pressed.connect(_on_tower_button_pressed.bind(config.type))
	
	hbox_container.add_child(button)
	tower_buttons.append([button, config.type, count_label])

# Função para adicionar novas torres dinamicamente
func add_tower_config(tower_type: TowerTypes.TowerType, texture_path: String, name: String):
	var new_config = {
		"type": tower_type,
		"texture": texture_path,
		"name": name
	}
	tower_configs.append(new_config)
	
	# Se já tivermos um building_manager conectado, atualiza os botões
	if building_manager:
		_on_tower_count_updated(building_manager.tower_count)

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
