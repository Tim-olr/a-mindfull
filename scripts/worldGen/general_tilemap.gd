extends TileMapLayer

func gen_collisions():
	var filled_tiles := get_used_cells()
	for filled_tile: Vector2 in filled_tiles:
		var neighboring_tiles := get_surrounding_cells(filled_tile)
		for neighbor in neighboring_tiles:
			if get_cell_source_id(neighbor) == -1:
				print("n: ", neighbor)
				set_cell(neighbor, 0, Vector2i(6, 64))
