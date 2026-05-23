class_name EnemyEndpoint
extends Node2D

signal enemy_arrived(value: int, enemy: EnemyEntity)

func _ready() -> void:
	add_to_group("enemy_endpoint")

func _on_range_body_entered(body: Node2D) -> void:
	if body and body.has_method("get_value"):
		enemy_arrived.emit(body.get_value(), body)
