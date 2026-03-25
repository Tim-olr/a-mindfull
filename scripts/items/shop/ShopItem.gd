extends Resource
class_name ShopItem

enum PriceType { SHARDS, ITEMS, FREE }

@export_category("Item")
@export var item_resource: ItemResource
@export var amount: int = 1
@export var icon_override: Texture2D   ## Optional; falls back to item_resource.txtr

@export_category("Price")
@export var price_type: PriceType = PriceType.SHARDS
@export var shard_price: float = 0.0
@export var item_costs: Array[IngredientData] = []  ## Used when price_type == ITEMS

@export_category("Stock")
## -1 = infinite stock
@export var stock: int = -1

@export_category("Display")
@export var display_name_override: String = ""  ## Shown in UI; falls back to item_resource.Name
@export var description: String = ""

func get_display_name() -> String:
	return display_name_override if display_name_override != "" else (item_resource.Name if item_resource else "???")

func get_icon() -> Texture2D:
	if icon_override:
		return icon_override
	if item_resource:
		return item_resource.txtr
	return null

func is_in_stock() -> bool:
	return stock == -1 or stock > 0
