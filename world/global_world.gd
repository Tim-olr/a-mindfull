extends Node

@onready var theWorld
@onready var projectiles
@onready var dmgNrs

var dungeon_generator: DungeonGenerator = null
var current_room: DungeonRoom = null
