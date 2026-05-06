extends Weapon

# The wheel rolls one of these damages per shot.
const DAMAGE_OPTIONS: Array[float] = [0.0, 10.0, 30.0]

var _rng := RandomNumberGenerator.new()

func perform_attack() -> void:
	# Re-roll the damage right before each shot. Total damage in Weapon
	# is shooter.stats.attackDamage + damageMod + rarity_damage, so we
	# expect spirit attackDamage = 0 and rarity_damage = 0 here.
	damageMod = DAMAGE_OPTIONS[_rng.randi() % DAMAGE_OPTIONS.size()]
	super.perform_attack()
