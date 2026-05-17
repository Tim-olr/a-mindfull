extends Node

signal tree_changed

var _unlocked: Dictionary = {}

# Accumulated stat bonuses applied to the player at run-start
var _bonus_max_hp: float = 0.0
var _bonus_speed: float = 0.0
var _bonus_damage: float = 0.0
var _bonus_damage_reduction: float = 0.0

const NODES := [
	# ── Vitality ────────────────────────────────────────────────────────
	{ "id": "extra_hp",          "name": "Extra Health",      "branch": "vitality",  "cost": 100,  "prereq": [],              "desc": "+10 Max HP" },
	{ "id": "vital_core",        "name": "Vital Core",        "branch": "vitality",  "cost": 200,  "prereq": ["extra_hp"],    "desc": "+20 Max HP" },
	{ "id": "tough_skin",        "name": "Tough Skin",        "branch": "vitality",  "cost": 300,  "prereq": ["vital_core"],  "desc": "-15% damage taken" },
	{ "id": "fleet_foot",        "name": "Fleet Foot",        "branch": "vitality",  "cost": 150,  "prereq": [],              "desc": "+20 Speed" },
	{ "id": "swift_stride",      "name": "Swift Stride",      "branch": "vitality",  "cost": 250,  "prereq": ["fleet_foot"],  "desc": "+30 Speed" },
	{ "id": "strength",          "name": "Strength",          "branch": "vitality",  "cost": 200,  "prereq": [],              "desc": "+2 Attack Damage" },
	# ── Weaponry ────────────────────────────────────────────────────────
	{ "id": "unlock_shotgun",         "name": "Shotgun",           "branch": "weaponry",  "cost": 150,  "prereq": [],  "desc": "Unlock: Shotgun" },
	{ "id": "unlock_smg",             "name": "SMG",               "branch": "weaponry",  "cost": 150,  "prereq": [],  "desc": "Unlock: SMG" },
	{ "id": "unlock_assault_rifle",   "name": "Assault Rifle",     "branch": "weaponry",  "cost": 200,  "prereq": [],  "desc": "Unlock: Assault Rifle" },
	{ "id": "unlock_burst_rifle",     "name": "Burst Rifle",       "branch": "weaponry",  "cost": 200,  "prereq": [],  "desc": "Unlock: Burst Rifle" },
	{ "id": "unlock_crossbow",        "name": "Crossbow",          "branch": "weaponry",  "cost": 250,  "prereq": [],  "desc": "Unlock: Crossbow" },
	{ "id": "unlock_boomerang",       "name": "Boomerang",         "branch": "weaponry",  "cost": 250,  "prereq": [],  "desc": "Unlock: Boomerang" },
	{ "id": "unlock_sniper",          "name": "Sniper",            "branch": "weaponry",  "cost": 300,  "prereq": [],  "desc": "Unlock: Sniper" },
	{ "id": "unlock_nail_gun",        "name": "Nail Gun",          "branch": "weaponry",  "cost": 300,  "prereq": [],  "desc": "Unlock: Nail Gun" },
	{ "id": "unlock_dice_gun",        "name": "Dice Gun",          "branch": "weaponry",  "cost": 350,  "prereq": [],  "desc": "Unlock: Dice Gun" },
	{ "id": "unlock_toxic_squirtgun", "name": "Toxic Squirtgun",   "branch": "weaponry",  "cost": 350,  "prereq": [],  "desc": "Unlock: Toxic Squirtgun" },
	{ "id": "unlock_echo_cannon",     "name": "Echo Cannon",       "branch": "weaponry",  "cost": 400,  "prereq": [],  "desc": "Unlock: Echo Cannon" },
	{ "id": "unlock_ring_of_rings",   "name": "Ring of Rings",     "branch": "weaponry",  "cost": 400,  "prereq": [],  "desc": "Unlock: Ring of Rings" },
	{ "id": "unlock_gravity_well",    "name": "Gravity Well",      "branch": "weaponry",  "cost": 500,  "prereq": [],  "desc": "Unlock: Gravity Well" },
	{ "id": "unlock_cursed_tome",     "name": "Cursed Tome",       "branch": "weaponry",  "cost": 500,  "prereq": [],  "desc": "Unlock: Cursed Tome" },
	# ── Stations ────────────────────────────────────────────────────────
	{ "id": "unlock_ignitor",    "name": "The Ignitor",       "branch": "stations",  "cost": 200,  "prereq": [],                   "desc": "Unlock: Ignitor (burn a card)" },
	{ "id": "station_slot_2",   "name": "Station Slot II",   "branch": "stations",  "cost": 400,  "prereq": ["unlock_ignitor"],    "desc": "Coming soon..." },
	{ "id": "station_slot_3",   "name": "Station Slot III",  "branch": "stations",  "cost": 600,  "prereq": ["station_slot_2"],   "desc": "Coming soon..." },
]

