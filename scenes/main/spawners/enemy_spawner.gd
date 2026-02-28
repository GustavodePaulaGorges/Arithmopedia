class_name EnemySpawner
extends Node2D

signal spawning_phase_complete

@export var wave_data_array : Array = ["Enemy 1", "Enemy2", "Enemy3", "Enemy4"]
@onready var enemy_spawn_timer: Timer = $EnemySpawnTimer

const DEFAULT_SPAWN_DELAY : float = 1.0

var current_spawn_delay : float = 0.0
var current_data_index : int = 0

func _ready() -> void:	
	enemy_spawn_timer.wait_time = DEFAULT_SPAWN_DELAY
	
	enemy_spawn_timer.start()

func spawn_entity() -> void:
	if current_data_index >= wave_data_array.size():
		printerr("Wave data array empty")
		enemy_spawn_timer.stop()
		spawning_phase_complete.emit()
		return

func _on_enemy_spawn_timer_timeout() -> void:
	spawn_entity()
	current_data_index += 1
