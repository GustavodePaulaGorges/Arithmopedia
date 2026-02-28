class_name EnemyEntity
extends CharacterBody2D

@export var movement_speed : float = 200
@export var path_finding_manager : PathfindingManager = null
@export var target_pos : Marker2D = null

var path_array : Array[Vector2i] = []

func _ready() -> void:
	print(path_finding_manager)
	path_array = path_finding_manager.get_valid_path(global_position / 16, target_pos.position / 16)
	print("PATH:", path_array)

func _physics_process(delta: float) -> void:
	get_path_to_postion()
	move_and_slide()

func get_path_to_postion() -> void:
	if path_array.is_empty():
		velocity = Vector2.ZERO
		return

	var target_position : Vector2 = path_array[0]
	var distance : float = global_position.distance_to(target_position)
	var step : float = movement_speed * get_process_delta_time()

	if distance <= step:
		global_position = target_position
		path_array.remove_at(0)
		velocity = Vector2.ZERO
	else:
		var direction : Vector2 = global_position.direction_to(target_position)
		velocity = direction * movement_speed
