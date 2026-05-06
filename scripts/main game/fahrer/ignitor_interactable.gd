extends Interactable
# Hub station: toggles FahrerDeck.ignitor_enabled. When enabled, the next
# run's card draw is skipped (the card is "burned").

@export var unlocked: bool = true  # Wise Tree will gate this later

signal toggled(enabled: bool)

func interacted() -> void:
	if not unlocked:
		return
	FahrerDeck.ignitor_enabled = not FahrerDeck.ignitor_enabled
	toggled.emit(FahrerDeck.ignitor_enabled)
	_is_active = false  # one-shot toggle, no panel to keep open
