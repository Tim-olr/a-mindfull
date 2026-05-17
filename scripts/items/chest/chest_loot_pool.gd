extends Resource
class_name ChestLootPool

@export var entries: Array[ChestLootEntry] = []
@export var min_items: int = 1
@export var max_items: int = 3

## Returns an Array of Dictionary: { "item": ItemResource, "count": int }
## luck (0.0–∞) boosts the effective weight of rarer items:
##   effective_weight = base_weight * (1 + luck * rarity * 0.5)
func roll_loot(rng: RandomNumberGenerator, luck: float = 0.0) -> Array:
	var result: Array = []
	if entries.is_empty():
		return result

	# Build effective weights, boosting higher-rarity items when luck > 0
	var effective_weights: Array = []
	var total_weight: float = 0.0
	for e in entries:
		var w := maxf(0.0, e.weight)
		if luck > 0.0 and e.item != null:
			var rarity: int = e.item.get("rarity") if e.item.get("rarity") != null else 0
			w *= (1.0 + luck * rarity * 0.5)
		effective_weights.append(w)
		total_weight += w

	if total_weight <= 0.0:
		return result

	var count := rng.randi_range(min_items, max_items)
	for _i in count:
		var roll := rng.randf() * total_weight
		var cumulative := 0.0
		for j in entries.size():
			cumulative += effective_weights[j]
			if roll <= cumulative:
				if entries[j].item != null:
					result.append({
						"item": entries[j].item,
						"count": rng.randi_range(entries[j].min_count, entries[j].max_count)
					})
				break

	return result
