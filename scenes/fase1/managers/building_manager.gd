class_name BuildingManager
extends Node

@export var towers_path : TileMapLayer = null
@export var level_manager: LevelManager
@export var addition_tower_scene: PackedScene
@export var subtraction_tower_scene: PackedScene

const IS_BUILDABLE_STR : String = "buildable"
const TOWER_GROUP : String = "TOWER_GROUP"
const GRID_SIZE : int = 16

var used_tiles : Array[Vector2i] = []

func place_tower(cell_position : Vector2i, tower_type: TowerTypes.TowerType) -> void:
	if check_valid_tower_placement(cell_position) == false:
		return
	
	var tower_scene: PackedScene
	match tower_type:
		TowerTypes.TowerType.ADDITION:
			tower_scene = addition_tower_scene
		TowerTypes.TowerType.SUBTRACTION:
			tower_scene = subtraction_tower_scene
		_:
			return
	var new_tower : Node2D = tower_scene.instantiate()
	add_child(new_tower)
	
	new_tower.position = cell_position * GRID_SIZE
	new_tower.level_manager = level_manager
	new_tower.add_to_group(TOWER_GROUP)

	connect_tower_to_spawner(new_tower)

	used_tiles.append(cell_position)

func connect_tower_to_spawner(tower: Node2D) -> void:
	var spawner = get_tree().get_first_node_in_group("enemy_spawner")

	if spawner:
		tower.request_spawn_enemy.connect(spawner.spawn_enemy_near_position)

func disconnect_tower_from_spawner(tower: Node2D) -> void:
	var spawner = get_tree().get_first_node_in_group("enemy_spawner")

	if spawner:
		tower.request_spawn_enemy.disconnect(spawner.spawn_enemy_near_position)

func check_valid_tower_placement(cell_position : Vector2i) -> bool :
	var is_buildable : bool = false
	if used_tiles.has(cell_position):
		return is_buildable
	
	var cell_data = towers_path.get_cell_tile_data(cell_position)

	if cell_data != null:
		is_buildable = cell_data.get_custom_data(IS_BUILDABLE_STR)

	return is_buildable

func remove_tower(cell_position : Vector2i) -> void:
	if check_valid_tower_removal(cell_position) == false:
		return
	
	var tower_to_remove = get_tower_at_position(cell_position)
	if tower_to_remove:
		disconnect_tower_from_spawner(tower_to_remove)
		tower_to_remove.remove_from_group(TOWER_GROUP)
		tower_to_remove.queue_free()
		used_tiles.erase(cell_position)

func check_valid_tower_removal(cell_position : Vector2i) -> bool:
	if not used_tiles.has(cell_position):
		return false
	
	var tower = get_tower_at_position(cell_position)
	return tower != null

func get_tower_at_position(cell_position : Vector2i) -> Node2D:
	var expected_position = Vector2(cell_position * GRID_SIZE)
	var towers = get_tree().get_nodes_in_group(TOWER_GROUP)
	
	for tower in towers:
		if tower.position == expected_position:
			return tower
	
	return null
