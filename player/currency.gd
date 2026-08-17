extends Node

signal changed(amount: int)

var shards: int = 0

func add(amount: int) -> void:
	if amount <= 0:
		return
	shards += amount
	changed.emit(shards)

func can_afford(cost: int) -> bool:
	return shards >= cost

func spend(cost: int) -> bool:
	if not can_afford(cost):
		return false
	shards -= cost
	changed.emit(shards)
	return true

func clear() -> void:
	shards = 0
	changed.emit(shards)
