class_name DefaultStage
extends Node2D

@export var stage_data: StageData

@onready var enemy_manager: EnemyManager = $EnemyManager
@onready var building_manager: BuildingManager = $BuildingManager
@onready var victory_modal: Control = $Modals/VictoryModal
@onready var defeat_modal: Control = $Modals/DefeatModal
@onready var stage_info_modal: Control = $Modals/StageInfoModal
@onready var tower_selector: TowerSelector = $UI/TowerSelector
@onready var wave_ui: WaveUI = $UI/WaveUI
@onready var horde_button: Button = $UI/HordeButton

var selected_tower_type: TowerTypes.TowerType = TowerTypes.TowerType.ADDITION
var towers_tilemap: TileMapLayer

func _ready() -> void:
	# Aguarda 1 frame para garantir que os nós da fase irmã (tilemap, spawner,
	# endpoint, path) já entraram na cena e nos seus grupos.
	call_deferred("_initialize")

func _initialize() -> void:
	if stage_data == null:
		push_error("DefaultStage: stage_data não foi atribuído")
		return

	stage_info_modal.set_stage_info(
		stage_data.stage_title,
		stage_data.stage_criteria,
		stage_data.stage_history
	)
	stage_info_modal.show_modal()

	towers_tilemap = get_tree().get_first_node_in_group("towers_tilemap")

	enemy_manager.level_completed.connect(_on_level_completed)
	enemy_manager.level_failed.connect(_on_level_failed)
	enemy_manager.wave_updated.connect(wave_ui.update_wave_display)
	enemy_manager.setup(stage_data)

	building_manager.setup(stage_data.tower_count)

	tower_selector.tower_selected.connect(_on_tower_selected)
	horde_button.pressed.connect(_on_horde_button_pressed)

func _on_level_completed() -> void:
	victory_modal.set_prize_text(stage_data.prize_text)
	victory_modal.show_modal()
	var pm := get_node_or_null("/root/ProgressManager")
	if pm:
		pm.complete_stage(stage_data.stage_id)

func _on_level_failed() -> void:
	defeat_modal.show_modal()

func _on_tower_selected(tower_type: TowerTypes.TowerType) -> void:
	selected_tower_type = tower_type

func _on_horde_button_pressed() -> void:
	enemy_manager.start_wave()
	horde_button.disabled = true
	horde_button.text = "Horda iniciada!"

func _unhandled_input(event: InputEvent) -> void:
	if towers_tilemap == null:
		return

	if event.is_action_pressed("left_mouse"):
		var cell_position : Vector2i = towers_tilemap.local_to_map(towers_tilemap.get_local_mouse_position())
		building_manager.place_tower(cell_position, selected_tower_type)

	if event.is_action_pressed("right_mouse"):
		var cell_position : Vector2i = towers_tilemap.local_to_map(towers_tilemap.get_local_mouse_position())
		building_manager.remove_tower(cell_position)
