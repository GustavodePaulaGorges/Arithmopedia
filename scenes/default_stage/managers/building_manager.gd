class_name BuildingManager
extends Node

signal tower_count_updated(tower_count: Dictionary)

@export var addition_tower_scene: PackedScene
@export var subtraction_tower_scene: PackedScene
@export var multiplication_tower_scene: PackedScene
@export var division_tower_scene: PackedScene
@export var potentiation_tower_scene: PackedScene
@export var radication_tower_scene: PackedScene

const IS_BUILDABLE_STR : String = "buildable"
const TOWER_GROUP : String = "TOWER_GROUP"
const GRID_SIZE : int = 16

var tower_count: Dictionary = {}
var towers_path: TileMapLayer = null
var used_tiles : Array[Vector2i] = []
var locked: bool = false

func _ready():
	add_to_group("building_manager")

func setup(p_tower_count: Dictionary) -> void:
	tower_count = p_tower_count.duplicate()
	towers_path = get_tree().get_first_node_in_group("towers_tilemap")
	tower_count_updated.emit(tower_count)

func validate_tower_count(tower_type: TowerTypes.TowerType) -> bool:
	return tower_count.get(tower_type, 0) > 0

func place_tower(cell_position : Vector2i, tower_type: TowerTypes.TowerType) -> void:
	if locked:
		return
	if not check_valid_tower_placement(cell_position):
		return

	var tower_scene: PackedScene
	match tower_type:
		TowerTypes.TowerType.ADDITION:
			tower_scene = addition_tower_scene
		TowerTypes.TowerType.SUBTRACTION:
			tower_scene = subtraction_tower_scene
		TowerTypes.TowerType.MULTIPLICATION:
			tower_scene = multiplication_tower_scene
		TowerTypes.TowerType.DIVISION:
			tower_scene = division_tower_scene
		TowerTypes.TowerType.POTENTIATION:
			tower_scene = potentiation_tower_scene
		TowerTypes.TowerType.RADICATION:
			tower_scene = radication_tower_scene
		_:
			return

	if not validate_tower_count(tower_type):
		return

	var new_tower : TowerEntity = tower_scene.instantiate()
	add_child(new_tower)

	new_tower.position = cell_position * GRID_SIZE
	new_tower.tower_type = tower_type
	new_tower.add_to_group(TOWER_GROUP)

	_connect_tower_to_enemy_manager(new_tower)

	tower_count[tower_type] -= 1
	tower_count_updated.emit(tower_count)
	used_tiles.append(cell_position)

func _connect_tower_to_enemy_manager(tower: TowerEntity) -> void:
	var em: EnemyManager = get_tree().get_first_node_in_group("enemy_manager")
	if em:
		em.register_tower(tower)

func _disconnect_tower_from_enemy_manager(tower: TowerEntity) -> void:
	var em: EnemyManager = get_tree().get_first_node_in_group("enemy_manager")
	if em:
		em.unregister_tower(tower)

func check_valid_tower_placement(cell_position : Vector2i) -> bool :
	if used_tiles.has(cell_position):
		return false
	if not towers_path:
		return false

	var cell_data = towers_path.get_cell_tile_data(cell_position)
	if cell_data == null:
		return false

	return bool(cell_data.get_custom_data(IS_BUILDABLE_STR))

func remove_tower(cell_position : Vector2i) -> void:
	if locked:
		return
	if not check_valid_tower_removal(cell_position):
		return

	var tower_to_remove: TowerEntity = get_tower_at_position(cell_position)
	if tower_to_remove:
		var tower_type = tower_to_remove.tower_type
		_disconnect_tower_from_enemy_manager(tower_to_remove)
		tower_to_remove.remove_from_group(TOWER_GROUP)
		tower_to_remove.queue_free()
		tower_count[tower_type] = tower_count.get(tower_type, 0) + 1
		tower_count_updated.emit(tower_count)
		used_tiles.erase(cell_position)

func check_valid_tower_removal(cell_position : Vector2i) -> bool:
	if not used_tiles.has(cell_position):
		return false
	return get_tower_at_position(cell_position) != null

func get_tower_at_position(cell_position : Vector2i) -> TowerEntity:
	var expected_position = Vector2(cell_position * GRID_SIZE)
	var towers = get_tree().get_nodes_in_group(TOWER_GROUP)

	for tower in towers:
		if tower.position == expected_position:
			return tower

	return null
