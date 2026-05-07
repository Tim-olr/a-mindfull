extends Resource
class_name ChestLootPool

@export var entries: Array[ChestLootEntry] = []
@export var min_items: int = 1
@export var max_items: int = 3

## Returns an Array of Dictionary: { "item": ItemResource, "count": int }
func roll_loot(rng: RandomNumberGenerator) -> Array:
	var result: Array = []
	if entries.is_empty():
		return result

	var total_weight: float = 0.0
	for e in entries:
		total_weight += maxf(0.0, e.weight)
	if total_weight <= 0.0:
		return result

	var count := rng.randi_range(min_items, max_items)
	for _i in count:
		var roll := rng.randf() * total_weight
		var cumulative := 0.0
		for e in entries:
			cumulative += maxf(0.0, e.weight)
			if roll <= cumulative:
				if e.item != null:
					result.append({
						"item": e.item,
						"count": rng.randi_range(e.min_count, e.max_count)
					})
				break

	return result
