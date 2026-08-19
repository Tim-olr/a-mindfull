extends Node2D
class_name PlayerSpecials

@onready var player_sprites: AnimatedSprite2D = $"../PlayerVisuals/PlayerSprites"
@onready var player_area: Area2D = $"../PlayerArea"
@onready var player_collision: CollisionShape2D = $"../PlayerCollision"

var is_paused: bool = false

var _menu_paused: bool = false
var _pre_menu_tree_paused: bool = false
var _pre_menu_player_always: bool = false

func pause():
	get_tree().paused = true

func unpause():
	get_tree().paused = false

func pause_wo_player():
	set_player_pause_mode(false)
	is_paused = true
	get_tree().paused = true

func unpause_wo_player():
	get_tree().paused = false
	is_paused = false
	set_player_pause_mode(true)

## Called when the pause menu opens. Freezes the player too (even mid an
## ability like Keep Me Close's, which normally exempts the player from the
## pause) by forcing it back to PAUSABLE, while remembering exactly how things
## were so close_pause_menu() can put them back — including an in-flight
## ability, whose duration timer is a descendant of the player node and
## simply stops counting down while the player is PAUSABLE, then resumes
## right where it left off once restored to ALWAYS.
func open_pause_menu() -> void:
	if _menu_paused:
		return
	_menu_paused = true
	_pre_menu_tree_paused = get_tree().paused
	var player_node = get_parent()
	_pre_menu_player_always = player_node.process_mode == Node.PROCESS_MODE_ALWAYS
	player_node.process_mode = Node.PROCESS_MODE_PAUSABLE
	get_tree().paused = true

## Called when the pause menu closes. Restores whatever pause state existed
## before the menu opened, so an ability that was mid-flight (world frozen,
## player free) picks back up exactly where it was.
func close_pause_menu() -> void:
	if not _menu_paused:
		return
	_menu_paused = false
	var player_node = get_parent()
	player_node.process_mode = Node.PROCESS_MODE_ALWAYS if _pre_menu_player_always else Node.PROCESS_MODE_PAUSABLE
	get_tree().paused = _pre_menu_tree_paused

func set_player_pause_mode(paused: bool):
	var player_node = get_parent()
	if paused:
		player_node.process_mode = Node.PROCESS_MODE_PAUSABLE
	else:
		player_node.process_mode = Node.PROCESS_MODE_ALWAYS

func change_game_speed(speed: float = 1.0):
	Engine.time_scale = speed

func size_player(new_scale):
	player_sprites.scale = new_scale
	player_area.scale = new_scale
	player_collision.scale = new_scale
