extends Item

func do_thing():
	if GlobalPlayer.manager.heal(20):
		return true
	return false
