class_name EnemyManager
extends Node

## Unifica spawn de inimigos da horda, spawn por torres, tracking de inimigos
## ativos, coleta no endpoint e checagem de condição de vitória.

signal wave_updated(wave_data_array: Array[int], current_data_index: int)
signal wave_updated_dual(
	upper_array: Array[int], upper_index: int,
	lower_array: Array[int], lower_index: int)
signal level_completed
signal level_failed

const DEFAULT_SPAWN_DELAY : float = 1.0

@export var enemy_scene: PackedScene

var stage_data: StageData
var stage_path_data: StagePathData

var wave_data_array: Array[int] = []
var current_data_index: int = 0
var spawner_finished: bool = false
var active_enemies_count: int = 0
var enemies_at_endpoint: Array[int] = []

# Modo dual (TWO_WAY_START)
var _dual_mode: bool = false
var wave_data_array_upper: Array[int] = []
var wave_data_array_lower: Array[int] = []
var current_upper_index: int = 0
var current_lower_index: int = 0
var _upper_finished: bool = false
var _lower_finished: bool = false
const LOWER_START_OFFSET: float = 0.5

var _spawn_timer: Timer
var _spawn_timer_upper: Timer
var _spawn_timer_lower: Timer
var _path_runtime: StagePathRuntime
var _spawner_position: Vector2
var _endpoint: EnemyEndpoint

func _ready() -> void:
	add_to_group("enemy_manager")

	_spawn_timer = Timer.new()
	_spawn_timer.wait_time = DEFAULT_SPAWN_DELAY
	_spawn_timer.one_shot = false
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(_spawn_timer)

	_spawn_timer_upper = Timer.new()
	_spawn_timer_upper.wait_time = DEFAULT_SPAWN_DELAY
	_spawn_timer_upper.one_shot = false
	_spawn_timer_upper.timeout.connect(_on_spawn_timer_upper_timeout)
	add_child(_spawn_timer_upper)

	_spawn_timer_lower = Timer.new()
	_spawn_timer_lower.wait_time = DEFAULT_SPAWN_DELAY
	_spawn_timer_lower.one_shot = false
	_spawn_timer_lower.timeout.connect(_on_spawn_timer_lower_timeout)
	add_child(_spawn_timer_lower)

func setup(p_stage_data: StageData, p_stage_path_data: StagePathData, p_stage_root: Node) -> void:
	stage_data = p_stage_data
	stage_path_data = p_stage_path_data
	wave_data_array = p_stage_data.enemy_array.duplicate()
	current_data_index = 0
	spawner_finished = false
	active_enemies_count = 0
	enemies_at_endpoint.clear()

	_path_runtime = StagePathRuntime.new()
	if not _path_runtime.setup(p_stage_root, stage_path_data):
		push_error("EnemyManager: falha ao inicializar StagePathRuntime")
		return

	_dual_mode = _path_runtime.is_two_way_start_first()
	if _dual_mode:
		wave_data_array_upper = p_stage_data.enemy_array_upper.duplicate()
		wave_data_array_lower = p_stage_data.enemy_array_lower.duplicate()
		current_upper_index = 0
		current_lower_index = 0
		_upper_finished = wave_data_array_upper.is_empty()
		_lower_finished = wave_data_array_lower.is_empty()
	else:
		wave_data_array_upper.clear()
		wave_data_array_lower.clear()

	var spawner: Node2D = get_tree().get_first_node_in_group("enemy_spawner")
	_spawner_position = spawner.global_position if spawner else Vector2.ZERO
	_endpoint = get_tree().get_first_node_in_group("enemy_endpoint")

	if _endpoint and not _endpoint.enemy_arrived.is_connected(_on_enemy_arrived):
		_endpoint.enemy_arrived.connect(_on_enemy_arrived)

	if _dual_mode:
		wave_updated_dual.emit(
			wave_data_array_upper, current_upper_index,
			wave_data_array_lower, current_lower_index)
	else:
		wave_updated.emit(wave_data_array, current_data_index)

func start_wave() -> void:
	if _dual_mode:
		if not _spawn_timer_upper.is_stopped() or not _spawn_timer_lower.is_stopped():
			return
		if not wave_data_array_upper.is_empty():
			_spawn_timer_upper.start()
		if not wave_data_array_lower.is_empty():
			var t := get_tree().create_timer(LOWER_START_OFFSET)
			t.timeout.connect(_start_lower_timer)
		_check_dual_finished()
		return
	if not _spawn_timer.is_stopped():
		return
	_spawn_timer.start()

func _start_lower_timer() -> void:
	if _lower_finished:
		return
	_spawn_timer_lower.start()

