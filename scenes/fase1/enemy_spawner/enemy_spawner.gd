class_name EnemySpawner
extends Node2D

signal spawning_phase_complete
signal wave_updated(wave_data_array: Array[int], current_data_index: int)

@export var wave_data_array : Array[int] = []
@export var path2D : Path2D
@export var enemy_scene : PackedScene
@export var level_manager: LevelManager

@onready var enemy_spawn_timer: Timer = $EnemySpawnTimer

const DEFAULT_SPAWN_DELAY : float = 1.0

var current_data_index : int = 0

func _ready() -> void:
	add_to_group("enemy_spawner")

	enemy_spawn_timer.wait_time = DEFAULT_SPAWN_DELAY
	
	wave_updated.emit(wave_data_array, current_data_index)


func start_spawning() -> void:
	if not enemy_spawn_timer.is_stopped():
		return
	
	enemy_spawn_timer.start()


func spawn_entity() -> void:
	if current_data_index >= wave_data_array.size():
		enemy_spawn_timer.stop()
		spawning_phase_complete.emit()
		if level_manager:
			level_manager.on_spawner_finished()
		return

	spawn_enemy_at_ratio(0.0, wave_data_array[current_data_index])


func spawn_enemy_at_ratio(ratio: float, value: int, creator_tower: TowerEntity = null) -> void:
	var path_follow := PathFollow2D.new()
	path_follow.loop = false
	path_follow.rotates = false

	path2D.add_child(path_follow)

	path_follow.progress_ratio = ratio

	var new_enemy = enemy_scene.instantiate()
	new_enemy.value = value
	new_enemy.creator_tower = creator_tower

	path_follow.add_child(new_enemy)
	level_manager.increment_active_enemies()


func spawn_enemy_near_position(ratio: float, value: int, creator_tower: TowerEntity = null) -> void:
	spawn_enemy_at_ratio(ratio, value, creator_tower) 


func _on_enemy_spawn_timer_timeout() -> void:
	spawn_entity()
	current_data_index += 1
	wave_updated.emit(wave_data_array, current_data_index)
