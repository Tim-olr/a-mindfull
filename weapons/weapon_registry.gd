extends Node

var _unlocked: Dictionary = {}

var _starting_weapons: Array[String] = [
	"Pistol",
	"Wooden Bow",
	"Throwing Knives",
]

var _weapon_resource_paths: Dictionary = {
	"Pistol": "res://weapons/guns/pistol.tres",
	"Wooden Bow": "res://weapons/guns/wooden_bow.tres",
	"Throwing Knives": "res://weapons/guns/throwing_knives.tres",
	"AR": "res://weapons/guns/assault_rifle.tres",
	"Boomerang": "res://weapons/guns/boomerang.tres",
	"Crossbow": "res://weapons/guns/crossbow.tres",
	"Cursed Tome": "res://weapons/guns/cursed_tome.tres",
	"Dice Gun": "res://weapons/guns/dice_gun.tres",
	"Echo Cannon": "res://weapons/guns/echo_cannon.tres",
	"Gravity Well": "res://weapons/guns/gravity_well.tres",
	"Nail Gun": "res://weapons/guns/nail_gun.tres",
	"Ring of Rings": "res://weapons/guns/ring_of_rings.tres",
	"Shotgun": "res://weapons/guns/shotgun.tres",
	"smg": "res://weapons/guns/smg.tres",
	"Sniper Rifle": "res://weapons/guns/sniper.tres",
	"Toxic Squirtgun": "res://weapons/guns/toxic_squirtgun.tres",
}

func _ready() -> void:
	for w in _starting_weapons:
		_unlocked[w] = true

func is_unlocked(weapon_name: String) -> bool:
	return _unlocked.get(weapon_name, false)

func unlock(weapon_name: String) -> void:
	_unlocked[weapon_name] = true

func lock(weapon_name: String) -> void:
	_unlocked.erase(weapon_name)

func get_unlocked_names() -> Array[String]:
	var result: Array[String] = []
	for k in _unlocked.keys():
		if _unlocked[k]:
			result.append(k)
	return result

func get_item_resource(weapon_name: String) -> ItemResource:
	var path: String = _weapon_resource_paths.get(weapon_name, "")
	if path == "":
		return null
	return load(path) as ItemResource
