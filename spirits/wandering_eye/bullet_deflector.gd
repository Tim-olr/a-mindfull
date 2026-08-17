extends Node2D

# When the Wandering Eye's active ability is running, this field deflects up to
# max_deflections incoming enemy projectiles back toward enemies.

const DEFLECT_PROJECTILE = preload("res://weapons/projectiles/projectile.tscn")

var max_deflections: int = 2
var deflections:     int = 0
var _deflected_ids:  Array = []

@onready var area: Area2D = $DeflectArea

func _on_area_entered(entered_area: Area2D) -> void:
	if deflections >= max_deflections:
		return
	var proj_node = entered_area.get_parent()
	if proj_node == null:
		return
	var sg = proj_node.get("shooter_group")
	if sg != "enemy":
		return
	if not proj_node is Projectile:
		return
	var proj := proj_node as Projectile
	var id := proj.get_instance_id()
	if _deflected_ids.has(id):
		return
	_deflected_ids.append(id)

	# Spawn a reflected player-side bullet
	var new_bullet = DEFLECT_PROJECTILE.instantiate()
	new_bullet.global_position  = proj.global_position
	new_bullet.rot               = proj.rot + PI
	new_bullet.rotation          = new_bullet.rot
	new_bullet.damage            = proj.damage * 1.5
	new_bullet.lifetime          = 2.5
	new_bullet.projectileSpeed   = max(proj.projectileSpeed, 200.0)
	new_bullet.pierce            = 2
	new_bullet.shooter_group     = "player"
	new_bullet.speed_mode        = 0
	new_bullet.end_speed_multiplier = 1.0
	new_bullet.knockback_force   = 120.0
	if not GameManager.is_in_lobby:
		GlobalWorld.projectiles.add_child(new_bullet)
	else:
		GlobalPlayer.player.get_parent().add_child(new_bullet)

	proj.queue_free()
	deflections += 1
	if deflections >= max_deflections:
		queue_free()
