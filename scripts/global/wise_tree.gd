extends Node

signal tree_changed

var _unlocked: Dictionary = {}

# Accumulated stat bonuses – recomputed from _unlocked on every _ready()
var _bonus_speed_pct:    float = 0.0   # each speed level: +5%
var _bonus_damage_pct:   float = 0.0   # each damage level: +5%
var _bonus_max_hp_pct:   float = 0.0   # each hp level: +10%
var _bonus_pickup_pct:   float = 0.0   # each pickup level: +0.05 to pickup_radius_mult
var _bonus_inv_slots:    int   = 0     # each inv level: +1
var _bonus_spirit_dr:    float = 0.0   # each sdr level: +5%
var _bonus_gathering:    float = 0.0   # each gather level: +5% to gathering_speed
var _bonus_luck:         float = 0.0   # each luck level: +10%
var _bonus_spirit_cdr:   float = 0.0   # each scdr level: +5%

const NODES := [
	# ── Skills ──────────────────────────────────────────────────────────────
	{ "id": "speed_1",  "name": "Swift Step I",    "branch": "skills", "cost": 150, "prereq": [],           "desc": "+5% Movement Speed" },
	{ "id": "speed_2",  "name": "Swift Step II",   "branch": "skills", "cost": 250, "prereq": ["speed_1"],  "desc": "+5% Movement Speed" },
	{ "id": "speed_3",  "name": "Swift Step III",  "branch": "skills", "cost": 400, "prereq": ["speed_2"],  "desc": "+5% Movement Speed" },

	{ "id": "damage_1", "name": "Sharp Edge I",    "branch": "skills", "cost": 150, "prereq": [],            "desc": "+5% Damage" },
	{ "id": "damage_2", "name": "Sharp Edge II",   "branch": "skills", "cost": 250, "prereq": ["damage_1"],  "desc": "+5% Damage" },
	{ "id": "damage_3", "name": "Sharp Edge III",  "branch": "skills", "cost": 400, "prereq": ["damage_2"],  "desc": "+5% Damage" },
	{ "id": "damage_4", "name": "Sharp Edge IV",   "branch": "skills", "cost": 600, "prereq": ["damage_3"],  "desc": "+5% Damage" },

	{ "id": "hp_1",     "name": "Vitality I",      "branch": "skills", "cost": 100, "prereq": [],        "desc": "+10% Max HP" },
	{ "id": "hp_2",     "name": "Vitality II",     "branch": "skills", "cost": 200, "prereq": ["hp_1"],  "desc": "+10% Max HP" },
	{ "id": "hp_3",     "name": "Vitality III",    "branch": "skills", "cost": 350, "prereq": ["hp_2"],  "desc": "+10% Max HP" },
	{ "id": "hp_4",     "name": "Vitality IV",     "branch": "skills", "cost": 500, "prereq": ["hp_3"],  "desc": "+10% Max HP" },
	{ "id": "hp_5",     "name": "Vitality V",      "branch": "skills", "cost": 700, "prereq": ["hp_4"],  "desc": "+10% Max HP" },

	{ "id": "pickup_1", "name": "Reach I",         "branch": "skills", "cost": 150, "prereq": [],             "desc": "+5% Pickup Radius" },
	{ "id": "pickup_2", "name": "Reach II",        "branch": "skills", "cost": 250, "prereq": ["pickup_1"],   "desc": "+5% Pickup Radius" },
	{ "id": "pickup_3", "name": "Reach III",       "branch": "skills", "cost": 400, "prereq": ["pickup_2"],   "desc": "+5% Pickup Radius" },
	{ "id": "pickup_4", "name": "Reach IV",        "branch": "skills", "cost": 600, "prereq": ["pickup_3"],   "desc": "+5% Pickup Radius" },

	{ "id": "inv_1",    "name": "Pack Rat I",      "branch": "skills", "cost": 200,  "prereq": [],          "desc": "+1 Inventory Slot" },
	{ "id": "inv_2",    "name": "Pack Rat II",     "branch": "skills", "cost": 300,  "prereq": ["inv_1"],   "desc": "+1 Inventory Slot" },
	{ "id": "inv_3",    "name": "Pack Rat III",    "branch": "skills", "cost": 450,  "prereq": ["inv_2"],   "desc": "+1 Inventory Slot" },
	{ "id": "inv_4",    "name": "Pack Rat IV",     "branch": "skills", "cost": 650,  "prereq": ["inv_3"],   "desc": "+1 Inventory Slot" },
	{ "id": "inv_5",    "name": "Pack Rat V",      "branch": "skills", "cost": 900,  "prereq": ["inv_4"],   "desc": "+1 Inventory Slot" },
	{ "id": "inv_6",    "name": "Pack Rat VI",     "branch": "skills", "cost": 1200, "prereq": ["inv_5"],   "desc": "+1 Inventory Slot" },
	{ "id": "inv_7",    "name": "Pack Rat VII",    "branch": "skills", "cost": 1600, "prereq": ["inv_6"],   "desc": "+1 Inventory Slot" },

	{ "id": "sdr_1",    "name": "Spirit Shield I",  "branch": "skills", "cost": 200, "prereq": [],          "desc": "+5% Spirit Damage Reduction" },
	{ "id": "sdr_2",    "name": "Spirit Shield II", "branch": "skills", "cost": 350, "prereq": ["sdr_1"],   "desc": "+5% Spirit Damage Reduction" },
	{ "id": "sdr_3",    "name": "Spirit Shield III","branch": "skills", "cost": 500, "prereq": ["sdr_2"],   "desc": "+5% Spirit Damage Reduction" },
	{ "id": "sdr_4",    "name": "Spirit Shield IV", "branch": "skills", "cost": 700, "prereq": ["sdr_3"],   "desc": "+5% Spirit Damage Reduction" },
	{ "id": "sdr_5",    "name": "Spirit Shield V",  "branch": "skills", "cost": 900, "prereq": ["sdr_4"],   "desc": "+5% Spirit Damage Reduction" },

	{ "id": "gather_1", "name": "Nimble Hands I",   "branch": "skills", "cost": 150, "prereq": [],             "desc": "+5% Gathering Speed" },
	{ "id": "gather_2", "name": "Nimble Hands II",  "branch": "skills", "cost": 250, "prereq": ["gather_1"],   "desc": "+5% Gathering Speed" },
	{ "id": "gather_3", "name": "Nimble Hands III", "branch": "skills", "cost": 400, "prereq": ["gather_2"],   "desc": "+5% Gathering Speed" },
	{ "id": "gather_4", "name": "Nimble Hands IV",  "branch": "skills", "cost": 600, "prereq": ["gather_3"],   "desc": "+5% Gathering Speed" },

	{ "id": "luck_1",   "name": "Fortune I",        "branch": "skills", "cost": 200, "prereq": [],           "desc": "+10% Luck" },
	{ "id": "luck_2",   "name": "Fortune II",       "branch": "skills", "cost": 400, "prereq": ["luck_1"],   "desc": "+10% Luck" },
	{ "id": "luck_3",   "name": "Fortune III",      "branch": "skills", "cost": 700, "prereq": ["luck_2"],   "desc": "+10% Luck" },

	{ "id": "scdr_1",   "name": "Soul Haste I",     "branch": "skills", "cost": 200, "prereq": [],            "desc": "+5% Spirit Cooldown Reduction" },
	{ "id": "scdr_2",   "name": "Soul Haste II",    "branch": "skills", "cost": 400, "prereq": ["scdr_1"],    "desc": "+5% Spirit Cooldown Reduction" },
	{ "id": "scdr_3",   "name": "Soul Haste III",   "branch": "skills", "cost": 700, "prereq": ["scdr_2"],    "desc": "+5% Spirit Cooldown Reduction" },

	# ── Weaponry ────────────────────────────────────────────────────────────
	{ "id": "unlock_shotgun",         "name": "Shotgun",          "branch": "weaponry", "cost": 150, "prereq": [], "desc": "Unlock: Shotgun" },
	{ "id": "unlock_smg",             "name": "SMG",              "branch": "weaponry", "cost": 150, "prereq": [], "desc": "Unlock: SMG" },
	{ "id": "unlock_assault_rifle",   "name": "Assault Rifle",    "branch": "weaponry", "cost": 200, "prereq": [], "desc": "Unlock: Assault Rifle" },
	{ "id": "unlock_burst_rifle",     "name": "Burst Rifle",      "branch": "weaponry", "cost": 200, "prereq": [], "desc": "Unlock: Burst Rifle" },
	{ "id": "unlock_crossbow",        "name": "Crossbow",         "branch": "weaponry", "cost": 250, "prereq": [], "desc": "Unlock: Crossbow" },
	{ "id": "unlock_boomerang",       "name": "Boomerang",        "branch": "weaponry", "cost": 250, "prereq": [], "desc": "Unlock: Boomerang" },
	{ "id": "unlock_sniper",          "name": "Sniper",           "branch": "weaponry", "cost": 300, "prereq": [], "desc": "Unlock: Sniper" },
	{ "id": "unlock_nail_gun",        "name": "Nail Gun",         "branch": "weaponry", "cost": 300, "prereq": [], "desc": "Unlock: Nail Gun" },
	{ "id": "unlock_dice_gun",        "name": "Dice Gun",         "branch": "weaponry", "cost": 350, "prereq": [], "desc": "Unlock: Dice Gun" },
	{ "id": "unlock_toxic_squirtgun", "name": "Toxic Squirtgun",  "branch": "weaponry", "cost": 350, "prereq": [], "desc": "Unlock: Toxic Squirtgun" },
	{ "id": "unlock_echo_cannon",     "name": "Echo Cannon",      "branch": "weaponry", "cost": 400, "prereq": [], "desc": "Unlock: Echo Cannon" },
	{ "id": "unlock_ring_of_rings",   "name": "Ring of Rings",    "branch": "weaponry", "cost": 400, "prereq": [], "desc": "Unlock: Ring of Rings" },
	{ "id": "unlock_gravity_well",    "name": "Gravity Well",     "branch": "weaponry", "cost": 500, "prereq": [], "desc": "Unlock: Gravity Well" },
	{ "id": "unlock_cursed_tome",     "name": "Cursed Tome",      "branch": "weaponry", "cost": 500, "prereq": [], "desc": "Unlock: Cursed Tome" },

	# ── Stations ────────────────────────────────────────────────────────────
	{ "id": "unlock_ignitor",       "name": "The Ignitor",       "branch": "stations", "cost": 200, "prereq": [],                    "desc": "Unlock: Ignitor (burn a card)" },
	{ "id": "station_cartographer", "name": "The Cartographer",  "branch": "stations", "cost": 300, "prereq": [],                    "desc": "Reveal a portion of the map at run start" },
	{ "id": "station_beacon",       "name": "The Beacon",        "branch": "stations", "cost": 250, "prereq": [],                    "desc": "Extraction point always visible on your map" },
]

