class_name StageData
extends Resource

enum VictoryType {
	ALL_GREATER_THAN,
	ALL_LESS_THAN,
	ALL_EQUAL_TO,
	ALTERNATING_SIGNALS
}

@export var stage_id: int = 1
@export_multiline var stage_title: String = ""
@export_multiline var stage_criteria: String = ""
@export_multiline var stage_history: String = ""
@export_multiline var prize_text: String = ""

@export var enemy_array: Array[int] = []

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
	return false
