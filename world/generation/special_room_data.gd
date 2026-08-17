extends Resource
class_name SpecialRoomData

enum Placement { DEAD_END, FARTHEST, RANDOM }

@export var id: StringName = &"boss"
@export var scene: PackedScene
@export var count: int = 1
@export var min_distance: int = 1
@export var placement: Placement = Placement.DEAD_END
