extends Resource
class_name CraftingStationResource

## The definition of a crafting station type (Workbench, Weapon Smith, etc.).
## Create one .tres per station type, then assign it to CraftingStationNode.

@export_category("Identity")
@export var station_name: String = "Crafting Station"
@export var icon: Texture2D

@export_category("Levels")
## One StationLevelData entry per level, in order (index 0 = level 1).
## The station starts at level 1 (levels[0]).
@export var levels: Array[StationLevelData] = []

## When true, each level automatically includes all recipes from every
## previous level so you don't have to copy them manually.
@export var inherit_previous_recipes: bool = true

## Returns the max level this station can reach.
func get_max_level() -> int:
	return levels.size()

## Returns the StationLevelData for a given 1-based level number.
func get_level_data(level: int) -> StationLevelData:
	var idx := clampi(level - 1, 0, levels.size() - 1)
	return levels[idx] if not levels.is_empty() else null

## Returns every recipe available at `level`, respecting inherit_previous_recipes.
func get_recipes_at_level(level: int) -> Array[CraftingRecipe]:
	var out: Array[CraftingRecipe] = []
	if levels.is_empty():
		return out

	if inherit_previous_recipes:
		for l in range(0, clampi(level, 1, levels.size())):
			for r in levels[l].recipes:
				if r not in out:
					out.append(r)
	else:
		var data := get_level_data(level)
		if data:
			out.assign(data.recipes)

	return out

## Returns true if the station can still be upgraded.
func can_level_up(current_level: int) -> bool:
	return current_level < get_max_level()
