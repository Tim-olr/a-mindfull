extends Label

func _ready() -> void:
	Currency.changed.connect(_on_changed)
	_on_changed(Currency.shards)

func _on_changed(amount: int) -> void:
	text = "Shards: %d" % amount
