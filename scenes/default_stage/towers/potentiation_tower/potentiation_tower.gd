class_name PotentiationTower
extends TowerEntity

const SPAWN_DELAY: float = 0.5

var is_busy: bool = false

func setup_sprite():
	super.setup_sprite()
	sprite.texture = load("res://assets/sprites/TorrePot.png")

func _physics_process(_delta: float) -> void:
	if is_busy:
		return
	if enemy_array.size() >= 1:
		select_enemy()

func select_enemy() -> void:
	var enemy1 = enemy_array[0]

	enemy1.is_moving = false

	var pot_value: int = enemy1.value * enemy1.value
	var ratio: float = enemy1.get_parent().progress_ratio
	var segment_index: int = enemy1.segment_index
	var branch: int = enemy1.branch

	is_busy = true
	await get_tree().create_timer(SPAWN_DELAY).timeout

	if not is_instance_valid(enemy1) or not (enemy1 in enemy_array):
		is_busy = false
		return

	remove_enemy(enemy1)
	is_busy = false

	request_spawn_enemy.emit(ratio, pot_value, self, segment_index, branch)
