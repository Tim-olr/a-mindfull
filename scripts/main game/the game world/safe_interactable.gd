extends Interactable

func interacted():
	GlobalPlayer.inventory.safe_ui.open()
