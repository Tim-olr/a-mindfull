extends Node2D

@export var amount_label: Label

func _ready() -> void:
	change_amount(0)

func change_amount(amount):
	if amount > 0:
		pass #implement nice add up thingy
	elif amount < 0:
		pass # implement nice decrease thingy
	if !is_instance_valid(amount_label):
		amount_label = Label.new()
	amount_label.text = str(GlobalSafe.shards)
