extends Resource
class_name CraftingRecipe

@export_category("Result")
@export var recipe_name: String = "New Recipe"
@export var result_item: ItemResource
@export var result_amount: int = 1

@export_category("Ingredients")
@export var ingredients: Array[IngredientData] = []

@export_category("Shard Cost")
@export var needs_shards: bool = false
@export var shard_cost: float = 0.0

@export_category("Display")
@export var icon: Texture2D
@export var description: String = ""

func get_icon() -> Texture2D:
	if icon:
		return icon
	if result_item:
		return result_item.txtr
	return null
