extends Projectile

# Grows from tiny to full size over its lifetime, making it appear to "charge up"
# as it slowly travels. Used by the Wandering Eye spirit.
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if lifetime > 0.0:
		var t: float = clamp(_elapsed / lifetime, 0.0, 1.0)
		var s: float = lerp(0.05, 1.0, t)
		scale = Vector2(s, s)
