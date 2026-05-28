class_name StageData
extends Resource

enum VictoryType {
	GREATER_THAN,
	LESS_THAN,
	EQUAL_TO,
	ALL_GREATER_THAN,
	ALL_LESS_THAN,
	ALL_EQUAL_TO,
	OPPOSITE_PAIRS
}

@export var stage_id: int = 1
@export_multiline var stage_title: String = ""
@export_multiline var stage_criteria: String = ""
@export_multiline var stage_history: String = ""
@export_multiline var prize_text: String = ""

@export var enemy_array: Array[int] = []

@export var victory_type: VictoryType = VictoryType.ALL_GREATER_THAN
@export var victory_target: int = 0

## Mapeamento TowerTypes.TowerType (int) -> quantidade disponível.
@export var tower_count: Dictionary = {}

func check_victory(enemies: Array[int]) -> bool:
	match victory_type:
		VictoryType.ALL_GREATER_THAN:
			for enemy in enemies:
				if enemy <= victory_target:
					return false
			return true
		VictoryType.ALL_LESS_THAN:
			for enemy in enemies:
				if enemy >= victory_target:
					return false
			return true
		VictoryType.ALL_EQUAL_TO:
			for enemy in enemies:
				if enemy != victory_target:
					return false
			return true
		VictoryType.GREATER_THAN:
			return enemies.any(func(x): return x > victory_target)
		VictoryType.LESS_THAN:
			return enemies.any(func(x): return x < victory_target)
		VictoryType.EQUAL_TO:
			return enemies.any(func(x): return x == victory_target)
		VictoryType.OPPOSITE_PAIRS:
			if enemies.size() < 2:
				return false
			for i in range(enemies.size()):
				for j in range(i + 1, enemies.size()):
					if enemies[i] == -enemies[j]:
						return true
			return false
	return false
