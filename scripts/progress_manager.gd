extends Node

# Singleton para gerenciar o progresso do jogador
# Deve ser configurado como AutoLoad no project.godot com o nome "ProgressManager"

signal stage_completed(stage_id)
signal stage_unlocked(stage_id)

var completed_stages: Array[int] = []
var unlocked_stages: Array[int] = [1]  # Fase 1 sempre desbloqueada
var current_stage: int = 1

const SAVE_FILE_PATH = "user://progress.save"

func _ready():
	load_progress()

func save_progress():
	var save_data = {
		"completed_stages": completed_stages,
		"unlocked_stages": unlocked_stages,
		"current_stage": current_stage
	}
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()

func load_progress():
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file:
		var save_data = file.get_var()
		file.close()
		
		if save_data:
			completed_stages = save_data.get("completed_stages", [])
			unlocked_stages = save_data.get("unlocked_stages", [1])
			current_stage = save_data.get("current_stage", 1)

func complete_stage(stage_id: int):
	if stage_id not in completed_stages:
		completed_stages.append(stage_id)
		unlock_stage(stage_id + 1)
		stage_completed.emit(stage_id)
		save_progress()

func unlock_stage(stage_id: int):
	if stage_id not in unlocked_stages:
		unlocked_stages.append(stage_id)
		stage_unlocked.emit(stage_id)
		save_progress()

func is_stage_completed(stage_id: int) -> bool:
	return stage_id in completed_stages

func is_stage_unlocked(stage_id: int) -> bool:
	return stage_id in unlocked_stages

func reset_progress():
	completed_stages.clear()
	unlocked_stages = [1]
	current_stage = 1
	save_progress()

func unlock_all_stages():
	# Desbloqueia todas as fases (assumindo que temos 10 fases no total)
	unlocked_stages.clear()
	for i in range(1, 11):  # Fases 1 a 10
		unlocked_stages.append(i)
	save_progress()

func _input(event):
	if event.is_action_pressed("ctrl_del"):
		reset_progress()
		print("Progresso resetado!")
	elif event.is_action_pressed("ctrl_insert"):
		unlock_all_stages()
		print("Todas as fases desbloqueadas!")
