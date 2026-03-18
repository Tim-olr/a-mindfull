extends Area2D
class_name CraftingStationNode

## ─────────────────────────────────────────────
##  CraftingStationNode
##  Place as an Area2D in your level with a CollisionShape2D.
##  Assign a CraftingStationResource in the Inspector.
##  The player must be in the "player" group.
## ─────────────────────────────────────────────

signal station_opened(station: CraftingStationNode)
signal station_closed(station: CraftingStationNode)
signal station_upgraded(station: CraftingStationNode, new_level: int)

@export var station_resource: CraftingStationResource

## Persisted current level (save/load alongside your save data).
@export var current_level: int = 1

## Action name in your Input Map that opens/closes the station.
@export var interact_action: String = "interact"

## Assign your CraftingUI node here.
@export var crafting_ui: CraftingUI

var _player_inside: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	current_level = clampi(current_level, 1, _max_level())


func _unhandled_input(event: InputEvent) -> void:
	if _player_inside and event.is_action_pressed("interact"):
		if crafting_ui and not crafting_ui.visible:
			open_ui()
		elif crafting_ui and crafting_ui.visible:
			close_ui()


# ── Public API ────────────────────────────────

func open_ui() -> void:
	if crafting_ui:
		crafting_ui.open_for_station(self)
	station_opened.emit(self)


func close_ui() -> void:
	if crafting_ui:
		crafting_ui.close()
	station_closed.emit(self)


func get_current_recipes() -> Array[CraftingRecipe]:
	if station_resource == null:
		return []
	return station_resource.get_recipes_at_level(current_level)


func get_current_level_data() -> StationLevelData:
	if station_resource == null:
		return null
	return station_resource.get_level_data(current_level)


func can_upgrade() -> bool:
	if station_resource == null or not station_resource.can_level_up(current_level):
		return false

	var data := get_current_level_data()
	if data == null:
		return false

	if data.upgrade_needs_shards:
		if Crafting.available_shards() < data.upgrade_shard_cost:
			return false

	for ingredient in data.upgrade_ingredients:
		if ingredient == null or ingredient.item_resource == null:
			continue
		if Crafting.get_material_count(ingredient.item_resource) < ingredient.amount:
			return false

	return true


func upgrade() -> bool:
	if not can_upgrade():
		return false

	var data := get_current_level_data()

	for ingredient in data.upgrade_ingredients:
		if ingredient == null or ingredient.item_resource == null:
			continue
		Crafting._consume_material(ingredient.item_resource, ingredient.amount)

	if data.upgrade_needs_shards:
		Crafting._consume_shards(data.upgrade_shard_cost)

	current_level += 1
	station_upgraded.emit(self, current_level)

	if crafting_ui and crafting_ui.visible:
		crafting_ui.open_for_station(self)

	return true


func get_display_name() -> String:
	var base := station_resource.station_name if station_resource else "Station"
	return "%s  Lv.%d / %d" % [base, current_level, _max_level()]


# ── Private ───────────────────────────────────

func _max_level() -> int:
	return station_resource.get_max_level() if station_resource else 1


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = true


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = false
		close_ui()
