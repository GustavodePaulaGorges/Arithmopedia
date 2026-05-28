class_name TowerEntity
extends Node2D

@export var tower_type: TowerTypes.TowerType

signal request_spawn_enemy(ratio: float, value: int, creator_tower: TowerEntity, segment_index: int, branch: int)
signal enemy_consumed(enemy: EnemyEntity)

const RANGE_COLOR := Color(0.4, 0.7, 1, 0.25)

var enemy_array : Array[EnemyEntity] = []
var sprite: Sprite2D

@onready var range_area: Node2D = $Range
@onready var range_shape: CollisionShape2D = $Range/CollisionShape2D

func _ready():
	add_to_group("towers")
	setup_sprite()
	queue_redraw()

func _draw():
	if range_shape == null or not (range_shape.shape is CircleShape2D):
		return
	var radius: float = (range_shape.shape as CircleShape2D).radius
	# Posição do CollisionShape2D no espaço local da torre (considerando o transform do Range)
	var center: Vector2 = range_area.position + range_area.scale * range_shape.position
	var effective_radius: float = radius * range_area.scale.x * range_shape.scale.x
	draw_circle(center, effective_radius, RANGE_COLOR)

func setup_sprite():
	sprite = Sprite2D.new()
	sprite.centered = false
	sprite.offset = Vector2(0, -16)
	add_child(sprite)

func _physics_process(_delta: float) -> void:
	pass

func _on_range_body_entered(body: Node2D) -> void:
	if body and body.creator_tower != self:
		enemy_array.append(body)

func _on_range_body_exited(body: Node2D) -> void:
	if body is EnemyEntity and body in enemy_array:
		enemy_array.erase(body)

func remove_enemy(enemy: EnemyEntity) -> void:
	enemy_array.erase(enemy)
	enemy_consumed.emit(enemy)
	enemy.get_parent().queue_free()
