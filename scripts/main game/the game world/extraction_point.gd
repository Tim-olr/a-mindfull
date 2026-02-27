extends Interactable
func interacted():
	for slot in GlobalPlayer.inventory.inventory.slots_with_items.duplicate():
		var inv_item = slot.item
		if inv_item == null:
			continue
		var count = slot.item_count
		if inv_item.isStackable:
			var found = false
			for safe_item in GlobalSafe.safe:
				if safe_item.Name == inv_item.Name:
					safe_item.amount += count
					found = true
					break
			if not found:
				var dup = inv_item.duplicate()
				dup.amount = count
				GlobalSafe.safe.append(dup)
		else:
			GlobalSafe.safe.append(inv_item.duplicate())
	get_tree().change_scene_to_file("res://spirit-game-project/scenes/main game/game.tscn")
