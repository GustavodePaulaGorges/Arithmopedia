class_name EnemyEntity
extends CharacterBody2D

@export var movement_speed : float = 200

var path_follow: PathFollow2D

func _ready() -> void:
	path_follow = get_parent() as PathFollow2D

func _physics_process(delta: float) -> void:
	if path_follow:
		path_follow.progress += movement_speed * delta
