extends Control

@onready var stages_grid = $VBoxContainer/CenterContainer/StagesGrid
@onready var back_button = $VBoxContainer/BackButton

# Configuração das fases - facilmente escalável para novas fases
var stages = [
	{
		"id": 1,
		"name": "Fase 1",
		"scene_path": "res://scenes/fase1/fase1.tscn"
	},
	{
		"id": 2,
		"name": "Fase 2", 
		"scene_path": "res://scenes/fase2/fase2.tscn"
	},
	{
		"id": 3,
		"name": "Fase 3", 
		"scene_path": "res://scenes/fase3/fase3.tscn"
	}
]

func _ready():
	back_button.pressed.connect(_on_back_button_pressed)
	_create_stage_buttons()
	
	if has_node("/root/ProgressManager"):
		var progress_manager = get_node("/root/ProgressManager")
		if progress_manager.has_signal("stage_completed"):
			progress_manager.stage_completed.connect(_on_stage_completed)
		if progress_manager.has_signal("stage_unlocked"):
			progress_manager.stage_unlocked.connect(_on_stage_unlocked)

func _create_stage_buttons():
	# Limpa botões existentes
	for child in stages_grid.get_children():
		child.queue_free()
	
	# Configura o StagesGrid para centralizar os filhos
	stages_grid.add_theme_constant_override("h_separation", 20)
	stages_grid.add_theme_constant_override("v_separation", 20)
	
	# Cria botões para cada fase
	for stage_data in stages:
		var stage_button = Button.new()
		stage_button.custom_minimum_size = Vector2(80, 80)
		stage_button.text = stage_data.name
		stage_button.add_theme_font_size_override("font_size", 24)
		
		# Aplica a fonte PixelifySans
		var font = load("res://assets/fonts/PixelifySans-VariableFont_wght.ttf")
		stage_button.add_theme_font_override("font", font)
		
		# Configura Container Sizing para centralização no GridContainer
		stage_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		stage_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		# Configura aparência baseada no status da fase
		var progress_manager = get_node_or_null("/root/ProgressManager")
		if progress_manager and progress_manager.is_stage_unlocked(stage_data.id):
			if progress_manager and progress_manager.is_stage_completed(stage_data.id):
				stage_button.modulate = Color.GREEN
			else:
				stage_button.modulate = Color.WHITE
			stage_button.pressed.connect(_on_stage_button_pressed.bind(stage_data))
		else:
			stage_button.modulate = Color.GRAY
			stage_button.disabled = true
			stage_button.text = "???"
		
		stages_grid.add_child(stage_button)

func _on_stage_button_pressed(stage_data):
	print("Iniciando: ", stage_data.name)
	var progress_manager = get_node_or_null("/root/ProgressManager")
	if progress_manager:
		progress_manager.current_stage = stage_data.id
	get_tree().change_scene_to_file(stage_data.scene_path)

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")

# Função para adicionar novas fases dinamicamente
func add_stage(id: int, name: String, scene_path: String):
	var new_stage = {
		"id": id,
		"name": name,
		"scene_path": scene_path
	}
	stages.append(new_stage)
	_create_stage_buttons()

# Atualiza a UI quando uma fase é completada
func _on_stage_completed(stage_id: int):
	_create_stage_buttons()

# Atualiza a UI quando uma fase é desbloqueada
func _on_stage_unlocked(stage_id: int):
	_create_stage_buttons()
