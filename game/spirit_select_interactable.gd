extends Interactable

func interacted():
	if _is_active:
		close_interaction()
		return
	_is_active = true
	GlobalPlayer.inventory.spirit_select_ui.open()

func close_interaction():
	super.close_interaction()
	GlobalPlayer.inventory.spirit_select_ui.close()
