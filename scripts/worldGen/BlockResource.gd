@tool
class_name BlockResource
extends Resource

## Block display name
@export var block_name: String = "Stone"

## Atlas tile coords in the TileSet (column, row)
@export var atlas_coords: Vector2i = Vector2i(0, 0)

## Which atlas source ID in the TileSet
@export var atlas_source_id: int = 0

## Time in seconds to mine this block
@export var mine_time: float = 1.0

## What the block drops when mined (item ID strings)
@export var drops: Array[String] = []

## Drop count range
@export var drop_min: int = 1
@export var drop_max: int = 1

## Can the player walk through it? (false = solid)
@export var is_solid: bool = true

## Is this a liquid (water, lava)?
@export var is_liquid: bool = false

## Light level emitted (0 = none)
@export var light_level: int = 0

## Tool required to mine ("", "pickaxe", "axe", "shovel")
@export var required_tool: String = ""

## Hardness tier — higher = needs better tool tier
@export var hardness: int = 0

## Sound to play when mining (optional)
@export var mine_sound: AudioStream
