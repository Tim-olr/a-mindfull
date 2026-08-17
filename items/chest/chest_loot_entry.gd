extends Resource
class_name ChestLootEntry

@export var item: ItemResource
@export var min_count: int = 1
@export var max_count: int = 1
## Higher weight = more likely to be selected relative to other entries.
@export var weight: float = 1.0
