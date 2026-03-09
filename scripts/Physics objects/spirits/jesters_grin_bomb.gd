extends PhysicsObject

var can_damage := false
@onready var explode_area: Area2D = $ExplodeArea

func on_touch(area):
	if area.is_in_group("enemy"):
		can_damage = true
		explode()

func explode():
	can_damage = true

func _process(_delta: float) -> void:
	if can_damage:
		for b in explode_area.get_overlapping_areas():
			if b.is_in_group("enemy") or b.is_in_group("spirit"):
				b.get_parent().damage(50, self, 0)
			if b.is_in_group("player"):
				b.get_parent().manager.damage(50, self, 0)
			queue_free()
