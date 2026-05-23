class_name EnemyManager
extends Node

## Unifica spawn de inimigos da horda, spawn por torres, tracking de inimigos
## ativos, coleta no endpoint e checagem de condição de vitória.

signal wave_updated(wave_data_array: Array[int], current_data_index: int)
signal level_completed
signal level_failed

const DEFAULT_SPAWN_DELAY : float = 1.0

@export var enemy_scene: PackedScene

var stage_data: StageData

var wave_data_array: Array[int] = []
var current_data_index: int = 0
var spawner_finished: bool = false
var active_enemies_count: int = 0
var enemies_at_endpoint: Array[int] = []

var _spawn_timer: Timer
var _enemy_path: Path2D
var _spawner_position: Vector2
var _endpoint: EnemyEndpoint

func _ready() -> void:
	add_to_group("enemy_manager")

	_spawn_timer = Timer.new()
	_spawn_timer.wait_time = DEFAULT_SPAWN_DELAY
	_spawn_timer.one_shot = false
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(_spawn_timer)

func setup(p_stage_data: StageData) -> void:
	stage_data = p_stage_data
	wave_data_array = p_stage_data.enemy_array.duplicate()
	current_data_index = 0
	spawner_finished = false
	active_enemies_count = 0
	enemies_at_endpoint.clear()

	# Resolve dependências por grupo (após a fase ter chamado add_to_group nos seus nós).
	_enemy_path = get_tree().get_first_node_in_group("enemy_path")
	var spawner: Node2D = get_tree().get_first_node_in_group("enemy_spawner")
	_spawner_position = spawner.global_position if spawner else Vector2.ZERO
	_endpoint = get_tree().get_first_node_in_group("enemy_endpoint")

	if _endpoint and not _endpoint.enemy_arrived.is_connected(_on_enemy_arrived):
		_endpoint.enemy_arrived.connect(_on_enemy_arrived)

	wave_updated.emit(wave_data_array, current_data_index)

func start_wave() -> void:
	if not _spawn_timer.is_stopped():
		return
	_spawn_timer.start()

## Chamado por torres via signal request_spawn_enemy.
func request_spawn(ratio: float, value: int, creator_tower: TowerEntity = null) -> void:
	_spawn_enemy_at_ratio(ratio, value, creator_tower)

func register_tower(tower: TowerEntity) -> void:
	if not tower.request_spawn_enemy.is_connected(request_spawn):
		tower.request_spawn_enemy.connect(request_spawn)
	if not tower.enemy_consumed.is_connected(_on_enemy_consumed):
		tower.enemy_consumed.connect(_on_enemy_consumed)

func unregister_tower(tower: TowerEntity) -> void:
	if tower.request_spawn_enemy.is_connected(request_spawn):
		tower.request_spawn_enemy.disconnect(request_spawn)
	if tower.enemy_consumed.is_connected(_on_enemy_consumed):
		tower.enemy_consumed.disconnect(_on_enemy_consumed)

func _on_spawn_timer_timeout() -> void:
	if current_data_index >= wave_data_array.size():
		_spawn_timer.stop()
		spawner_finished = true
		_check_victory()
		return

	_spawn_enemy_at_ratio(0.0, wave_data_array[current_data_index])
	current_data_index += 1
	wave_updated.emit(wave_data_array, current_data_index)

func _spawn_enemy_at_ratio(ratio: float, value: int, creator_tower: TowerEntity = null) -> void:
	if not _enemy_path or not enemy_scene:
		push_error("EnemyManager: enemy_path ou enemy_scene não configurados")
		return

	var path_follow := PathFollow2D.new()
	path_follow.loop = false
	path_follow.rotates = false
	_enemy_path.add_child(path_follow)
	path_follow.progress_ratio = ratio

	var new_enemy: EnemyEntity = enemy_scene.instantiate()
	new_enemy.value = value
	new_enemy.creator_tower = creator_tower
	path_follow.add_child(new_enemy)

	active_enemies_count += 1

func _on_enemy_consumed(_enemy: EnemyEntity) -> void:
	active_enemies_count = max(active_enemies_count - 1, 0)

func _on_enemy_arrived(value: int, enemy: EnemyEntity) -> void:
	enemies_at_endpoint.append(value)
	if enemy and is_instance_valid(enemy):
		var parent := enemy.get_parent()
		if parent:
			parent.queue_free()
	_check_victory()

func _check_victory() -> void:
	if not spawner_finished:
		return
	# Active enemies count é decrementado somente quando torres consomem inimigos.
	# Vitória/derrota é avaliada quando todos os inimigos vivos chegaram ao endpoint.
	if active_enemies_count != enemies_at_endpoint.size():
		return
	if enemies_at_endpoint.is_empty():
		return

	if stage_data and stage_data.check_victory(enemies_at_endpoint):
		level_completed.emit()
	else:
		level_failed.emit()