var _node_map: Dictionary = {}

func _ready() -> void:
	for n in NODES:
		_node_map[n["id"]] = n
	_recompute_bonuses()

func _recompute_bonuses() -> void:
	_bonus_speed_pct   = 0.0
	_bonus_damage_pct  = 0.0
	_bonus_max_hp_pct  = 0.0
	_bonus_pickup_pct  = 0.0
	_bonus_inv_slots   = 0
	_bonus_spirit_dr   = 0.0
	_bonus_gathering   = 0.0
	_bonus_luck        = 0.0
	_bonus_spirit_cdr  = 0.0
	for id in _unlocked:
		_apply_effect(id)

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

# Each entry: { "display_name", "effect_per_level", "node_ids": [] }
const SKILL_CHAINS := [
	{ "display_name": "Swift Step",    "effect_per_level": "+5% Movement Speed",           "node_ids": ["speed_1",  "speed_2",  "speed_3"] },
	{ "display_name": "Sharp Edge",    "effect_per_level": "+5% Damage",                   "node_ids": ["damage_1", "damage_2", "damage_3", "damage_4"] },
	{ "display_name": "Vitality",      "effect_per_level": "+10% Max HP",                  "node_ids": ["hp_1",     "hp_2",     "hp_3",     "hp_4",     "hp_5"] },
	{ "display_name": "Reach",         "effect_per_level": "+5% Pickup Radius",            "node_ids": ["pickup_1", "pickup_2", "pickup_3", "pickup_4"] },
	{ "display_name": "Pack Rat",      "effect_per_level": "+1 Inventory Slot",            "node_ids": ["inv_1",    "inv_2",    "inv_3",    "inv_4",    "inv_5",  "inv_6",  "inv_7"] },
	{ "display_name": "Spirit Shield", "effect_per_level": "+5% Spirit Damage Reduction",  "node_ids": ["sdr_1",    "sdr_2",    "sdr_3",    "sdr_4",    "sdr_5"] },
	{ "display_name": "Nimble Hands",  "effect_per_level": "+5% Gathering Speed",          "node_ids": ["gather_1", "gather_2", "gather_3", "gather_4"] },
	{ "display_name": "Fortune",       "effect_per_level": "+10% Luck",                    "node_ids": ["luck_1",   "luck_2",   "luck_3"] },
	{ "display_name": "Soul Haste",    "effect_per_level": "+5% Spirit Cooldown Reduction","node_ids": ["scdr_1",   "scdr_2",   "scdr_3"] },
]

