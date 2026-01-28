extends Node2D
class_name PlayerInv

var inventory := []
var slotAmount: int
var occupiedSlots: int

func addToInventory(item, amount):
	if inventory.has(item):
		var invItem = inventory.get(item)
		if invItem.canStack:
			invItem.stack += amount
		else:
			pass
	elif occupiedSlots < slotAmount:
		inventory.append(item)
	else:
		pass # make it so it gives a red pop up or sum like that
	setGlobalInv()

func setPlayerInvToGlobal():
	GlobalPlayer.inventory.inventory = GlobalSafe.currentInventory

func setGlobalInv():
	GlobalSafe.currentInventory = GlobalPlayer.inventory.inventory
