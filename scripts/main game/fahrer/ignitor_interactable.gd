extends Interactable
# Hub station: toggles FahrerDeck.ignitor_enabled. When enabled, the next
# run's card draw is skipped (the card is "burned").

signal toggled(enabled: bool)

func interacted() -> void:
	if not WiseTree.is_unlocked("unlock_ignitor"):
		return
	FahrerDeck.ignitor_enabled = not FahrerDeck.ignitor_enabled
	toggled.emit(FahrerDeck.ignitor_enabled)
	_is_active = false
