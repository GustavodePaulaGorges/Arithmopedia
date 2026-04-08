class_name Stage1
extends Node2D

@export var addition_tower_scene : PackedScene = null
@export var subtraction_tower_scene : PackedScene = null
@export var building_manager : BuildingManager1 = null
@export var level_manager: LevelManager = null
@export var enemy_spawner: EnemySpawner = null
@onready var towers_path: TileMapLayer = $TowersPath
@onready var victory_modal: Control = $VictoryModal
@onready var defeat_modal: Control = $DefeatModal
@onready var stage_info_modal: Control = $StageInfoModal
@onready var tower_selector: TowerSelector = $UI/TowerSelector
@onready var wave_ui: WaveUI = $UI/WaveUI
@onready var horde_button: Button = $UI/HordeButton

## Variaveis da fase
var selected_tower_type: TowerTypes.TowerType = TowerTypes.TowerType.ADDITION
var tower_count = {
	TowerTypes.TowerType.ADDITION: 1
}
var enemy_array : Array[int] = [3, 4, 5, 6, 7, 8]
var victory_condition = LevelManager.VictoryCondition.new(
	LevelManager.VictoryType.ALL_GREATER_THAN, 
	6
)
var stage_title: String = "Tutorial/Fase 1 (Começando a aventura)"
var stage_criteria: String = "Fazer números maiores que 6"
var stage_history: String = "Após o roubo da Arithmopedia, os primeiros números fugitivos escaparam pela ponte de Mathemas. Eles são pequenos e inofensivos, mas ainda seguem uma lógica, por enquanto.\nPitáclides, o único mago imune ao Khaos, precisa começar a organizar esses números.\nDe repente, ele se lembra da torre somatória, uma de suas antigas magias que reage à harmonia dos pares."
var prize_text: String = "A soma é comutativa e associativa, isto é, a ordem dos termos não altera o resultado final nem a forma como você os agrupa. Num sentido prático para esta fase: somar 3+4 ou 4+3 dá o mesmo 7; mas como as torres consomem pares sequenciais, a posição importa para a jogabilidade mesmo quando a operação matemática em si é indiferente à ordem."

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
	print("=== FASE 1 COMPLETADA ===")
	victory_modal.set_prize_text(prize_text)
	victory_modal.show_modal()
	ProgressManager.complete_stage(1) 

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
