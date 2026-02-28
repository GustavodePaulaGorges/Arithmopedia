class_name EnemySpawner
extends Node2D

signal spawning_phase_complete

@export var wave_data_array : Array = ["Enemy 1", "Enemy2", "Enemy3", "Enemy4"]
@export var path2D : Path2D
@onready var enemy_container = $EnemyContainer
@export var enemy_scene: PackedScene
@onready var enemy_spawn_timer: Timer = $EnemySpawnTimer

const DEFAULT_SPAWN_DELAY : float = 1.0

var current_spawn_delay : float = 0.0
var current_data_index : int = 0

func _ready() -> void:	
	enemy_spawn_timer.wait_time = DEFAULT_SPAWN_DELAY
	
	enemy_spawn_timer.start()

func spawn_entity() -> void:
	if current_data_index >= wave_data_array.size():
		enemy_spawn_timer.stop()
		spawning_phase_complete.emit()
		return

	var path_follow := PathFollow2D.new()
	path_follow.loop = false
	path_follow.rotates = false
	path_follow.progress_ratio = 0.0
	path2D.add_child(path_follow)

	var enemy = enemy_scene.instantiate()
	path_follow.add_child(enemy)

func _on_enemy_spawn_timer_timeout() -> void:
	spawn_entity()
	current_data_index += 1
