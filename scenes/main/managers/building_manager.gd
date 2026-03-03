class_name BuildingManager
extends Node

@export var towers_path : TileMapLayer = null

const IS_BUILDABLE_STR : String = "buildable"
const TOWER_GROUP : String = "TOWER_GROUP"
const GRID_SIZE : int = 16

var used_tiles : Array[Vector2i] = []

func place_tower(cell_position : Vector2i, tower_packed_scene : PackedScene) -> void:
	if check_valid_tower_placement(cell_position) == false:
		return
	
	var new_tower : Node2D = tower_packed_scene.instantiate()
	add_child(new_tower)
	
	new_tower.position = cell_position * GRID_SIZE
	new_tower.add_to_group(TOWER_GROUP)
	used_tiles.append(cell_position)

func check_valid_tower_placement(cell_position : Vector2i) -> bool :
	var is_buildable : bool = false
	if used_tiles.has(cell_position):
		return is_buildable
	
	var cell_data = towers_path.get_cell_tile_data(cell_position)

	if cell_data != null:
		is_buildable = cell_data.get_custom_data(IS_BUILDABLE_STR)

	return is_buildable
