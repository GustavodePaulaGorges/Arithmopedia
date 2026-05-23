extends TileMapLayer

func _process(_delta):
	var mouse_pos = get_local_mouse_position()
	var tile_coords = local_to_map(mouse_pos)

	if get_cell_source_id(tile_coords) != -1:
		# faz com que a tile com o slot de torre ative o mouse "apontando"
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	else:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
