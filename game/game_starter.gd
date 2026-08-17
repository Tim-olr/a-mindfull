extends Interactable

@onready var timer: Timer = $Timer

func interacted():
	GameManager.gameStarted = true
	GlobalSafe.saved_inventory.clear()
	for slot in GlobalPlayer.inventory.inventory.slots:
		if slot.item != null:
			GlobalSafe.saved_inventory.append({
				"slot_index": slot.slot_index,
				"item": slot.item,
				"count": slot.item.amount
			})
	timer.start()
	GlobalPlayer.visuals.showBlack()

func _on_timer_timeout() -> void:
	get_tree().change_scene_to_file("res://world/the_world.tscn")
