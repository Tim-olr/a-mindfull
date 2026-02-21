extends Resource
class_name MineableBlockResource

@export_category("identification")
@export var atlas_coord: Vector2i = Vector2i.ZERO
@export var source_id: int = 0

@export_category("mining")
@export var hardness: float = 1.0
@export var required_pickaxe_tier: int = 0

@export_category("drops")
@export var drops: Array[DropEntry] = []

func roll_drops() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for drop in drops:
		if randf() <= drop.chance:
			var count := randi_range(drop.min_count, drop.max_count)
			result.append({"item": drop.item, "count": count})
	return result
