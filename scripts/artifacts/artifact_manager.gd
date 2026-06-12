extends Node

const ARTIFACT_PATHS: Array[String] = [
	"res://resources/artifacts/weighted_boots.tres",
	"res://resources/artifacts/adrenal_syringe.tres",
	"res://resources/artifacts/insurance_charm.tres",
	"res://resources/artifacts/max_vitality.tres",
	"res://resources/artifacts/focused_mind.tres",
]

# artifact_id -> ArtifactResource (duplicated instance, accumulates stacks)
var _active: Dictionary = {}

# Templates used for world drops and random rolling.
var _pool: Array[ArtifactResource] = []

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	_load_pool()


func _load_pool() -> void:
	for path in ARTIFACT_PATHS:
		if not ResourceLoader.exists(path):
			push_warning("ArtifactManager: missing resource at " + path)
			continue
		var res = load(path)
		if res is ArtifactResource:
			_pool.append(res)
	print("ArtifactManager: %d artifacts loaded" % _pool.size())


# --- Run lifecycle ---

# Call at run start. Resets stack counts and tracking vars; does NOT undo stats
# because the player scene was reloaded and stats are already fresh.
func clear() -> void:
	for id in _active:
		var inst: ArtifactResource = _active[id]
		inst.stacks = 0
		inst.reset_tracking()
	_active.clear()


# --- Pickup ---

func pick_up(template: ArtifactResource) -> void:
	var id := template.artifact_id
	if not _active.has(id):
		var inst := template.duplicate() as ArtifactResource
		inst.stacks = 0
		_active[id] = inst
	var inst: ArtifactResource = _active[id]
	inst.stacks += 1
	inst.on_stack_added()


# --- Removal (mid-run, undoes stat changes) ---

func remove_one(artifact_id: String) -> bool:
	if not _active.has(artifact_id):
		return false
	var inst: ArtifactResource = _active[artifact_id]
	if inst.stacks > 1:
		inst.stacks -= 1
		inst.on_stack_removed()
	else:
		inst.on_all_removed()
		inst.stacks = 0
		_active.erase(artifact_id)
	return true

func remove_all_of(artifact_id: String) -> bool:
	if not _active.has(artifact_id):
		return false
	var inst: ArtifactResource = _active[artifact_id]
	inst.on_all_removed()
	inst.stacks = 0
	_active.erase(artifact_id)
	return true


# --- Queries ---

func has_artifact(artifact_id: String) -> bool:
	return _active.has(artifact_id)

func get_stacks(artifact_id: String) -> int:
	if not _active.has(artifact_id):
		return 0
	return _active[artifact_id].stacks

# Speed multiplier when Adrenal Syringe is active and player is at or below 25% HP.
func adrenal_speed_mult() -> float:
	if not _active.has("adrenal_syringe"):
		return 1.0
	if GlobalPlayer.stats == null or GlobalPlayer.stats.maxHp <= 0:
		return 1.0
	if GlobalPlayer.stats.hp > GlobalPlayer.stats.maxHp * 0.25:
		return 1.0
	return _active["adrenal_syringe"].get_speed_mult()

# Extra fraction of carried shards kept on death (on top of the base 10%).
func shard_death_retention() -> float:
	if not _active.has("insurance_charm"):
		return 0.0
	return _active["insurance_charm"].get_retention_bonus()

# Cooldown reduction fraction applied to spirit actives by Focused Mind.
func spirit_cdr() -> float:
	if not _active.has("focused_mind"):
		return 0.0
	return _active["focused_mind"].get_cdr()


# --- Rolling ---

func roll_random() -> ArtifactResource:
	if _pool.is_empty():
		return null
	const BASE_W := [1.0, 0.5, 0.2]  # COMMON, UNCOMMON, RARE
	var luck := GlobalPlayer.stats.luck if GlobalPlayer.stats else 0.0
	var weights: Array[float] = []
	var total := 0.0
	for art in _pool:
		var w := BASE_W[art.rarity] * (1.0 + luck * int(art.rarity) * 0.5)
		weights.append(w)
		total += w
	var roll := _rng.randf() * total
	var acc := 0.0
	for i in _pool.size():
		acc += weights[i]
		if roll <= acc:
			return _pool[i]
	return _pool[_pool.size() - 1]
