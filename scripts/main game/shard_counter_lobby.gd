extends Node2D

@onready var amount_label: Label = $amount

func _ready() -> void:
	change_amount(0)

func change_amount(amount):
	if amount > 0:
		pass #implement nice add up thingy
	elif amount < 0:
		pass # implement nice decrease thingy
	amount_label.text = str(GlobalSafe.shards)
