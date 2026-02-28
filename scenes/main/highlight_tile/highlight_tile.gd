class_name HighlightTile

extends Node2D

const GRID_SIZE : int = 16

func _process(delta: float) -> void:
	follow_mouse_position()

func follow_mouse_position() -> void:
	var mouse_position : Vector2i = get_global_mouse_position() / GRID_SIZE
	
	position = mouse_position * GRID_SIZE
