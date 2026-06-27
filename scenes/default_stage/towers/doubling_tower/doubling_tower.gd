class_name DoublingTower
extends TowerEntity

const DUPLICATE_OFFSET: float = 0.1

func setup_sprite():
	super.setup_sprite()
	sprite.texture = load("res://assets/sprites/TorreDup.png")


func _on_range_body_entered(body: Node2D) -> void:
	if body is EnemyEntity and not body.duplicated and body.creator_tower != self:
		enemy_array.append(body)

func _physics_process(_delta: float) -> void:
	if enemy_array.size() >= 1:
		select_enemy()


func select_enemy() -> void:
	var enemy = enemy_array[0]

	var value = enemy.value
	var ratio = clampf(enemy.get_parent().progress_ratio + DUPLICATE_OFFSET, 0.0, 1.0)
	var segment_index: int = enemy.segment_index
	var branch: int = enemy.branch

	enemy.duplicated = true
	request_spawn_enemy.emit(ratio, value, self, segment_index, branch)

	enemy_array.remove_at(0)
