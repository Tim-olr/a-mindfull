## MiningComponent.gd
## Attach to your Player node. Handles mining input, progress bar, and drops.
##
## Usage:
##   1. Add MiningComponent.gd as a script on a new Node child of Player
##   2. Assign world_generator in Inspector or via code
##   3. Call start_mining(coord) / stop_mining() from Player input

extends Node

# ─────────────────────────────────────────────
#  EXPORTS
# ─────────────────────────────────────────────

## Reference to the WorldGenerator node
@export var world_generator: NodePath

## Tool type the player currently holds ("", "pickaxe", "axe", "shovel")
@export var current_tool: String = ""

## If true, shows a ProgressBar node named "MineProgress" on Player
@export var show_progress: bool = true

# ─────────────────────────────────────────────
#  STATE
# ─────────────────────────────────────────────

var _gen: Node = null
var _mining: bool = false
var _current_coord: Vector2i = Vector2i(-9999, -9999)
var _progress_bar: ProgressBar = null

signal mine_progress_changed(progress: float)
signal block_mined(coord: Vector2i, block: BlockResource)

# ─────────────────────────────────────────────
#  READY
# ─────────────────────────────────────────────

func _ready() -> void:
	_gen = get_node(world_generator)
	if show_progress:
		_progress_bar = get_parent().get_node_or_null("MineProgress")


# ─────────────────────────────────────────────
#  PROCESS
# ─────────────────────────────────────────────

func _process(delta: float) -> void:
	if not _mining or _gen == null:
		return

	var progress: float = _gen.mine_block(_current_coord, delta, current_tool)

	if progress < 0.0:
		# No block — stop
		stop_mining()
		return

	emit_signal("mine_progress_changed", progress)

	if _progress_bar:
		_progress_bar.value = progress * 100.0

	if progress >= 1.0:
		emit_signal("block_mined", _current_coord, _gen.get_block(_current_coord))
		stop_mining()


# ─────────────────────────────────────────────
#  PUBLIC API
# ─────────────────────────────────────────────

func start_mining(tile_coord: Vector2i) -> void:
	if _current_coord != tile_coord:
		# Switched target — reset hp by refreshing (WorldGen tracks hp per coord)
		_current_coord = tile_coord
	_mining = true
	if _progress_bar:
		_progress_bar.show()


func stop_mining() -> void:
	_mining = false
	emit_signal("mine_progress_changed", 0.0)
	if _progress_bar:
		_progress_bar.hide()
		_progress_bar.value = 0.0


func is_mining() -> bool:
	return _mining
