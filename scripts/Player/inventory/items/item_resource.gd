extends Resource
class_name ItemResource

@export_category("checks")
@export var isWeapon := false
@export var isUsableItem := false
@export var isMaterial := false
@export var isPlaceable := false
@export var has_scale := true

@export_category("inventory_settings")
@export var isSelected: bool
@export var isEquipped: bool = false
@export var itemScene: PackedScene
@export var isStackable := false
@export var amount: int

@export_category("general_settings")
@export_enum("common", "uncommon", "rare", "epic", "legendary") var rarity
@export var txtr: Texture2D
@export var Name: String
@export var description: String
@export var scale_mod: Vector2

var inv_slot: InventorySlot = null
var resource: ItemResource

func _init() -> void:
	if itemScene != null:
		itemScene.set_resource(self)
