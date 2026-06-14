class_name StageData
extends Resource

enum VictoryType {
	ALL_GREATER_THAN,
	ALL_LESS_THAN,
	ALL_EQUAL_TO,
	ALTERNATING_SIGNALS,
	POTENCY_PROGRESSION,
	OPPOSITE_PAIRS,
	ALL_EQUAL_BETWEEN,
	EVEN_ODD,
	SQUARE_PERFECT
}

@export var stage_id: int = 1
@export_multiline var stage_title: String = ""
@export_multiline var stage_criteria: String = ""
@export_multiline var stage_history: String = ""
@export_multiline var prize_text: String = ""

@export var enemy_array: Array[int] = []
@export var enemy_array_upper: Array[int] = []
@export var enemy_array_lower: Array[int] = []

@export var victory_type: VictoryType = VictoryType.ALL_GREATER_THAN
@export var victory_target: int = 0

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
		VictoryType.OPPOSITE_PAIRS:
			if enemies.size() < 2:
				return false
			for i in range(enemies.size()):
				for j in range(i + 1, enemies.size()):
					if enemies[i] == -enemies[j]:
						return true
			return false
		VictoryType.ALTERNATING_SIGNALS:
				var should_be_positive = true
				for enemy in enemies:
					if should_be_positive:
						if enemy < 0:
							return false
					else:
						if enemy > 0:
							return false
					should_be_positive = !should_be_positive	
				return true
		VictoryType.POTENCY_PROGRESSION:
			if enemies.size() != 4:
				return false
			for i in range(1, enemies.size()):
				if enemies[i] * 2 != enemies[i - 1]:
					return false
			return true
		VictoryType.ALL_EQUAL_BETWEEN:
			if enemies.size() != 4:
				return false
			var first = enemies[0]
			for enemy in enemies:
				if enemy != first:
					return false
			return true
		VictoryType.EVEN_ODD:
			if enemies.size() != 4:
				return false
			var should_be_even = true
			for enemy in enemies:
				if should_be_even:
					if enemy % 2 != 0:
						return false
				else:
					if enemy % 2 == 0:
						return false
				should_be_even = !should_be_even	
			return true
		VictoryType.SQUARE_PERFECT:
			if enemies.size() != 4:
				return false
			for enemy in enemies:
				if enemy < 0:
					return false
				if sqrt(enemy) != int(sqrt(enemy)):
					return false
			return true
	return false
