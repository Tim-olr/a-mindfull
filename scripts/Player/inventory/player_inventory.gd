extends Node2D

var inventory := []

func addToInventory(item, amount):
	if inventory.has(item):
		var invItem = inventory.get(item)
		if invItem.canStack:
			invItem.stack += amount
		else:
			pass
	else:
		inventory.append(item)
	setGlobalInv()

func setPlayerInvToGlobal():
	GlobalPlayer.inventory.inventory = GlobalSafe.currentInventory

func setGlobalInv():
	GlobalSafe.currentInventory = GlobalPlayer.inventory.inventory
