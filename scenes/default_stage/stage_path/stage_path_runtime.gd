class_name StagePathRuntime
extends RefCounted

## Runtime que gerencia o caminho composto da fase:
## - sequência de segmentos (lineares e bifurcações);
## - distribuição de inimigos nas bifurcações (alternando top/bottom);
## - reagrupamento (merge) na entrada do próximo segmento.

const BRANCH_TOP: int = 0
const BRANCH_BOTTOM: int = 1
const SINGLE_BRANCH: int = 0

const META_PENDING_REMOVED: StringName = &"_stage_path_pending_removed"

class SegmentRuntime:
	var kind: int = StagePathSegment.Kind.LINEAR
	var paths: Array = []                   # tamanho 1 (LINEAR) ou 2 (BIFURCATION: [top, bottom])
	var bif_counter: int = 0                # contador local para distribuição
	var top_queue: Array = []               # merge: fila do lado top (EnemyEntity)
	var bottom_queue: Array = []            # merge: fila do lado bottom (EnemyEntity)
	var sort_queue: Array = []              # fila de ordenação na entrada (quando sort_bifurcation_by_value)
	var next_release: int = 0               # próximo lado a liberar do merge (0=top, 1=bottom)
	var pending: Array = [0, 0]             # inimigos vivos em cada branch da bifurcação

var data: StagePathData
var stage_root: Node
var segments: Array[SegmentRuntime] = []

func setup(p_stage_root: Node, p_data: StagePathData) -> bool:
	stage_root = p_stage_root
	data = p_data
	segments.clear()
	if data == null:
		push_error("StagePathRuntime: StagePathData não fornecido")
		return false
	if data.segments.is_empty():
		push_error("StagePathRuntime: StagePathData sem segmentos")
		return false

	for seg_def: StagePathSegment in data.segments:
		var seg := SegmentRuntime.new()
		seg.kind = seg_def.kind
		match seg_def.kind:
			StagePathSegment.Kind.LINEAR:
				var p := _resolve_path(seg_def.path)
				if p == null:
					return false
				seg.paths = [p]
			StagePathSegment.Kind.BIFURCATION, StagePathSegment.Kind.TWO_WAY_START:
				var pt := _resolve_path(seg_def.top_path)
				var pb := _resolve_path(seg_def.bottom_path)
				if pt == null or pb == null:
					return false
				seg.paths = [pt, pb]
		segments.append(seg)
	return true

func _resolve_path(np: NodePath) -> Path2D:
	if np.is_empty():
		push_error("StagePathRuntime: NodePath de segmento vazio")
		return null
	var n := stage_root.get_node_or_null(np)
	if n == null:
		push_error("StagePathRuntime: não foi possível resolver NodePath %s" % np)
		return null
	if not (n is Path2D):
		push_error("StagePathRuntime: nó %s não é Path2D" % np)
		return null
	return n

## Para spawn inicial (horda): coloca o inimigo no segmento 0.
## Se o segmento 0 for bifurcação, distribui via contador.
func place_initial(enemy: EnemyEntity) -> void:
	var branch := _choose_initial_branch(0)
	_attach_to_segment(enemy, 0, branch, 0.0)

## Para spawn por torre (resultado de operação): mantém segmento/branch da torre.
func place_at(enemy: EnemyEntity, segment_index: int, branch: int, ratio: float) -> void:
	segment_index = clamp(segment_index, 0, segments.size() - 1)
	var seg := segments[segment_index]
	if seg.kind == StagePathSegment.Kind.LINEAR:
		branch = SINGLE_BRANCH
	else:
		branch = clamp(branch, 0, 1)
	_attach_to_segment(enemy, segment_index, branch, ratio)

func _choose_initial_branch(segment_index: int) -> int:
	var seg := segments[segment_index]
	if seg.kind == StagePathSegment.Kind.LINEAR:
		return SINGLE_BRANCH
	seg.bif_counter += 1
	# 1º (ímpar) → top, 2º (par) → bottom, ...
	return BRANCH_TOP if (seg.bif_counter % 2) == 1 else BRANCH_BOTTOM

func is_two_way_start_first() -> bool:
	return not segments.is_empty() and segments[0].kind == StagePathSegment.Kind.TWO_WAY_START

func place_initial_on_branch(enemy: EnemyEntity, branch: int) -> void:
	if segments.is_empty():
		return
	branch = clamp(branch, 0, 1)
	_attach_to_segment(enemy, 0, branch, 0.0)

static func _is_branching_kind(kind: int) -> bool:
	return kind == StagePathSegment.Kind.BIFURCATION or kind == StagePathSegment.Kind.TWO_WAY_START

