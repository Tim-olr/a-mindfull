extends Control

const C_BG     := Color(0.09, 0.10, 0.12)
const C_BORDER := Color(0.22, 0.24, 0.28)
const C_ACCENT := Color(0.90, 0.65, 0.20)
const C_TEXT   := Color(0.92, 0.90, 0.85)
const C_TEXT_DIM := Color(0.55, 0.53, 0.50)
const RADIUS   := 9
const SHOW_TIME: float = 4.0

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
		var box := _make_card(card)
		box.position = Vector2(start_x + i * (card_w + gap), y)
		box.size = Vector2(card_w, card_h)
		add_child(box)
		_animate(box, i * 0.15)


func _make_card(card: FahrerCard) -> Control:
	var root := Control.new()
	root.clip_contents = true
	var sb   := StyleBoxFlat.new()
	sb.bg_color     = C_BG
	sb.border_color = _suit_color(card.suit)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(RADIUS)
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", sb)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(panel)

	var stripe := ColorRect.new()
	stripe.color    = _suit_color(card.suit)
	stripe.size     = Vector2(220, 4)
	stripe.position = Vector2(0, 0)
	root.add_child(stripe)

	var suit_lbl := Label.new()
	suit_lbl.text = _suit_name(card.suit)
	suit_lbl.position = Vector2(0, 14)
	suit_lbl.size = Vector2(220, 20)
	suit_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	suit_lbl.add_theme_color_override("font_color", _suit_color(card.suit))
	suit_lbl.add_theme_font_size_override("font_size", 15)
	root.add_child(suit_lbl)

	var name_lbl := Label.new()
	name_lbl.text = card.card_name.to_upper()
	name_lbl.position = Vector2(8, 110)
	name_lbl.size = Vector2(204, 32)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_color_override("font_color", C_ACCENT)
	name_lbl.add_theme_font_size_override("font_size", 18)
	root.add_child(name_lbl)

	var desc_container := Control.new()
	desc_container.layout_mode = 0
	desc_container.position = Vector2(12, 148)
	desc_container.size = Vector2(196, 120)
	desc_container.clip_contents = true
	root.add_child(desc_container)

	var desc_lbl := Label.new()
	desc_lbl.layout_mode = 0
	desc_lbl.position = Vector2(0, 0)
	desc_lbl.size = Vector2(196, 120)
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_color_override("font_color", C_TEXT)
	desc_lbl.add_theme_font_size_override("font_size", 16)
	desc_lbl.text = card.description
	desc_container.add_child(desc_lbl)

	if card.icon != null:
		var icon := TextureRect.new()
		icon.texture = card.icon
		icon.position = Vector2(80, 40)
		icon.size = Vector2(60, 60)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(icon)

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
	return C_BORDER
