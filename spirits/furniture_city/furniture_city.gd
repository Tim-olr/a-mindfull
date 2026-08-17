extends Spirit

const fc_boost = preload("uid://gj7tdld1efap")
var inst_boost: FcBoost

const FC_ACTIVE = preload("uid://cxyp653xr82ux")
var fc_active: Weapon

var has_boost := false

func _ready() -> void:
	super()
	inst_boost = fc_boost.instantiate()
	GlobalPlayer.components.add_component(inst_boost)
	fc_active = FC_ACTIVE.instantiate()
	fc_active.attackable = false
	add_child(fc_active)

func apply_passive():
	inst_boost.can_boost = true

func remove_passive():
	inst_boost.can_boost = false

func active_ability():
	if canAbility:
		fc_active.shoot()
		active_ability_timer.start(get_effective_cooldown())
		canAbility = false
