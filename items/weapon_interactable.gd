extends ItemInteractable
class_name WeaponInteractable

## Shard cost to buy this weapon. 0 = free pickup (same as a plain ItemInteractable).
@export var cost: int = 0

func interacted() -> void:
	if cost > 0 and not Currency.spend(cost):
		return
	super.interacted()
