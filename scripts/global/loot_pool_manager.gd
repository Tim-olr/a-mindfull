extends Node

var _biome_pools: Dictionary = {}
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()

func register_biome_pool(biome_name: String, weapon_resources: Array) -> void:
	_biome_pools[biome_name] = weapon_resources

func roll_weapon(biome_name: String) -> ItemResource:
	var pool: Array = _biome_pools.get(biome_name, [])
	if pool.is_empty():
		pool = _get_all_unlocked_weapons()
	var unlocked: Array = []
	for res in pool:
		if res is ItemResource and WeaponRegistry.is_unlocked(res.Name):
			unlocked.append(res)
	if unlocked.is_empty():
		return null
	return unlocked[_rng.randi() % unlocked.size()]

func _get_all_unlocked_weapons() -> Array:
	var result: Array = []
	for pool in _biome_pools.values():
		for res in pool:
			if res is ItemResource and WeaponRegistry.is_unlocked(res.Name):
				if not result.has(res):
					result.append(res)
	return result
