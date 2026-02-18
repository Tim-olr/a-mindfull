class_name BlockData
extends RefCounted

## Tile coordinate in the TileMapLayer
var coord: Vector2i = Vector2i.ZERO

## The block definition
var block: BlockResource = null

## Remaining health (seconds of mining left)
var hp: float = 1.0

## Currently being mined by (node reference, optional)
var mined_by: Node = null