func _get_next_segment_index(current_seg_index: int, enemy: EnemyEntity = null) -> int:
	if segments.is_empty():
		return -1

	# Regra especial da fase final:
	# o BottomPath da primeira bifurcação volta direto para o MainPath.
	if data \
	and data.bottom_branch_returns_to_start \
	and enemy != null \
	and current_seg_index == data.bottom_branch_returns_to_start_from_segment_index \
	and enemy.branch == BRANCH_BOTTOM:
		return 0

	var next_index := current_seg_index + 1

	if next_index >= segments.size():
		if data and data.loop:
			return 0
		return -1

	return next_index

func _decrement_pending_for_enemy(enemy: EnemyEntity, seg: SegmentRuntime) -> void:
	if enemy == null:
		return

	var b: int = clamp(enemy.branch, 0, 1)

	if _is_removed_from_pending(enemy):
		_clear_removed_from_pending(enemy)
	else:
		seg.pending[b] = max(seg.pending[b] - 1, 0)

func _reset_enemy_loop_immunity_if_needed(enemy: EnemyEntity, current_seg_index: int, next_seg_index: int) -> void:
	if enemy == null:
		return

	if data == null:
		return

	if next_seg_index != 0:
		return

	if current_seg_index == 0:
		return

	if data.reset_creator_tower_on_return_to_start:
		if enemy.creator_tower != null:
			print(
				"[RESET_CREATOR] id=%d value=%d old_creator=%s"
				% [
					enemy.get_instance_id(),
					enemy.value,
					enemy.creator_tower.name
				]
			)

		enemy.creator_tower = null

	if data.reset_duplicated_on_return_to_start:
		enemy.duplicated = false

func _attach_to_segment(enemy: EnemyEntity, segment_index: int, branch: int, ratio: float) -> void:
	var seg := segments[segment_index]
	var p2d: Path2D = seg.paths[branch] if branch < seg.paths.size() else seg.paths[0]

	var path_follow := PathFollow2D.new()
	path_follow.loop = false
	path_follow.rotates = false
	p2d.add_child(path_follow)
	path_follow.progress_ratio = ratio

	var old_parent := enemy.get_parent()
	if old_parent and old_parent is PathFollow2D:
		old_parent.remove_child(enemy)
		old_parent.queue_free()

	path_follow.add_child(enemy)

	enemy.segment_index = segment_index
	enemy.branch = branch
	enemy.path_runtime = self
	enemy.path_follow = path_follow
	enemy.reset_segment_finished_flag()

	# Sempre que o inimigo entra ou reentra em um segmento,
	# ele volta a fazer parte do fluxo normal do caminho.
	_clear_removed_from_pending(enemy)

	if _is_branching_kind(seg.kind):
		seg.pending[branch] += 1

	print(
		"[ATTACH] id=%d value=%d seg=%d branch=%d pending=[%d,%d]"
		% [
			enemy.get_instance_id(),
			enemy.value,
			segment_index,
			branch,
			seg.pending[0],
			seg.pending[1]
		]
	)

## Chamado pelo EnemyEntity quando atinge progress_ratio >= 1.0 em seu segmento.
func on_enemy_finished_segment(enemy: EnemyEntity) -> void:

	print(
		"[FINISH] enemy=%d seg=%d branch=%d"
		% [
			enemy.get_instance_id(),
			enemy.segment_index,
			enemy.branch
		]
	)

	var seg_index := enemy.segment_index
	if seg_index < 0 or seg_index >= segments.size():
		return
	var seg := segments[seg_index]
	print("[DEBUG] on_enemy_finished_segment: enemy=%s, seg=%d, branch=%d, seg_kind=%d" % [enemy.value, seg_index, enemy.branch, seg.kind])

	# Se for último segmento, volta ao início no modo loop.
	# Importante: se o último segmento for bifurcação, precisa decrementar o pending.
	if seg_index >= segments.size() - 1:
		if _is_branching_kind(seg.kind):
			_decrement_pending_for_enemy(enemy, seg)

		if data and data.loop:
			_advance_to_next(enemy, seg_index)
			return

		enemy.is_moving = false
		if enemy.path_follow:
			enemy.path_follow.progress_ratio = 1.0
		return

	if _is_branching_kind(seg.kind):
		_decrement_pending_for_enemy(enemy, seg)

		enemy.is_moving = false

		if enemy.path_follow:
			enemy.path_follow.progress_ratio = 1.0

		if enemy.branch == BRANCH_TOP:
			seg.top_queue.append(enemy)
			print("[DEBUG] on_enemy_finished_segment: enemy=%s enqueued in top_queue (size: %d)" % [enemy.value, seg.top_queue.size()])
		else:
			seg.bottom_queue.append(enemy)
			print("[DEBUG] on_enemy_finished_segment: enemy=%s enqueued in bottom_queue (size: %d)" % [enemy.value, seg.bottom_queue.size()])

		_flush_merge(seg_index)
	else:
		_advance_to_next(enemy, seg_index)

