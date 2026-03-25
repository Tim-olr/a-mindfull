extends Node
class_name Item

@export var resource: ItemResource
var isSelected: bool

func _process(_delta: float) -> void:
	if not is_instance_valid(resource):
		return
	if Input.is_action_just_pressed("attack") and resource.isSelected:
		use()
	if resource.isStackable:
		if resource.amount <= 0:
			var slot = resource.inv_slot
			resource.inv_slot = null
			if is_instance_valid(slot):
				slot.deselect()
				GlobalPlayer.inventory.inventory.slots_with_items.erase(slot)
				slot.set_item(null)
			queue_free()
			set_process(false)

func use():
	if not is_instance_valid(resource):
		return
	if resource.isUsableItem:
		if resource.isStackable:
			if do_thing():
				if is_instance_valid(resource.inv_slot):
					resource.inv_slot.update_visuals()
				decrease_amount(1)
	if resource.isMaterial:
		pass

func do_thing():
	pass

func decrease_amount(amount):
	if not is_instance_valid(resource):
		return
	if resource.amount > amount:
		resource.amount -= amount
	elif resource.amount == amount:
		var slot = resource.inv_slot
		resource.inv_slot = null
		if is_instance_valid(slot):
			slot.set_item(null)

func initialize(item_resource: ItemResource) -> void:
	resource = item_resource
