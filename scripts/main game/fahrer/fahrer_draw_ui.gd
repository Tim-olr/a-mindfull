extends Control

const SHOW_TIME: float = 4.0
const _card_scene = preload("res://scenes/main game/fahrer/fahrer_card.tscn")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	FahrerDeck.cards_drawn.connect(_on_cards_drawn)


func _on_cards_drawn(cards: Array) -> void:
	for c in get_children():
		c.queue_free()
	if cards.is_empty():
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var card_w  := 220
	var card_h  := 280
	var gap     := 24
	var total_w := cards.size() * card_w + (cards.size() - 1) * gap
	var start_x := (viewport_size.x - total_w) / 2.0
	var y       := (viewport_size.y - card_h) / 2.0 - 40

	for i in cards.size():
		var card: FahrerCard = cards[i]
		var box := _setup_card(_card_scene.instantiate(), card)
		box.position = Vector2(start_x + i * (card_w + gap), y)
		box.size = Vector2(card_w, card_h)
		add_child(box)
		_animate(box, i * 0.15)


func _setup_card(root: Control, card: FahrerCard) -> Control:
	var suit_color := _suit_color(card.suit)

	var bg: NinePatchRect = root.get_node("Background")
	bg.self_modulate = Color(0.09, 0.10, 0.12, 1.0)

	var stripe: ColorRect = root.get_node("SuitStripe")
	stripe.color = suit_color

	var suit_lbl: Label = root.get_node("SuitLabel")
	suit_lbl.text = _suit_name(card.suit)
	suit_lbl.add_theme_color_override("font_color", suit_color)

	var icon_rect: TextureRect = root.get_node("IconRect")
	if card.icon != null:
		icon_rect.texture = card.icon
		icon_rect.visible = true
	else:
		icon_rect.visible = false

	var name_lbl: Label = root.get_node("NameLabel")
	name_lbl.text = card.card_name.to_upper()

	var desc_lbl: Label = root.get_node("DescContainer/DescLabel")
	desc_lbl.text = card.description

	# Add a border Panel behind to show the border color
	var border_panel := Panel.new()
	border_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	border_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.10, 0.12, 1)
	sb.border_color = suit_color
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(9)
	border_panel.add_theme_stylebox_override("panel", sb)
	root.add_child(border_panel)
	root.move_child(border_panel, 0)

	return root


func _animate(card_root: Control, delay: float) -> void:
	card_root.modulate = Color(1, 1, 1, 0)
	card_root.scale = Vector2(0.7, 0.7)
	card_root.pivot_offset = Vector2(110, 140)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(card_root, "modulate", Color.WHITE, 0.35).set_delay(delay)
	tw.tween_property(card_root, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_delay(delay)
	var tw2 := create_tween()
	tw2.tween_interval(SHOW_TIME + delay)
	tw2.tween_property(card_root, "modulate", Color(1, 1, 1, 0), 0.6)
	tw2.tween_callback(card_root.queue_free)


func _suit_name(s: int) -> String:
	match s:
		FahrerCard.Suit.CLUBS:    return "♣ CLUBS"
		FahrerCard.Suit.DIAMONDS: return "♦ DIAMONDS"
		FahrerCard.Suit.HEARTS:   return "♥ HEARTS"
		FahrerCard.Suit.SPADES:   return "♠ SPADES"
		FahrerCard.Suit.FAHRER:   return "✦ FAHRER"
	return ""


func _suit_color(s: int) -> Color:
	match s:
		FahrerCard.Suit.CLUBS:    return Color(0.55, 0.85, 0.55)
		FahrerCard.Suit.DIAMONDS: return Color(0.95, 0.45, 0.30)
		FahrerCard.Suit.HEARTS:   return Color(0.90, 0.30, 0.45)
		FahrerCard.Suit.SPADES:   return Color(0.55, 0.55, 0.85)
		FahrerCard.Suit.FAHRER:   return Color(1.00, 0.85, 0.30)
	return Color(0.22, 0.24, 0.28)
