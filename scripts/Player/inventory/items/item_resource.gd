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
@export_enum("common", "uncommon", "rare", "epic", "legendary") var rarity: int
@export var txtr: Texture2D
@export var Name: String
@export var description: String
@export var scale_mod: Vector2

var inv_slot: InventorySlot = null
var rarity_applied: bool = false

var bonus_damage:       float   = 0.0
var bonus_speed:        float   = 0.0
var bonus_cooldown_sub: float   = 0.0
var bonus_lifetime:     float   = 0.0
var bonus_amount:       int     = 0
var bonus_size:         float   = 0.0

func calculate_rarity_outline():
	match rarity:
		0: return Color.WHITE
		1: return Color.GREEN
		2: return Color.BLUE
		3: return Color.PURPLE
		4: return Color.ORANGE
		_: return Color.WHITE
