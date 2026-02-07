extends Node2D
class_name PlayerInv

var occupiedSlots: int
@onready var inventory: ActualInv = $Inventory

func setPlayerInvToGlobal():
	GlobalPlayer.inventory.inventory = GlobalSafe.currentInventory

func setGlobalInv():
	GlobalSafe.currentInventory = GlobalPlayer.inventory.inventory
