class_name Stage1
extends Node2D

@export var addition_tower_scene : PackedScene = null
@export var subtraction_tower_scene : PackedScene = null
@export var building_manager : BuildingManager = null
@export var level_manager: LevelManager = null
@export var enemy_spawner: EnemySpawner = null
@onready var towers_path: TileMapLayer = $TowersPath
@onready var victory_modal: Control = $VictoryModal
@onready var defeat_modal: Control = $DefeatModal
@onready var tower_selector: TowerSelector = $UI/TowerSelector
@onready var horde_button: Button = $UI/HordeButton

var selected_tower_type: TowerTypes.TowerType = TowerTypes.TowerType.ADDITION

func _ready():
	if level_manager and enemy_spawner:
		var enemy_array: Array[int] = [10, 8, 3, 2]
		var victory_condition = LevelManager.VictoryCondition.new(
			LevelManager.VictoryType.ALL_GREATER_THAN, 
			10
		)
		level_manager.setup_level(enemy_array, victory_condition)
		
		level_manager.level_completed.connect(_on_level_completed)
		level_manager.level_failed.connect(_on_level_failed)
		
		enemy_spawner.wave_data_array = level_manager.get_enemy_data()
	else:
		print("ERRO: Level manager ou enemy_spawner não encontrados")
	
	if building_manager and towers_path:
		building_manager.towers_path = towers_path
		building_manager.addition_tower_scene = addition_tower_scene
		building_manager.subtraction_tower_scene = subtraction_tower_scene
	else:
		print("ERRO: Building manager ou towers_path não encontrados")
		if not building_manager:
			print("Building manager é null")
		if not towers_path:
			print("Towers path é null")
	
	if tower_selector:
		tower_selector.tower_selected.connect(_on_tower_selected)
	
	if horde_button:
		horde_button.pressed.connect(_on_horde_button_pressed)

func _on_level_completed():
	victory_modal.show_modal()

func _on_level_failed():
	defeat_modal.show_modal()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_mouse"):
		if not towers_path:
			print("ERRO: towers_path não encontrado")
			return
			
		var cell_position : Vector2i = towers_path.local_to_map(towers_path.get_local_mouse_position())
	
		if not building_manager:
			return
			
		building_manager.place_tower(cell_position, selected_tower_type)

func _on_tower_selected(tower_type: TowerTypes.TowerType):
	selected_tower_type = tower_type

func _on_horde_button_pressed():
	if enemy_spawner:
		enemy_spawner.start_spawning()
		horde_button.disabled = true
		horde_button.text = "Horda iniciada!"
