class_name EnemyEndpoint3
extends Node2D

@export var level_manager: LevelManager3

var enemy_array_values : Array[int] = []

func _on_range_body_entered(body: Node2D) -> void:
	if body and body.has_method("get_value"):
		enemy_array_values.append(body.get_value())
		remove_enemy(body)

		check_victory_condition()

func check_victory_condition():
	if  level_manager.spawner_finished and level_manager.active_enemies_count == enemy_array_values.size():

		level_manager.enemies_at_endpoint = enemy_array_values
		level_manager.on_enemies_reached_endpoint()

func remove_enemy(enemy: EnemyEntity3) -> void:
	enemy.get_parent().queue_free()
