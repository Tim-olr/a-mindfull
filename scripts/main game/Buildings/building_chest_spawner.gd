extends Node2D

## PackedScene pointing to chest.tscn. Set this in the Inspector on SmallBuilding.
@export var chest_scene: PackedScene
## 0.0 = never spawn, 1.0 = always spawn.
@export var spawn_chance: float = 0.65
## Optional: override the loot pool on the spawned chest.
@export var loot_pool_override: ChestLootPool

## Interior safe bounds for small_building.tscn (pixels from building origin).
const INTERIOR_X_MIN := 80
const INTERIOR_X_MAX := 420
const INTERIOR_Y_MIN := 60
const INTERIOR_Y_MAX := 320

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	if chest_scene == null:
		return
	_rng.randomize()
	if _rng.randf() > spawn_chance:
		return

	var chest = chest_scene.instantiate()
	chest.position = Vector2(
		_rng.randi_range(INTERIOR_X_MIN, INTERIOR_X_MAX),
		_rng.randi_range(INTERIOR_Y_MIN, INTERIOR_Y_MAX)
	)

	if loot_pool_override != null:
		var interactable: ChestInteractable = chest.find_child("ChestInteractable", true, false)
		if interactable != null:
			interactable.loot_pool = loot_pool_override

	add_child(chest)
