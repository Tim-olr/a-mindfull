extends Interactable

func _ready() -> void:
	# Deferred so FogOfWar's tilemap is already registered before we convert world→tile
	call_deferred("_register_beacon")

func _register_beacon() -> void:
	FogOfWar.register_extraction_point(global_position)

func interacted():
	# Bring every carried weapon home to the hub safe.
	for slot in GlobalPlayer.inventory.inventory.slots_with_items.duplicate():
		var inv_item = slot.item
		if inv_item == null:
			continue
		GlobalSafe.safe.append(inv_item.duplicate())
	get_tree().change_scene_to_file("res://game/game.tscn")
