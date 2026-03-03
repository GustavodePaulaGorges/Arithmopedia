class_name TowerEntity
extends Node2D

var enemy_array = []

func _physics_process(delta: float) -> void:
	if enemy_array.size() != 0:
		select_enemy()
	else:
		pass

func _on_range_body_entered(body: Node2D) -> void:
	if body is EnemyEntity:
		enemy_array.append(body)

func _on_range_body_exited(body: Node2D) -> void:
	if body is EnemyEntity:
		enemy_array.erase(body)

func select_enemy() -> void:
	var enemy1 = enemy_array[0]
	enemy1.set_is_moving(false)
	
	if enemy_array.size() >= 2:
		var enemy2 = enemy_array[1]
		var progress1 = enemy1.get_parent().progress_ratio
		var progress2 = enemy2.get_parent().progress_ratio
		var sum_value = enemy1.value + enemy2.value

		remove_enemy(enemy1)
		remove_enemy(enemy2)
		
		## Instanciar EnemySpawner e componentizar certinho pra criar o novo inimigo
		## Avaliar nivel de conhecimento, pq teria que ter path ou algo do tipo pra coloca dnv,
		## torre deveria ter essa info? É escalável?
		print("Enemy 1 progress:", progress1)
		print("Enemy 2 progress:", progress2)
		print("Soma dos values:", sum_value)

func remove_enemy(enemy: EnemyEntity) -> void:
	enemy.get_parent().queue_free()
