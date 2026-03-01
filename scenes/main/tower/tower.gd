class_name TowerEntity
extends Node2D

var enemy_array = []
var enemy

func _physics_process(delta: float) -> void:
	if enemy_array.size() != 0:
		select_enemy()
	else:
		enemy = null

func _on_range_body_entered(body: Node2D) -> void:
	enemy_array.append(body.get_parent()) # aqui pega o parent pq tem o progresso no caminho, pra reposicionar dps

func _on_range_body_exited(body: Node2D) -> void:
	enemy_array.erase(body.get_parent())

# todo-fazer funcionar kkkkkkkkkk
# parece que ele não tá pegando o enemy_entity corretamente do parent, debbugar pra ver
func select_enemy() -> void:
	if len(enemy_array) == 2: # vai fazer a operação com os inimigos
		var enemy1 = enemy_array[0].get_node("EnemyEntity") as EnemyEntity
		var enemy1_value = enemy.value
		
		var enemy2 = enemy_array[1].get_node("EnemyEntity") as EnemyEntity
		var enemy2_value = enemy.value
		
		print_debug(enemy1_value + enemy2_value)
	
