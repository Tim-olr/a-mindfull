extends Component
class_name FcBoost

var boost_applied := false
var can_boost := false

func _ready() -> void:
	component_name = "fc_boost"

func apply_boost():
	if !boost_applied:
		boost_applied = true
		GlobalPlayer.stats.speed *= 1.3

func unapply_boost():
	if boost_applied:
		boost_applied = false
		GlobalPlayer.stats.speed /= 1.3

func _on_boost_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("physics_object") and !boost_applied and can_boost:
		apply_boost()

func _on_boost_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("physics_object") and boost_applied:
		unapply_boost()
