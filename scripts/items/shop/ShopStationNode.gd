extends Area2D
class_name ShopStationNode

signal shop_opened(station: ShopStationNode)
signal shop_closed(station: ShopStationNode)
signal buy_requested(station: ShopStationNode)

@export var shop_resource: ShopResource
@export var opens_menu: bool = true
@export var interact_action: String = "interact"
@export var shop_ui: ShopUI
@export var upgrade_weapon_rarity: bool = false

var _player_inside: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if _player_inside and event.is_action_pressed("interact"):
		if opens_menu:
			if shop_ui and not shop_ui.visible:
				open_ui()
			elif shop_ui and shop_ui.visible:
				close_ui()
		else:
			buy_requested.emit(self)
			buy()


func open_ui() -> void:
	if shop_ui:
		shop_ui.open_for_station(self)
	shop_opened.emit(self)


func close_ui() -> void:
	if shop_ui:
		shop_ui.close()
	shop_closed.emit(self)


func buy() -> void:
	pass


func get_display_name() -> String:
	return shop_resource.shop_name if shop_resource else "Shop"


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = true


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = false
		if opens_menu:
			close_ui()
