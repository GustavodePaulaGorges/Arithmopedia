class_name EnemyEntity
extends CharacterBody2D

@export var movement_speed : float = 75
@export var value : int

@onready var value_label : Label = $Label

var path_follow: PathFollow2D
var is_moving : bool = true
var creator_tower: TowerEntity

var segment_index: int = 0
var branch: int = 0
var path_runtime: StagePathRuntime
var _segment_finished: bool = false

func set_is_moving(new_value: bool) -> void:
	is_moving = new_value

func _ready() -> void:
	update_label()
	if path_follow == null:
		path_follow = get_parent() as PathFollow2D

func _physics_process(delta: float) -> void:
	if path_follow and is_moving:
		path_follow.progress += movement_speed * delta
		if not _segment_finished and path_follow.progress_ratio >= 1.0:
			_segment_finished = true
			if path_runtime:
				path_runtime.on_enemy_finished_segment(self)

func reset_segment_finished_flag() -> void:
	_segment_finished = false

func update_label():
	value_label.text = str(value)

func get_value() -> int:
	return value
