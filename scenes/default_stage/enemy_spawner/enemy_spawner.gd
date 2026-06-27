class_name EnemySpawner
extends Node2D

## Marcador de posição do spawn da fase. A lógica de spawn fica no EnemyManager.

enum Role { NONE, UPPER, LOWER }

@export var role: Role = Role.NONE

func _ready() -> void:
	add_to_group("enemy_spawner")
	match role:
		Role.UPPER:
			add_to_group("enemy_spawner_upper")
		Role.LOWER:
			add_to_group("enemy_spawner_lower")
		_:
			pass
