extends ShopStationNode

@export var cost: float

func buy() -> void:
	if GlobalPlayer.stats.shards >= cost:
		if GlobalPlayer.stats.hp == GlobalPlayer.stats.maxHp:
			return
		GlobalPlayer.stats.remove_shards(cost)
		GlobalPlayer.manager.heal(50)
