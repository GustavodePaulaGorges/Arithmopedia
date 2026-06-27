class_name StagePathData
extends Resource

@export var segments: Array[StagePathSegment] = []
@export var loop: bool = false
@export var sort_bifurcation_by_value: bool = false
@export var paused_enemies_do_not_block_merge: bool = false
@export var bottom_branch_returns_to_start: bool = false
@export var bottom_branch_returns_to_start_from_segment_index: int = 1
@export var reset_creator_tower_on_return_to_start: bool = false
@export var reset_duplicated_on_return_to_start: bool = false