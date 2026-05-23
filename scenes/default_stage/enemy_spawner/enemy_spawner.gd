class_name EnemySpawner
extends Node2D

## Marcador de posição do spawn da fase. A lógica de spawn fica no EnemyManager.

func _ready() -> void:
	add_to_group("enemy_spawner")
