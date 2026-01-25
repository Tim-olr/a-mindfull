extends CharacterBody2D
class_name Projectile

@onready var life_time: Timer = $LifeTime

var rot
@export var damage: float
@export var lifetime: float
@export var projectileSpeed: float
@export var pierce: int
@onready var collision_area: Area2D = $CollisionArea
var shooter_group: String = ""

var targets_hit: Array[Node] = []

func _ready() -> void:
	life_time.start(lifetime)
	collision_area.body_entered.connect(_on_obstacle_entered)
	collision_area.area_entered.connect(_on_obstacle_entered)
	collision_area.body_exited.connect(_on_obstacle_exited)
	collision_area.area_exited.connect(_on_obstacle_exited)

func _on_obstacle_entered(body: Node):
	if body.is_in_group(shooter_group):
		return
	if body.is_in_group("enemy") or body.is_in_group("player"):
		if not targets_hit.has(body):
			hit(body)
	elif body.is_in_group("wall"):
		go_away()

func _on_obstacle_exited(body: Node):
	if targets_hit.has(body):
		targets_hit.erase(body)

func go_away():
	queue_free()

func do_damage(hitBody):
	if hitBody.is_in_group("enemy"):
		if hitBody.has_method("damage"):
			hitBody.damage(damage)
		elif hitBody.get_parent().has_method("damage"):
			hitBody.get_parent().damage(damage)
		targets_hit.append(hitBody)
		pierce -= 1
		if pierce <= 0:
			go_away()
	elif hitBody.is_in_group("player"):
		if hitBody.manager.has_method("damage"):
			hitBody.manager.damage(damage)
		elif hitBody.get_parent().manager.has_method("damage"):
			hitBody.get_parent().manager.damage(damage)
		targets_hit.append(hitBody)
		pierce -= 1
		if pierce <= 0:
			go_away()

func hit(hitBody):
	var my_shape = $CollisionArea/CollisionShape2D.shape
	var my_transform = $CollisionArea/CollisionShape2D.global_transform
	var body_shape_owner = hitBody.shape_owner_get_owner(0)
	var body_shape = hitBody.shape_owner_get_shape(0, 0)
	var body_transform = body_shape_owner.global_transform
	var contacts = my_shape.collide_and_get_contacts(my_transform, body_shape, body_transform)
	var spawn_pos = self.global_position
	if contacts.size() > 0:
		spawn_pos = contacts[0]
	do_damage(hitBody)

func _on_life_time_timeout() -> void:
	queue_free()

func _physics_process(delta: float):
		velocity = Vector2(projectileSpeed, 0).rotated(rot)
		move_and_slide()
