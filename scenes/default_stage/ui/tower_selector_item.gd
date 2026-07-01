class_name TowerSelectorItem
extends Control

signal tower_pressed(type)

@onready var button: TextureButton = $AspectRatioContainer/TextureButton
@onready var count_label: Label = $AspectRatioContainer/TextureButton/CountLabel
@onready var button_click = $ButtonClick
@onready var button_hover = $ButtonHover

var tower_type
var _is_hovered: bool = false
var _is_selected: bool = false


func setup(texture: Texture2D, type, count: int) -> void:
	tower_type = type
	button.texture_normal = texture
	count_label.text = str(count)
	button.pressed.connect(_on_pressed)
	button.mouse_entered.connect(_on_texture_button_mouse_entered)
	button.mouse_exited.connect(_on_texture_button_mouse_exited)


func _on_pressed() -> void:
	button_click.play()
	tower_pressed.emit(tower_type)
	_is_selected = true
	_update_modulate()

func _on_texture_button_mouse_entered() -> void:
	button_hover.play()
	_is_hovered = true
	_update_modulate()

func _on_texture_button_mouse_exited() -> void:
	_is_hovered = false
	_update_modulate()

func _update_modulate() -> void:
	if _is_selected or _is_hovered:
		modulate = Color(1.8, 1.8, 1.8)
	else:
		modulate = Color.WHITE


func set_selected(value: bool) -> void:
	_is_selected = value
	_update_modulate()
