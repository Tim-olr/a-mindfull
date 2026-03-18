extends Node
class_name CraftingManager

## ─────────────────────────────────────────────
##  CraftingManager  (Autoload name: "Crafting")
##
##  When GameManager.is_in_hub is true, material counts and shard
##  totals include both the player's inventory/shards AND GlobalSafe.
##  Consumption drains the player first, then spills into the safe.
## ─────────────────────────────────────────────

signal craft_succeeded(recipe: CraftingRecipe, station: CraftingStationNode)
signal craft_failed(recipe: CraftingRecipe, reason: String)


# ════════════════════════════════════════════════
#  Public API
# ════════════════════════════════════════════════

func can_craft(recipe: CraftingRecipe) -> bool:
	if recipe == null:
		return false
	if recipe.needs_shards and available_shards() < recipe.shard_cost:
		return false
	for ingredient in recipe.ingredients:
		if ingredient == null or ingredient.item_resource == null:
			continue
		if get_material_count(ingredient.item_resource) < ingredient.amount:
			return false
	return true


func craft(recipe: CraftingRecipe, station: CraftingStationNode = null) -> bool:
	if not can_craft(recipe):
		craft_failed.emit(recipe, _failure_reason(recipe))
		return false

	for ingredient in recipe.ingredients:
		if ingredient == null or ingredient.item_resource == null:
			continue
		_consume_material(ingredient.item_resource, ingredient.amount)

	if recipe.needs_shards:
		_consume_shards(recipe.shard_cost)

	_give_item(recipe.result_item, recipe.result_amount)
	craft_succeeded.emit(recipe, station)
	return true


## Total of this material across inventory (+ safe when in hub).
func get_material_count(item_res: ItemResource) -> int:
	var total := _count_in_inventory(item_res)
	if _in_hub():
		total += _count_in_safe(item_res)
	return total


## All unique materials the player is carrying (+ safe when in hub).
func get_all_materials() -> Array:
	var found: Array   = []
	var seen: Array[String] = []

	for slot in _inv_slots():
		var held: ItemResource = slot.item
		if held == null or not held.isMaterial:
			continue
		if held.Name not in seen:
			seen.append(held.Name)
			found.append(held)

	if _in_hub():
		for item in GlobalSafe.safe:
			if item == null or not item.isMaterial:
				continue
			if item.Name not in seen:
				seen.append(item.Name)
				found.append(item)

	return found


## Combined shards available (player + safe when in hub).
func available_shards() -> float:
	if _in_hub():
		return GlobalPlayer.stats.shards + GlobalSafe.shards
	return GlobalPlayer.stats.shards


# ════════════════════════════════════════════════
#  Internal — called by CraftingStationNode too
# ════════════════════════════════════════════════

func _consume_material(item_res: ItemResource, amount: int) -> void:
	# Always drain inventory first
	var remaining := _consume_from_inventory(item_res, amount)
	# Spill into safe only when in hub
	if remaining > 0 and _in_hub():
		_consume_from_safe(item_res, remaining)


func _consume_shards(amount: float) -> void:
	var from_player := minf(amount, GlobalPlayer.stats.shards)
	GlobalPlayer.stats.shards -= from_player
	GlobalPlayer.stats.shard_counter.change_amount(0)

	var remainder := amount - from_player
	if remainder > 0.0 and _in_hub():
		GlobalSafe.decrease_shards(remainder)


func _give_item(item_res: ItemResource, amount: int) -> void:
	if item_res == null:
		return
	var new_res: ItemResource = item_res.duplicate(true)
	if new_res.isStackable:
		new_res.amount = amount
	if GlobalPlayer.inventory and GlobalPlayer.inventory.inventory.has_method("add_item"):
		GlobalPlayer.inventory.inventory.add_item(new_res)
	else:
		push_warning("CraftingManager: GlobalPlayer.inventory has no add_item() — wire _give_item() to your inventory's method.")


# ════════════════════════════════════════════════
#  Private helpers
# ════════════════════════════════════════════════

func _in_hub() -> bool:
	return GameManager.is_in_lobby


func _inv_slots() -> Array:
	if GlobalPlayer.inventory == null:
		return []
	var inv = GlobalPlayer.inventory.inventory
	if inv == null:
		return []
	return inv.slots_with_items


func _count_in_inventory(item_res: ItemResource) -> int:
	var total := 0
	for slot in _inv_slots():
		if slot == null:
			continue
		var held: ItemResource = slot.item
		if held == null or held.Name != item_res.Name:
			continue
		total += held.amount if held.isStackable else 1
	return total


func _count_in_safe(item_res: ItemResource) -> int:
	var total := 0
	for item in GlobalSafe.safe:
		if item == null or item.Name != item_res.Name:
			continue
		total += item.amount if item.isStackable else 1
	return total


func _consume_from_inventory(item_res: ItemResource, amount: int) -> int:
	# Returns how many still need to be consumed (i.e. 0 if fully consumed).
	var remaining := amount
	var inv = GlobalPlayer.inventory.inventory if GlobalPlayer.inventory else null
	if inv == null:
		return remaining

	for slot in inv.slots_with_items.duplicate():
		if remaining <= 0:
			break
		if slot == null:
			continue
		var held: ItemResource = slot.item
		if held == null or held.Name != item_res.Name:
			continue
		if held.isStackable:
			if held.amount <= remaining:
				remaining -= held.amount
				inv.slots_with_items.erase(slot)
				slot.set_item(null)
			else:
				held.amount -= remaining
				remaining = 0
				slot.update_visuals()
		else:
			remaining -= 1
			inv.slots_with_items.erase(slot)
			slot.set_item(null)

	return remaining


func _consume_from_safe(item_res: ItemResource, amount: int) -> void:
	var remaining := amount
	for i in range(GlobalSafe.safe.size() - 1, -1, -1):
		if remaining <= 0:
			break
		var item: ItemResource = GlobalSafe.safe[i]
		if item == null or item.Name != item_res.Name:
			continue
		if item.isStackable:
			if item.amount <= remaining:
				remaining -= item.amount
				GlobalSafe.safe.remove_at(i)
			else:
				item.amount -= remaining
				remaining = 0
		else:
			remaining -= 1
			GlobalSafe.safe.remove_at(i)


func _failure_reason(recipe: CraftingRecipe) -> String:
	if recipe.needs_shards and available_shards() < recipe.shard_cost:
		return "Need %.0f shards (have %.0f)" % [recipe.shard_cost, available_shards()]
	for ingredient in recipe.ingredients:
		if ingredient == null or ingredient.item_resource == null:
			continue
		var have := get_material_count(ingredient.item_resource)
		if have < ingredient.amount:
			return "Need %s x%d (have %d)" % [ingredient.item_resource.Name, ingredient.amount, have]
	return "Unknown"
