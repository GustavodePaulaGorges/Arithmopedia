class_name Stage2
extends Node2D

@export var addition_tower_scene : PackedScene = null
@export var subtraction_tower_scene : PackedScene = null
@export var building_manager : BuildingManager2 = null
@export var level_manager: LevelManager2 = null
@export var enemy_spawner: EnemySpawner2 = null
@onready var towers_path: TileMapLayer = $TowersPath
@onready var victory_modal: Control = $VictoryModal
@onready var defeat_modal: Control = $DefeatModal
@onready var stage_info_modal: Control = $StageInfoModal
@onready var tower_selector: TowerSelector2 = $UI/TowerSelector
@onready var wave_ui: WaveUI2 = $UI/WaveUI
@onready var horde_button: Button = $UI/HordeButton

## Variaveis da fase
var selected_tower_type: TowerTypes.TowerType = TowerTypes.TowerType.ADDITION
var tower_count = {
	TowerTypes.TowerType.ADDITION: 1,
	TowerTypes.TowerType.SUBTRACTION: 1
}
var enemy_array : Array[int] = [10, 8, 3, 2]
var victory_condition = LevelManager2.VictoryCondition.new(
	LevelManager2.VictoryType.ALL_LESS_THAN, 
	10
)
var stage_title: String = "Fase 2 (A arte de fazer menos)"
var stage_criteria: String = "Fazer um número menor que 10"
var stage_history: String = "A trilha adiante leva Pitáclides a um vale onde os números ecoam como montanhas: grandes demais, pesados demais, desbalanceados demais. O Khaos distorceu suas proporções, e agora eles não cabem mais no caminho estreito que leva ao próximo capítulo da Arithmopedia."
var prize_text: String = "A subtração não segue as mesmas propriedades da adição: ela não é comutativa (a − b ≠ b − a na maior parte dos casos) e também não é associativa, isto é, (a − b) − c geralmente produz algo diferente de a − (b − c). É por isso que, em situações onde operações aparecem em sequência, a ordem altera profundamente o resultado. Essa é uma das primeiras lições sobre operações mistas, é exatamente o tipo de princípio que Pitáclides domina melhor do que qualquer outro mago de Mathemas."

func _ready():
	stage_info_modal.set_stage_info(stage_title, stage_criteria, stage_history)
	stage_info_modal.show_modal()
	
	if level_manager and enemy_spawner:
		level_manager.setup_level(enemy_array, victory_condition)
		
		level_manager.level_completed.connect(_on_level_completed)
		level_manager.level_failed.connect(_on_level_failed)
		
		enemy_spawner.wave_data_array = level_manager.get_enemy_data()
		
		# Atualiza a UI da horda imediatamente para mostrar os valores antes de iniciar
		enemy_spawner.wave_updated.emit(enemy_spawner.wave_data_array, enemy_spawner.current_data_index)

		enemy_spawner.wave_updated.connect(wave_ui.update_wave_display)
	else:
		print("ERRO: Level manager ou enemy_spawner não encontrados")
	
	if building_manager and towers_path:
		building_manager.towers_path = towers_path
		building_manager.addition_tower_scene = addition_tower_scene
		building_manager.subtraction_tower_scene = subtraction_tower_scene
		building_manager.tower_count = tower_count
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
	print("=== FASE 2 COMPLETADA ===")
	victory_modal.set_prize_text(prize_text)
	victory_modal.show_modal()
	ProgressManager.complete_stage(2)

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
		
	if event.is_action_pressed("right_mouse"):
		if not towers_path:
			print("ERRO: towers_path não encontrado")
			return
			
		var cell_position : Vector2i = towers_path.local_to_map(towers_path.get_local_mouse_position())
	
		if not building_manager:
			return
			
		building_manager.remove_tower(cell_position)

func _on_tower_selected(tower_type: TowerTypes.TowerType):
	selected_tower_type = tower_type

func _on_horde_button_pressed():
	if enemy_spawner:
		enemy_spawner.start_spawning()
		horde_button.disabled = true
		horde_button.text = "Horda iniciada!"
