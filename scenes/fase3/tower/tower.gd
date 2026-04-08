class_name TowerEntity3
extends Node2D

@export var level_manager: LevelManager3
@export var tower_type: TowerTypes.TowerType

signal request_spawn_enemy(ratio: float, value: int, creator_tower: TowerEntity3)

var enemy_array : Array[EnemyEntity3] = []
var sprite: Sprite2D

func _ready():
	add_to_group("towers")
	setup_sprite()

func setup_sprite():
	sprite = Sprite2D.new()
	sprite.centered = false
	sprite.offset = Vector2(0, -16)
	add_child(sprite)

func _physics_process(delta: float) -> void:
	pass

func _on_range_body_entered(body: Node2D) -> void:
	if body and body.creator_tower != self:
		enemy_array.append(body)

func _on_range_body_exited(body: Node2D) -> void:
	if body is EnemyEntity3 and body in enemy_array:
		enemy_array.erase(body)

func remove_enemy(enemy: EnemyEntity3) -> void:
	enemy.get_parent().queue_free()
	level_manager.decrement_active_enemies()
	
