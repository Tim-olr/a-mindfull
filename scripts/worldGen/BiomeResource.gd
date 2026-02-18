@tool
class_name BiomeResource
extends Resource

## Biome display name
@export var biome_name: String = "Plains"

## Noise threshold range where this biome appears (0.0 - 1.0 moisture value)
@export var moisture_min: float = 0.0
@export var moisture_max: float = 1.0

## Elevation range this biome appears in (0.0 = sea level, 1.0 = peak)
@export var elevation_min: float = 0.2
@export var elevation_max: float = 0.8

## Surface block (top layer)
@export var surface_block: BlockResource

## Sub-surface blocks (layers underneath surface)
@export var subsurface_blocks: Array[BlockResource] = []

## Number of subsurface layers
@export var subsurface_depth: int = 3

## Deep/stone block (below subsurface)
@export var deep_block: BlockResource

## Decorations / props placed on surface (scenes)
@export var decoration_scenes: Array[PackedScene] = []

## Chance (0-1) of spawning a decoration per tile
@export var decoration_chance: float = 0.05

## Biome color tint (applied to tilemap modulate)
@export var biome_tint: Color = Color.WHITE
