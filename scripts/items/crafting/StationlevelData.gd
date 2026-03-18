extends Resource
class_name StationLevelData

## Data for one level of a crafting station.
## Add one of these per level in your CraftingStationResource.

@export_category("Recipes")
## All recipes available once the station reaches this level.
## Higher levels typically include everything from previous levels too —
## just duplicate the lower-level recipes into the array, or set
## inherit_previous_recipes = true on CraftingStationResource.
@export var recipes: Array[CraftingRecipe] = []

@export_category("Upgrade Cost (to reach the NEXT level)")
## Materials needed to upgrade FROM this level to the next.
## Leave empty if this is the max level.
@export var upgrade_ingredients: Array[IngredientData] = []
@export var upgrade_needs_shards: bool = false
@export var upgrade_shard_cost: float = 0.0

@export_category("Display")
@export var level_name: String = ""        ## Optional flavour name, e.g. "Apprentice"
@export var level_description: String = "" ## Shown in the upgrade panel
