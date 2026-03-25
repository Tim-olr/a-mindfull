extends Area2D
class_name ScrapBrokerNode

signal broker_opened
signal broker_closed

@export var interact_action: String = "interact"
@export var scrap_broker_ui: ScrapBrokerUI
@export var spirit_core_resource: ItemResource

var _player_inside: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if _player_inside and event.is_action_pressed(interact_action):
		if scrap_broker_ui and not scrap_broker_ui.visible:
			open_ui()
		elif scrap_broker_ui and scrap_broker_ui.visible:
			close_ui()


func open_ui() -> void:
	if scrap_broker_ui:
		if spirit_core_resource != null:
			scrap_broker_ui.set_spirit_core_resource(spirit_core_resource)
		scrap_broker_ui.open()
	broker_opened.emit()


func close_ui() -> void:
	if scrap_broker_ui:
		scrap_broker_ui.close()
	broker_closed.emit()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = true


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = false
		close_ui()
