class_name StagePathRuntime
extends RefCounted

## Runtime que gerencia o caminho composto da fase:
## - sequência de segmentos (lineares e bifurcações);
## - distribuição de inimigos nas bifurcações (alternando top/bottom);
## - reagrupamento (merge) na entrada do próximo segmento.

const BRANCH_TOP: int = 0
const BRANCH_BOTTOM: int = 1
const SINGLE_BRANCH: int = 0

class SegmentRuntime:
	var kind: int = StagePathSegment.Kind.LINEAR
	var paths: Array = []                   # tamanho 1 (LINEAR) ou 2 (BIFURCATION: [top, bottom])
	var bif_counter: int = 0                # contador local para distribuição
	var top_queue: Array = []               # merge: fila do lado top (EnemyEntity)
	var bottom_queue: Array = []            # merge: fila do lado bottom (EnemyEntity)
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
			StagePathSegment.Kind.BIFURCATION:
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

func _attach_to_segment(enemy: EnemyEntity, segment_index: int, branch: int, ratio: float) -> void:
	var seg := segments[segment_index]
	var p2d: Path2D = seg.paths[branch] if branch < seg.paths.size() else seg.paths[0]

	var path_follow := PathFollow2D.new()
	path_follow.loop = false
	path_follow.rotates = false
	p2d.add_child(path_follow)
	path_follow.progress_ratio = ratio

	# Se já tinha um pai (estamos transferindo de segmento), reparent.
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

	if seg.kind == StagePathSegment.Kind.BIFURCATION:
		seg.pending[branch] += 1

## Chamado pelo EnemyEntity quando atinge progress_ratio >= 1.0 em seu segmento.
func on_enemy_finished_segment(enemy: EnemyEntity) -> void:
	var seg_index := enemy.segment_index
	if seg_index < 0 or seg_index >= segments.size():
		return
	var seg := segments[seg_index]

	# Se for último segmento, deixa o endpoint cuidar do enemy.
	# Apenas pausa o movimento e mantém posição.
	if seg_index >= segments.size() - 1:
		enemy.is_moving = false
		if enemy.path_follow:
			enemy.path_follow.progress_ratio = 1.0
		return

	if seg.kind == StagePathSegment.Kind.BIFURCATION:
		# Decrementa pending e enfileira no merge.
		seg.pending[enemy.branch] = max(seg.pending[enemy.branch] - 1, 0)
		enemy.is_moving = false
		if enemy.path_follow:
			enemy.path_follow.progress_ratio = 1.0
		if enemy.branch == BRANCH_TOP:
			seg.top_queue.append(enemy)
		else:
			seg.bottom_queue.append(enemy)
		_flush_merge(seg_index)
	else:
		# Linear → próximo segmento (pode ser linear ou bifurcação).
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
	if seg.kind == StagePathSegment.Kind.BIFURCATION:
		seg.pending[enemy.branch] = max(seg.pending[enemy.branch] - 1, 0)
		# Pode ser que com a remoção, o merge fique destravado.
		_flush_merge(seg_index)

func _advance_to_next(enemy: EnemyEntity, current_seg_index: int) -> void:
	var next_index := current_seg_index + 1
	if next_index >= segments.size():
		enemy.is_moving = false
		return
	var next_seg := segments[next_index]
	var branch := SINGLE_BRANCH
	if next_seg.kind == StagePathSegment.Kind.BIFURCATION:
		branch = _choose_initial_branch(next_index)
	_attach_to_segment(enemy, next_index, branch, 0.0)
	enemy.is_moving = true

func _flush_merge(bif_seg_index: int) -> void:
	var seg := segments[bif_seg_index]
	var next_index := bif_seg_index + 1
	if next_index >= segments.size():
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
			_advance_to_next(e, bif_seg_index)
			seg.next_release = BRANCH_BOTTOM if side == BRANCH_TOP else BRANCH_TOP
		elif not other.is_empty() and other_side_pending == 0 and seg.pending[side] == 0:
			# Lado esperado nunca mais virá: drena o outro.
			var e2: EnemyEntity = other.pop_front()
			_advance_to_next(e2, bif_seg_index)
			# next_release permanece, mas como pending[side] == 0, próxima iteração
			# cairá nesta mesma branch.
		else:
			break

## Útil ao final da horda (quando o EnemyManager sabe que não há mais spawns)
## para drenar qualquer merge que tenha ficado esperando o par.
func drain_all_merges() -> void:
	for i in range(segments.size()):
		if segments[i].kind == StagePathSegment.Kind.BIFURCATION:
			_drain_segment(i)

func _drain_segment(bif_seg_index: int) -> void:
	var seg := segments[bif_seg_index]
	var next_index := bif_seg_index + 1
	if next_index >= segments.size():
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
