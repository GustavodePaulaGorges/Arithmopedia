class_name AdditionTower3
extends TowerEntity3

func setup_sprite():
	super.setup_sprite()
	sprite.texture = load("res://assets/sprites/TorreAdd.png")

func _physics_process(delta: float) -> void:
	if enemy_array.size() >= 1:
		select_enemy()

func select_enemy() -> void:
	var enemy1 = enemy_array[0]
	
	if enemy1.creator_tower != self:
		enemy1.is_moving = false
	
	if enemy_array.size() >= 2:
		var enemy2 = enemy_array[1]

		var sum_value = enemy1.value + enemy2.value
		var ratio1 = enemy1.get_parent().progress_ratio
		var ratio2 = enemy2.get_parent().progress_ratio
		var ratio = (ratio1 + ratio2) / 2.0

		remove_enemy(enemy1)
		remove_enemy(enemy2)

		request_spawn_enemy.emit(ratio, sum_value, self)
