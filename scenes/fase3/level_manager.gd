class_name LevelManager3
extends Node

signal level_completed
signal level_failed

var enemy_data_array: Array[int] = []
var victory_condition: VictoryCondition = null
var spawner_finished: bool = false
var enemies_at_endpoint: Array[int] = []
var active_enemies_count: int

enum VictoryType {
	GREATER_THAN,
	LESS_THAN,
	EQUAL_TO,
	ALL_GREATER_THAN,
	ALL_LESS_THAN,
	ALL_EQUAL_TO
}

class VictoryCondition:
	var type: VictoryType
	var target_value: int
	
	func _init(condition_type: VictoryType, target: int):
		type = condition_type
		target_value = target
	
	func check_condition(enemies: Array[int]) -> bool:
		match type:
			VictoryType.ALL_GREATER_THAN:
				for enemy in enemies:
					if enemy <= target_value:
						return false
				return true
			VictoryType.ALL_LESS_THAN:
				for enemy in enemies:
					if enemy >= target_value:
						return false
				return true
			VictoryType.ALL_EQUAL_TO:
				for enemy in enemies:
					if enemy != target_value:
						return false
				return true
			VictoryType.GREATER_THAN:
				return enemies.any(func(x): return x > target_value)
			VictoryType.LESS_THAN:
				return enemies.any(func(x): return x < target_value)
			VictoryType.EQUAL_TO:
				return enemies.any(func(x): return x == target_value)
		return false

func setup_level(enemy_array: Array[int], condition: VictoryCondition):
	enemy_data_array = enemy_array.duplicate()
	victory_condition = condition
	spawner_finished = false
	enemies_at_endpoint.clear()

func on_spawner_finished():
	spawner_finished = true

func on_enemies_reached_endpoint():
	if spawner_finished:
		check_victory()

func check_victory():
	if not spawner_finished or enemies_at_endpoint.size() == 0:
		return

	if victory_condition and victory_condition.check_condition(enemies_at_endpoint):
		level_completed.emit()
	else:
		level_failed.emit()

func get_enemy_data() -> Array[int]:
	return enemy_data_array.duplicate()

func is_spawning_complete() -> bool:
	return spawner_finished
	
func decrement_active_enemies() -> void:
	active_enemies_count -= 1
	
func increment_active_enemies() -> void:
	active_enemies_count += 1
