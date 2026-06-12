extends Resource
class_name ArtifactResource

enum Rarity { COMMON, UNCOMMON, RARE }

@export var artifact_id: String
@export var artifact_name: String
@export var description: String
@export var icon: Texture2D
@export var rarity: Rarity = Rarity.COMMON

var stacks: int = 0

# Called after stacks has been incremented.
func on_stack_added() -> void:
	pass

# Called after stacks has been decremented (only for partial removal mid-run).
func on_stack_removed() -> void:
	pass

# Called to undo all accumulated stat changes mid-run.
func on_all_removed() -> void:
	pass

# Called at run start/end — resets internal tracking vars WITHOUT touching stats
# (scene reload already resets stats). Override in subclasses that track state.
func reset_tracking() -> void:
	pass

func rarity_color() -> Color:
	match rarity:
		Rarity.COMMON:   return Color.WHITE
		Rarity.UNCOMMON: return Color.GREEN
		Rarity.RARE:     return Color.PURPLE
		_:               return Color.WHITE
