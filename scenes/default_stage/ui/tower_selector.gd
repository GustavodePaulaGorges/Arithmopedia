class_name TowerSelector
extends Control

signal tower_selected(type)

@onready var hbox: HBoxContainer = $MarginContainer/HBoxContainer

const ITEM_WIDTH: int = 32
const ITEM_HEIGHT: int = 64
const ITEM_SEPARATION: int = 4

var item_scene: PackedScene = preload("res://scenes/default_stage/ui/tower_selector_item.tscn")

var tower_configs: Dictionary = {
	TowerTypes.TowerType.ADDITION: {
		"texture": preload("res://assets/sprites/TorreAdd.png")
	},
	TowerTypes.TowerType.SUBTRACTION: {
		"texture": preload("res://assets/sprites/TorreSub.png")
	},
	TowerTypes.TowerType.MULTIPLICATION: {
		"texture": preload("res://assets/sprites/TorreMult.png")
	},
	TowerTypes.TowerType.DIVISION: {
		"texture": preload("res://assets/sprites/TorreDiv.png")
	},
	TowerTypes.TowerType.POTENTIATION: {
		"texture": preload("res://assets/sprites/TorrePot.png")
	},
	TowerTypes.TowerType.RADICATION: {
		"texture": preload("res://assets/sprites/TorreRad.png")
	},
	TowerTypes.TowerType.DOUBLING: {
		"texture": preload("res://assets/sprites/TorreDup.png")
	}
}

var selected_tower


func update_ui(tower_count: Dictionary) -> void:
	for child in hbox.get_children():
		child.queue_free()

	var visible_count: int = 0

	for tower_type in tower_count.keys():
		var count: int = tower_count[tower_type]

		if count <= 0:
			continue

		if not tower_configs.has(tower_type):
			continue

		var item: TowerSelectorItem = item_scene.instantiate()

		hbox.add_child(item)

		item.setup(
			tower_configs[tower_type].texture,
			tower_type,
			count
		)

		item.tower_pressed.connect(_on_item_pressed)
		visible_count += 1

	_resize_to_items(visible_count)

	if selected_tower == null or tower_count.get(selected_tower, 0) <= 0:
		for tower_type in tower_count.keys():
			if tower_count[tower_type] > 0:
				selected_tower = tower_type
				tower_selected.emit(selected_tower)
				break

	_update_selection()


func _on_item_pressed(type) -> void:
	selected_tower = type
	_update_selection()
	tower_selected.emit(type)


func _update_selection() -> void:
	for item in hbox.get_children():
		item.set_selected(item.tower_type == selected_tower)


func _resize_to_items(visible_count: int) -> void:
	var width: int = 0
	if visible_count > 0:
		width = visible_count * ITEM_WIDTH + (visible_count - 1) * ITEM_SEPARATION
	custom_minimum_size = Vector2(width, ITEM_HEIGHT)
	offset_left = offset_right - width
	offset_top = offset_bottom - ITEM_HEIGHT
