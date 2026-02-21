extends Resource
class_name ItemResource

@export_category("checks")
@export var isWeapon := false
@export var isUsableItem := false
@export var isMaterial := false
@export var isPlaceable := false

@export_category("inventory_settings")
@export var isSelected: bool
@export var itemScene: PackedScene
@export var isStackable := false
@export var amount: int

@export_category("general_settings")
@export_enum("common", "uncommon", "rare", "epic", "legendary") var rarity
@export var txtr: Texture2D
@export var Name: String
@export var description: String
