extends DungeonRoom
class_name ShopRoom

@export var weapon_pool: ChestLootPool
@export var weapon_interactable_scene: PackedScene = preload("res://items/weapon_interactable.tscn")
@export var base_price: int = 20
@export var price_per_rarity: int = 15

func _ready() -> void:
	if weapon_pool == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var luck: float = GlobalPlayer.stats.luck if GlobalPlayer.stats else 0.0
	var offers := weapon_pool.roll_loot(rng, luck)
	if offers.is_empty():
		return
	var spacing := room_size.x / (offers.size() + 1.0)
	for i in offers.size():
		var item: ItemResource = offers[i]["item"]
		if item == null:
			continue
		var interactable: WeaponInteractable = weapon_interactable_scene.instantiate()
		interactable.item = item
		interactable.cost = base_price + int(item.rarity) * price_per_rarity
		interactable.position = Vector2(spacing * (i + 1), room_size.y / 2.0)
		add_child(interactable)