## Chamado pelo EnemyManager quando uma torre consome um inimigo (queue_free do
## PathFollow2D acontece na torre). Mantém pending consistente.
func on_enemy_consumed(enemy: EnemyEntity) -> void:
	if enemy == null:
		return

	var seg_index := enemy.segment_index
	if seg_index < 0 or seg_index >= segments.size():
		return

	var seg := segments[seg_index]

	if _is_branching_kind(seg.kind):
		if _is_removed_from_pending(enemy):
			_clear_removed_from_pending(enemy)
		else:
			seg.pending[enemy.branch] = max(seg.pending[enemy.branch] - 1, 0)

		_flush_merge(seg_index)
	else:
		var next_index := seg_index + 1
		if next_index < segments.size():
			var next_seg := segments[next_index]
			if _is_branching_kind(next_seg.kind) and enemy in next_seg.sort_queue:
				next_seg.sort_queue.erase(enemy)
				_flush_sort_queue(next_index)

func _advance_to_next(enemy: EnemyEntity, current_seg_index: int) -> void:
	var next_index := _get_next_segment_index(current_seg_index, enemy)

	if next_index < 0:
		enemy.is_moving = false
		return

	_reset_enemy_loop_immunity_if_needed(enemy, current_seg_index, next_index)

	var next_seg := segments[next_index]
	var branch := SINGLE_BRANCH

	print(
		"[DEBUG] _advance_to_next: enemy=%s, from_seg=%d, to_seg=%d, next_seg_kind=%d"
		% [enemy.value, current_seg_index, next_index, next_seg.kind]
	)

	if _is_branching_kind(next_seg.kind):
		if data and data.sort_bifurcation_by_value:
			enemy.is_moving = false
			next_seg.sort_queue.append(enemy)

			print(
				"[DEBUG] _advance_to_next: enemy=%s enfileirado para sort_queue do seg %d (queue size: %d)"
				% [enemy.value, next_index, next_seg.sort_queue.size()]
			)

			_flush_sort_queue(next_index)
			return

		branch = _choose_initial_branch(next_index)

		print(
			"[DEBUG] _advance_to_next: enemy=%s assigned to branch %d (sem sort)"
			% [enemy.value, branch]
		)

	_attach_to_segment(enemy, next_index, branch, 0.0)
	enemy.is_moving = true

func _flush_sort_queue(bif_seg_index: int) -> void:
	var seg := segments[bif_seg_index]
	print("[DEBUG] _flush_sort_queue: seg=%d, queue_size=%d" % [bif_seg_index, seg.sort_queue.size()])
	while seg.sort_queue.size() >= 2:
		var e1: EnemyEntity = seg.sort_queue.pop_front()
		var e2: EnemyEntity = seg.sort_queue.pop_front()
		var top_enemy: EnemyEntity = e1
		var bottom_enemy: EnemyEntity = e2
		if e2.value > e1.value || e2.value == e1.value:
			top_enemy = e2
			bottom_enemy = e1
		print("[DEBUG] _flush_sort_queue: pair processed - top=%s, bottom=%s" % [top_enemy.value, bottom_enemy.value])
		print(
			"[SORT] top id=%d value=%d | bottom id=%d value=%d"
			% [
				top_enemy.get_instance_id(),
				top_enemy.value,
				bottom_enemy.get_instance_id(),
				bottom_enemy.value
			]
		)
		_attach_to_segment(top_enemy, bif_seg_index, BRANCH_TOP, 0.0)
		top_enemy.is_moving = true
		_attach_to_segment(bottom_enemy, bif_seg_index, BRANCH_BOTTOM, 0.0)
		bottom_enemy.is_moving = true
	if seg.sort_queue.size() == 1:
		print("[DEBUG] _flush_sort_queue: 1 enemy remaining in queue (odd number) - enemy=%s" % [seg.sort_queue[0].value])
