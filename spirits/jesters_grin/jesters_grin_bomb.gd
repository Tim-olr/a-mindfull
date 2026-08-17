extends PhysicsObject

var can_damage := false
@onready var explode_area: Area2D = $ExplodeArea
@onready var explosionanim: AnimatedSprite2D = $ExplodeArea/explosionanim

func _ready() -> void:
	super()
	explosionanim.play("nun")

func on_touch(area):
	if area.is_in_group("enemy"):
		can_damage = true
		explode()

func explode():
	can_damage = true

func _process(_delta: float) -> void:
	if can_damage:
		explosionanim.play("default")
		for b in explode_area.get_overlapping_areas():
			if is_instance_valid(b):
				if b.is_in_group("enemy") or b.is_in_group("spirit"):
					b.get_parent().damage(50, self, 0)
				if b.is_in_group("player"):
					b.get_parent().manager.damage(50, self, 0)
		await explosionanim.animation_finished
		queue_free()
