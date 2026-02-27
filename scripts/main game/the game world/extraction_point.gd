extends Interactable

func interacted():
	for slot: InventorySlot in GlobalPlayer.inventory.inventory.slots_with_items.duplicate():
		GlobalPlayer.inventory.inventory.slots_with_items.erase(slot)
		GlobalSafe.safe.append(slot.item)
	get_tree().change_scene_to_file("res://spirit-game-project/scenes/main game/game.tscn")
