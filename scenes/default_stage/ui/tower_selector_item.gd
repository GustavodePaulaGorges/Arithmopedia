class_name TowerSelectorItem
extends Control

signal tower_pressed(type)

@onready var button: TextureButton = $AspectRatioContainer/TextureButton
@onready var count_label: Label = $AspectRatioContainer/TextureButton/CountLabel

var tower_type


func setup(texture: Texture2D, type, count: int) -> void:
	tower_type = type
	button.texture_normal = texture
	count_label.text = str(count)
	button.pressed.connect(_on_pressed)


func _on_pressed() -> void:
	tower_pressed.emit(tower_type)


func set_selected(value: bool) -> void:
	modulate = Color(1.8, 1.8, 1.8) if value else Color.WHITE
