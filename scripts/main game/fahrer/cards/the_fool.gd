extends FahrerCard

var _orig_maxHp: float
var _orig_hp: float
var _orig_speed: float
var _orig_damage: float
var _orig_bullet_amount: int
var _orig_proj_speed: float
var _orig_bullet_lifetime: float
var _orig_attack_speed: float

func apply() -> void:
	var s = GlobalPlayer.stats
	_orig_maxHp         = s.maxHp
	_orig_hp            = s.hp
	_orig_speed         = s.speed
	_orig_damage        = s.attackDamage
	_orig_bullet_amount = s.bulletAmount
	_orig_proj_speed    = s.projectileSpeed
	_orig_bullet_lifetime = s.bulletLifeTime
	_orig_attack_speed  = s.attackSpeed

	s.maxHp         = clampf(randf_range(s.maxHp * 0.4, s.maxHp * 2.5), 1.0, 9999.0)
	s.hp            = s.maxHp
	s.speed         = clampf(randf_range(s.speed * 0.3, s.speed * 3.0), 50.0, 9999.0)
	s.attackDamage  = clampf(randf_range(s.attackDamage * 0.2, s.attackDamage * 4.0), 0.5, 9999.0)
	s.bulletAmount  = clampi(randi_range(1, max(s.bulletAmount * 3, 8)), 1, 20)
	s.projectileSpeed = clampf(randf_range(s.projectileSpeed * 0.3, s.projectileSpeed * 3.0), 50.0, 9999.0)
	s.bulletLifeTime  = clampf(randf_range(s.bulletLifeTime * 0.3, s.bulletLifeTime * 3.0), 0.2, 20.0)
	s.attackSpeed     = clampf(randf_range(s.attackSpeed * 0.3, s.attackSpeed * 3.0), 0.0, 5.0)

func remove() -> void:
	var s = GlobalPlayer.stats
	s.maxHp         = _orig_maxHp
	s.hp            = min(_orig_hp, s.maxHp)
	s.speed         = _orig_speed
	s.attackDamage  = _orig_damage
	s.bulletAmount  = _orig_bullet_amount
	s.projectileSpeed = _orig_proj_speed
	s.bulletLifeTime  = _orig_bullet_lifetime
	s.attackSpeed     = _orig_attack_speed
