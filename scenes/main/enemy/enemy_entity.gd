class_name EnemyEntity
extends CharacterBody2D

@export var movement_speed : float = 75
@export var value : int

@onready var value_label : Label = $Label

var path_follow: PathFollow2D

func _ready() -> void:
	update_label()
	path_follow = get_parent() as PathFollow2D

func _physics_process(delta: float) -> void:
	if path_follow:
		path_follow.progress += movement_speed * delta

func update_label():
	value_label.text = str(value)