func _flush_merge(bif_seg_index: int) -> void:
	var seg := segments[bif_seg_index]
	var next_index := bif_seg_index + 1
	var is_last := next_index >= segments.size()
	print("[DEBUG] _flush_merge: seg=%d, top_queue=%d, bottom_queue=%d, pending=[%d,%d], next_release=%d" % [bif_seg_index, seg.top_queue.size(), seg.bottom_queue.size(), seg.pending[0], seg.pending[1], seg.next_release])
	if is_last and data and data.loop:
		next_index = 0
	elif is_last:
		# Sem segmento depois da bifurcação: libera todos imediatamente.
		while not seg.top_queue.is_empty():
			var e: EnemyEntity = seg.top_queue.pop_front()
			e.is_moving = false
		while not seg.bottom_queue.is_empty():
			var e2: EnemyEntity = seg.bottom_queue.pop_front()
			e2.is_moving = false
		return

	while true:
		var side: int = seg.next_release
		var preferred: Array = seg.top_queue if side == BRANCH_TOP else seg.bottom_queue
		var other: Array = seg.bottom_queue if side == BRANCH_TOP else seg.top_queue
		var other_side_pending: int = seg.pending[BRANCH_BOTTOM if side == BRANCH_TOP else BRANCH_TOP]

		if not preferred.is_empty():
			var e: EnemyEntity = preferred.pop_front()
			print(
				"[DEBUG] _flush_merge: releasing enemy=%s from preferred side %d to next seg %d"
				% [e.value, side, _get_next_segment_index(bif_seg_index, e)]
			)
			_advance_to_next(e, bif_seg_index)
			seg.next_release = BRANCH_BOTTOM if side == BRANCH_TOP else BRANCH_TOP
		elif not other.is_empty() and other_side_pending == 0 and seg.pending[side] == 0:
			# Lado esperado nunca mais virá: drena o outro.
			var e2: EnemyEntity = other.pop_front()
			print(
				"[DEBUG] _flush_merge: draining enemy=%s from other side to next seg %d (pending exhausted)"
				% [e2.value, _get_next_segment_index(bif_seg_index, e2)]
			)
			_advance_to_next(e2, bif_seg_index)
			# next_release permanece, mas como pending[side] == 0, próxima iteração
			# cairá nesta mesma branch.
		else:
			print("[DEBUG] _flush_merge: breaking loop - preferred_empty=%s, other_empty=%s, other_pending=%d, side_pending=%d" % [preferred.is_empty(), other.is_empty(), other_side_pending, seg.pending[side]])
			break

## Útil ao final da horda (quando o EnemyManager sabe que não há mais spawns)
## para drenar qualquer merge que tenha ficado esperando o par.
func drain_all_merges() -> void:
	for i in range(segments.size()):
		if _is_branching_kind(segments[i].kind):
			_drain_segment(i)

func _drain_segment(bif_seg_index: int) -> void:
	var seg := segments[bif_seg_index]
	var next_index := bif_seg_index + 1
	if next_index >= segments.size():
		if data and data.loop:
			next_index = 0
		else:
			return
	# Drena tudo respeitando ordem top/bottom alternada quando possível.
	while not seg.top_queue.is_empty() or not seg.bottom_queue.is_empty():
		var side: int = seg.next_release
		var preferred: Array = seg.top_queue if side == BRANCH_TOP else seg.bottom_queue
		var other: Array = seg.bottom_queue if side == BRANCH_TOP else seg.top_queue
		if not preferred.is_empty():
			var e: EnemyEntity = preferred.pop_front()
			_advance_to_next(e, bif_seg_index)
			seg.next_release = BRANCH_BOTTOM if side == BRANCH_TOP else BRANCH_TOP
		elif not other.is_empty():
			var e2: EnemyEntity = other.pop_front()
			_advance_to_next(e2, bif_seg_index)

func _is_removed_from_pending(enemy: EnemyEntity) -> bool:
	return enemy != null \
		and enemy.has_meta(META_PENDING_REMOVED) \
		and enemy.get_meta(META_PENDING_REMOVED) == true


func _mark_removed_from_pending(enemy: EnemyEntity) -> void:
	if enemy != null:
		enemy.set_meta(META_PENDING_REMOVED, true)


func _clear_removed_from_pending(enemy: EnemyEntity) -> void:
	if enemy != null and enemy.has_meta(META_PENDING_REMOVED):
		enemy.remove_meta(META_PENDING_REMOVED)


func on_enemy_paused_by_tower(enemy: EnemyEntity) -> void:
	if enemy == null:
		return

	if data == null or not data.paused_enemies_do_not_block_merge:
		return

	if _is_removed_from_pending(enemy):
		return

	var seg_index := enemy.segment_index
	if seg_index < 0 or seg_index >= segments.size():
		return

	var seg := segments[seg_index]
	if not _is_branching_kind(seg.kind):
		return

	var b: int = clamp(enemy.branch, 0, 1)

	seg.pending[b] = max(seg.pending[b] - 1, 0)
	_mark_removed_from_pending(enemy)

	print(
		"[PAUSE_FLOW] id=%d value=%d seg=%d branch=%d pending=[%d,%d]"
		% [
			enemy.get_instance_id(),
			enemy.value,
			seg_index,
			b,
			seg.pending[0],
			seg.pending[1]
		]
	)

	_flush_merge(seg_index)
