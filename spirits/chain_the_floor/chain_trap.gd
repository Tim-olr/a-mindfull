extends Node2D

var radius: float = 160.0
var trapped_enemies: Array = []

@onready var detect_area: Area2D = $DetectArea

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy") and not trapped_enemies.has(body):
		trapped_enemies.append(body)

func _physics_process(_delta: float) -> void:
	var to_remove: Array = []
	for enemy in trapped_enemies:
		if not is_instance_valid(enemy):
			to_remove.append(enemy)
			continue
		var diff: Vector2 = enemy.global_position - global_position
		if diff.length() > radius:
			# Push the enemy back inside the boundary
			enemy.global_position = global_position + diff.normalized() * (radius - 4.0)
	for e in to_remove:
		trapped_enemies.erase(e)

func deactivate() -> void:
	queue_free()
