extends DungeonRoom
class_name ItemRoom

@export var artifact_pool: ArtifactLootPool
@export var upgrade_interactable_scene: PackedScene = preload("res://items/upgrade_interactable.tscn")

func _ready() -> void:
	if artifact_pool == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var luck: float = GlobalPlayer.stats.luck if GlobalPlayer.stats else 0.0
	var artifact := artifact_pool.roll_artifact(rng, luck)
	if artifact == null:
		return
	var interactable: UpgradeInteractable = upgrade_interactable_scene.instantiate()
	interactable.artifact = artifact
	interactable.position = room_size / 2.0
	add_child(interactable)