## Chamado por torres via signal request_spawn_enemy.
func request_spawn(ratio: float, value: int, creator_tower: TowerEntity = null, segment_index: int = 0, branch: int = 0) -> void:
	_spawn_enemy_at(segment_index, branch, ratio, value, creator_tower)

func register_tower(tower: TowerEntity) -> void:
	if not tower.request_spawn_enemy.is_connected(request_spawn):
		tower.request_spawn_enemy.connect(request_spawn)

	if not tower.enemy_consumed.is_connected(_on_enemy_consumed):
		tower.enemy_consumed.connect(_on_enemy_consumed)

	if not tower.enemy_paused.is_connected(_on_enemy_paused):
		tower.enemy_paused.connect(_on_enemy_paused)

func unregister_tower(tower: TowerEntity) -> void:
	if tower.request_spawn_enemy.is_connected(request_spawn):
		tower.request_spawn_enemy.disconnect(request_spawn)

	if tower.enemy_consumed.is_connected(_on_enemy_consumed):
		tower.enemy_consumed.disconnect(_on_enemy_consumed)

	if tower.enemy_paused.is_connected(_on_enemy_paused):
		tower.enemy_paused.disconnect(_on_enemy_paused)

func _on_spawn_timer_timeout() -> void:
	if current_data_index >= wave_data_array.size():
		_spawn_timer.stop()
		spawner_finished = true
		if _path_runtime:
			_path_runtime.drain_all_merges()
		_check_victory()
		return

	_spawn_initial_enemy(wave_data_array[current_data_index])
	current_data_index += 1
	wave_updated.emit(wave_data_array, current_data_index)

func _on_spawn_timer_upper_timeout() -> void:
	if current_upper_index >= wave_data_array_upper.size():
		_spawn_timer_upper.stop()
		_upper_finished = true
		_check_dual_finished()
		return
	_spawn_initial_enemy_on_branch(wave_data_array_upper[current_upper_index], StagePathRuntime.BRANCH_TOP)
	current_upper_index += 1
	wave_updated_dual.emit(
		wave_data_array_upper, current_upper_index,
		wave_data_array_lower, current_lower_index)

func _on_spawn_timer_lower_timeout() -> void:
	if current_lower_index >= wave_data_array_lower.size():
		_spawn_timer_lower.stop()
		_lower_finished = true
		_check_dual_finished()
		return
	_spawn_initial_enemy_on_branch(wave_data_array_lower[current_lower_index], StagePathRuntime.BRANCH_BOTTOM)
	current_lower_index += 1
	wave_updated_dual.emit(
		wave_data_array_upper, current_upper_index,
		wave_data_array_lower, current_lower_index)

func _check_dual_finished() -> void:
	if _upper_finished and _lower_finished:
		spawner_finished = true
		if _path_runtime:
			_path_runtime.drain_all_merges()
		_check_victory()

func _spawn_initial_enemy(value: int) -> void:
	if not _path_runtime or not enemy_scene:
		push_error("EnemyManager: path_runtime ou enemy_scene não configurados")
		return
	var new_enemy: EnemyEntity = enemy_scene.instantiate()
	new_enemy.value = value
	_path_runtime.place_initial(new_enemy)
	active_enemies_count += 1

func _spawn_initial_enemy_on_branch(value: int, branch: int) -> void:
	if not _path_runtime or not enemy_scene:
		push_error("EnemyManager: path_runtime ou enemy_scene não configurados")
		return
	var new_enemy: EnemyEntity = enemy_scene.instantiate()
	new_enemy.value = value
	_path_runtime.place_initial_on_branch(new_enemy, branch)
	active_enemies_count += 1

func _spawn_enemy_at(segment_index: int, branch: int, ratio: float, value: int, creator_tower: TowerEntity = null) -> void:
	if not _path_runtime or not enemy_scene:
		push_error("EnemyManager: path_runtime ou enemy_scene não configurados")
		return
	var new_enemy: EnemyEntity = enemy_scene.instantiate()
	new_enemy.value = value
	new_enemy.creator_tower = creator_tower
	_path_runtime.place_at(new_enemy, segment_index, branch, ratio)
	active_enemies_count += 1

func _on_enemy_consumed(enemy: EnemyEntity) -> void:
	active_enemies_count = max(active_enemies_count - 1, 0)
	if _path_runtime:
		_path_runtime.on_enemy_consumed(enemy)

func _on_enemy_arrived(value: int, enemy: EnemyEntity) -> void:
	enemies_at_endpoint.append(value)
	if enemy and is_instance_valid(enemy):
		var parent := enemy.get_parent()
		if parent:
			parent.queue_free()
	if spawner_finished and _path_runtime:
		_path_runtime.drain_all_merges()
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

func _on_enemy_paused(enemy: EnemyEntity) -> void:
	if _path_runtime:
		_path_runtime.on_enemy_paused_by_tower(enemy)
