extends Node

var _unlocked: Dictionary = {}

var _starting_weapons: Array[String] = [
	"Pistol",
	"Wooden Bow",
	"Throwing Knives",
]

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
