extends Node2D
class_name PlayerInv

var occupiedSlots: int
@onready var safe_ui: SafeUI = $SafeUi
@onready var spirit_select_ui: SpiritSelectUI = $SpiritSelectUi
@onready var inventory: ActualInv = $InventoryLayer/Inventory
