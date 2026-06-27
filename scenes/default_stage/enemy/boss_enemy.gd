class_name BossEnemy
extends Node2D

signal boss_defeated

const MAX_HEALTH := 100
var health: int = MAX_HEALTH

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var progress_bar: ProgressBar = $ProgressBar

var sprite_original_position: Vector2
var sprite_original_scale: Vector2
var sprite_original_color: Color

var is_dying := false
var already_emitted_defeat := false

var shake_tween: Tween
var color_tween: Tween
var scale_tween: Tween

var death_spiral_tween: Tween
var death_squish_tween: Tween

func _ready() -> void:
	sprite_original_position = sprite.position
	sprite_original_scale = sprite.scale
	sprite_original_color = sprite.modulate
	
	set_health_label()
	
func set_health_label() -> void:
	progress_bar.value = health

func _on_area_2d_body_entered(enemy: EnemyEntity) -> void:
	if is_dying:
		return

	if enemy and enemy.creator_tower != self:
		health -= enemy.value
		print(health)
		set_health_label()

		if health <= 0:
			play_death_effect()
			## Signal pra acaba a fase
		else:
			play_hit_effect()

func play_hit_effect() -> void:
	if shake_tween:
		shake_tween.kill()
	if color_tween:
		color_tween.kill()
	if scale_tween:
		scale_tween.kill()

	sprite.position = sprite_original_position
	sprite.scale = sprite_original_scale
	sprite.modulate = sprite_original_color

	shake_tween = create_tween()
	shake_tween.tween_property(sprite, "position", sprite_original_position + Vector2(4, 0), 0.03)
	shake_tween.tween_property(sprite, "position", sprite_original_position + Vector2(-4, 0), 0.03)
	shake_tween.tween_property(sprite, "position", sprite_original_position + Vector2(3, 0), 0.03)
	shake_tween.tween_property(sprite, "position", sprite_original_position + Vector2(-3, 0), 0.03)
	shake_tween.tween_property(sprite, "position", sprite_original_position, 0.03)

	color_tween = create_tween()
	color_tween.tween_property(sprite, "modulate", Color(1, 0.2, 0.2), 0.04)
	color_tween.tween_property(sprite, "modulate", sprite_original_color, 0.12)

	scale_tween = create_tween()
	scale_tween.tween_property(sprite, "scale", sprite_original_scale * 0.85, 0.05)
	scale_tween.tween_property(sprite, "scale", sprite_original_scale * 1.12, 0.06)
	scale_tween.tween_property(sprite, "scale", sprite_original_scale, 0.06)
	
func play_death_effect() -> void:
	is_dying = true

	if shake_tween:
		shake_tween.kill()
	if color_tween:
		color_tween.kill()
	if scale_tween:
		scale_tween.kill()
	if death_spiral_tween:
		death_spiral_tween.kill()
	if death_squish_tween:
		death_squish_tween.kill()

	sprite.position = sprite_original_position
	sprite.scale = sprite_original_scale
	sprite.modulate = Color(1, 0.25, 0.25, 1)

	death_spiral_tween = create_tween()
	death_spiral_tween.set_parallel(true)

	death_spiral_tween.tween_method(
		_update_death_spiral,
		0.0,
		1.0,
		1.2
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	death_spiral_tween.tween_property(sprite, "modulate:a", 0.0, 1.2)

	death_squish_tween = create_tween()

	var steps := 10
	for i in range(steps):
		var progress := float(i + 1) / float(steps)
		var shrink := lerpf(1.0, 0.05, progress)

		var squish_x := randf_range(0.75, 1.25)
		var squish_y := randf_range(0.75, 1.25)

		var target_scale := Vector2(
			sprite_original_scale.x * shrink * squish_x,
			sprite_original_scale.y * shrink * squish_y
		)

		death_squish_tween.tween_property(
			sprite,
			"scale",
			target_scale,
			0.08
		).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)

	death_squish_tween.tween_property(sprite, "scale", Vector2.ZERO, 0.12)

	death_spiral_tween.finished.connect(func():
		if not already_emitted_defeat:
			already_emitted_defeat = true
			boss_defeated.emit()

		queue_free()
	)

func _update_death_spiral(t: float) -> void:
	var rotations := 3.5
	var radius := lerpf(28.0, 0.0, t)
	var angle := t * TAU * rotations

	sprite.position = sprite_original_position + Vector2(
		cos(angle),
		sin(angle)
	) * radius

	sprite.rotation = angle