func get_chain_level(chain: Dictionary) -> int:
	var level := 0
	for id in chain["node_ids"]:
		if is_unlocked(id):
			level += 1
	return level

func get_chain_max(chain: Dictionary) -> int:
	return chain["node_ids"].size()

func get_chain_next_id(chain: Dictionary) -> String:
	for id in chain["node_ids"]:
		if not is_unlocked(id):
			return id
	return ""

func get_chain_next_cost(chain: Dictionary) -> int:
	var nid := get_chain_next_id(chain)
	if nid == "":
		return -1
	var nd = _node_map.get(nid, null)
	return nd["cost"] if nd != null else -1

func can_upgrade_chain(chain: Dictionary) -> bool:
	var nid := get_chain_next_id(chain)
	return nid != "" and can_unlock(nid)

func upgrade_chain(chain: Dictionary) -> bool:
	return unlock(get_chain_next_id(chain))

func apply_stat_bonuses(stats: PlayerStats) -> void:
	stats.speed        *= (1.0 + _bonus_speed_pct)
	stats.attackDamage *= (1.0 + _bonus_damage_pct)
	stats.maxHp        *= (1.0 + _bonus_max_hp_pct)
	stats.hp            = stats.maxHp
	stats.pickup_radius_mult   += _bonus_pickup_pct
	stats.bonus_inv_slots       = _bonus_inv_slots
	stats.spirit_damage_reduction = clampf(_bonus_spirit_dr, 0.0, 0.95)
	stats.gathering_speed         = 1.0 + _bonus_gathering
	stats.luck                    = _bonus_luck
	stats.spirit_cooldown_reduction = clampf(_bonus_spirit_cdr, 0.0, 0.95)

func _apply_effect(node_id: String) -> void:
	match node_id:
		"speed_1", "speed_2", "speed_3":
			_bonus_speed_pct += 0.05
		"damage_1", "damage_2", "damage_3", "damage_4":
			_bonus_damage_pct += 0.05
		"hp_1", "hp_2", "hp_3", "hp_4", "hp_5":
			_bonus_max_hp_pct += 0.10
		"pickup_1", "pickup_2", "pickup_3", "pickup_4":
			_bonus_pickup_pct += 0.05
		"inv_1", "inv_2", "inv_3", "inv_4", "inv_5", "inv_6", "inv_7":
			_bonus_inv_slots += 1
		"sdr_1", "sdr_2", "sdr_3", "sdr_4", "sdr_5":
			_bonus_spirit_dr += 0.05
		"gather_1", "gather_2", "gather_3", "gather_4":
			_bonus_gathering += 0.05
		"luck_1", "luck_2", "luck_3":
			_bonus_luck += 0.10
		"scdr_1", "scdr_2", "scdr_3":
			_bonus_spirit_cdr += 0.05
		_:
			_apply_weapon_unlock_by_id(node_id)

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