var _node_map: Dictionary = {}

func _ready() -> void:
	for n in NODES:
		_node_map[n["id"]] = n
	_apply_weapon_unlocks()

func is_unlocked(node_id: String) -> bool:
	return _unlocked.get(node_id, false)

func prereqs_met(node_id: String) -> bool:
	var nd = _node_map.get(node_id, null)
	if nd == null:
		return false
	for p in nd["prereq"]:
		if not is_unlocked(p):
			return false
	return true

func can_unlock(node_id: String) -> bool:
	if is_unlocked(node_id):
		return false
	if not prereqs_met(node_id):
		return false
	var nd = _node_map.get(node_id, null)
	if nd == null:
		return false
	return GlobalSafe.shards >= nd["cost"]

func unlock(node_id: String) -> bool:
	if not can_unlock(node_id):
		return false
	var nd = _node_map.get(node_id, null)
	GlobalSafe.decrease_shards(nd["cost"])
	_unlocked[node_id] = true
	_apply_effect(node_id)
	tree_changed.emit()
	return true

func get_branch(branch: String) -> Array:
	var result := []
	for n in NODES:
		if n["branch"] == branch:
			result.append(n)
	return result

func apply_stat_bonuses(stats: PlayerStats) -> void:
	stats.maxHp += _bonus_max_hp
	stats.hp = minf(stats.hp + _bonus_max_hp, stats.maxHp)
	stats.speed += _bonus_speed
	stats.attackDamage += _bonus_damage
	stats.damage_reduction = clampf(stats.damage_reduction + _bonus_damage_reduction, 0.0, 0.95)

func _apply_effect(node_id: String) -> void:
	match node_id:
		"extra_hp":         _bonus_max_hp += 10.0
		"vital_core":       _bonus_max_hp += 20.0
		"tough_skin":       _bonus_damage_reduction += 0.15
		"fleet_foot":       _bonus_speed += 20.0
		"swift_stride":     _bonus_speed += 30.0
		"strength":         _bonus_damage += 2.0
		_:                  _apply_weapon_unlock_by_id(node_id)

func _apply_weapon_unlocks() -> void:
	for id in _unlocked:
		_apply_weapon_unlock_by_id(id)

func _apply_weapon_unlock_by_id(node_id: String) -> void:
	var weapon_name := _weapon_name_for(node_id)
	if weapon_name != "":
		WeaponRegistry.unlock(weapon_name)

func _weapon_name_for(node_id: String) -> String:
	match node_id:
		"unlock_shotgun":         return "Shotgun"
		"unlock_smg":             return "SMG"
		"unlock_assault_rifle":   return "Assault Rifle"
		"unlock_burst_rifle":     return "Burst Rifle"
		"unlock_crossbow":        return "Crossbow"
		"unlock_boomerang":       return "Boomerang"
		"unlock_sniper":          return "Sniper"
		"unlock_nail_gun":        return "Nail Gun"
		"unlock_dice_gun":        return "Dice Gun"
		"unlock_toxic_squirtgun": return "Toxic Squirtgun"
		"unlock_echo_cannon":     return "Echo Cannon"
		"unlock_ring_of_rings":   return "Ring of Rings"
		"unlock_gravity_well":    return "Gravity Well"
		"unlock_cursed_tome":     return "Cursed Tome"
	return ""
