extends Node
class_name Item

var resource: ItemResource

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("attack") and resource.isSelected:
		use()
	if resource.isStackable:
		if resource.amount <= 0:
			resource.inv_slot.deselect()
			GlobalPlayer.inventory.inventory.slots_with_items.erase(resource.inv_slot)
			resource.inv_slot.set_item(null)
			resource.inv_slot = null
			queue_free()

func use():
	if resource.isUsableItem:
		if resource.isStackable:
			if do_thing():
				resource.inv_slot.update_visuals()
				decrease_amount(1)
	if resource.isMaterial:
		pass

func do_thing():
	pass

func decrease_amount(amount):
	if resource.amount > amount:
		resource.amount -= amount
	elif resource.amount == amount:
		resource.inv_slot.set_item(null)
		resource.inv_slot = null
