extends Control
class_name ShopUI

## ─────────────────────────────────────────────
##  ShopUI  —  fully self-contained, no scene file needed.
##  Add a bare Control node anywhere, attach this script.
##  Reparents itself onto a CanvasLayer automatically.
## ─────────────────────────────────────────────

# ── Palette (mirrors CraftingUI) ───────────────
const C_BG          := Color(0.07, 0.08, 0.10)
const C_PANEL       := Color(0.11, 0.13, 0.16)
const C_PANEL_DARK  := Color(0.06, 0.07, 0.09)
const C_PANEL_GLASS := Color(1, 1, 1, 0.03)
const C_BORDER      := Color(0.20, 0.23, 0.28)
const C_BORDER_LIT  := Color(0.35, 0.40, 0.50)
const C_ACCENT      := Color(0.95, 0.72, 0.22)
const C_ACCENT_DIM  := Color(0.55, 0.40, 0.08)
const C_TEXT        := Color(0.93, 0.91, 0.87)
const C_TEXT_DIM    := Color(0.48, 0.46, 0.44)
const C_TEXT_MICRO  := Color(0.32, 0.31, 0.30)
const C_GREEN       := Color(0.30, 0.82, 0.48)
const C_RED         := Color(0.92, 0.33, 0.30)
const C_SAFE        := Color(0.38, 0.72, 0.98)
const C_BTN_HOVER   := Color(1.00, 0.80, 0.28)
const C_BTN_PRESS   := Color(0.60, 0.42, 0.08)
const C_BADGE_BG    := Color(0.18, 0.20, 0.24)

# ── Layout ──────────────────────────────────────
const W       := 1170
const H       := 780
const PAD     := 21
const LIST_W  := 345
const _CORNER := 9

# ── Nodes ─────────────────────────────────────
var _station_label:   Label
var _subtitle_label:  Label
var _item_list:       VBoxContainer
var _item_buttons:    Array[Button] = []
var _item_name_label: Label
var _item_amount_lbl: Label
var _item_icon:       TextureRect
var _item_desc_label: Label
var _price_container: VBoxContainer
var _qty_box:         SpinBox
var _buy_button:      Button
var _close_button:    Button

# ── State ─────────────────────────────────────
var _station:       ShopStationNode = null
var _selected_item: ShopItem        = null
var _open_tween:    Tween           = null


# ════════════════════════════════════════════════
#  Bootstrap
# ════════════════════════════════════════════════

func _ready() -> void:
	if not get_parent() is CanvasLayer:
		var cl       := CanvasLayer.new()
		cl.layer      = 10
		cl.name       = "ShopUILayer"
		get_tree().root.call_deferred("add_child", cl)
		await get_tree().process_frame
		get_parent().remove_child(self)
		cl.add_child(self)

	_build_ui()
	hide()


# ════════════════════════════════════════════════
#  Public API
# ════════════════════════════════════════════════

func open_for_station(station: ShopStationNode) -> void:
	_station       = station
	_selected_item = null
	modulate.a     = 0.0
	scale          = Vector2(0.92, 0.92)
	show()
	_refresh()
	if _open_tween:
		_open_tween.kill()
	_open_tween = create_tween().set_parallel(true)
	_open_tween.tween_property(self, "scale",      Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_open_tween.tween_property(self, "modulate:a", 1.0,               0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func close() -> void:
	_station = null
	if _open_tween:
		_open_tween.kill()
	_open_tween = create_tween().set_parallel(true)
	_open_tween.tween_property(self, "scale",      Vector2(0.92, 0.92), 0.14).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
	_open_tween.tween_property(self, "modulate:a", 0.0,                 0.14).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
	_open_tween.chain().tween_callback(hide)


# ════════════════════════════════════════════════
#  Build UI
# ════════════════════════════════════════════════

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_CENTER)
	custom_minimum_size = Vector2(W, H)
	size                = Vector2(W, H)
	pivot_offset        = size / 2.0
	position            = get_viewport().get_visible_rect().size / 2.0 - size / 2.0

	# Drop shadow
	var shadow := _make_box(Vector2(W, H), Vector2(12, 12), Color(0, 0, 0, 0.6))
	add_child(shadow)

	# Main background
	var bg := _make_box(Vector2(W, H), Vector2.ZERO, C_BG, C_BORDER)
	add_child(bg)

	# Gold gradient top stripe
	var grad          := Gradient.new()
	grad.set_color(0, C_ACCENT)
	grad.set_color(1, Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.0))
	var grad_tex      := GradientTexture1D.new()
	grad_tex.gradient  = grad
	var stripe         := TextureRect.new()
	stripe.texture      = grad_tex
	stripe.stretch_mode = TextureRect.STRETCH_SCALE
	stripe.size         = Vector2(W, 5)
	stripe.position     = Vector2.ZERO
	bg.add_child(stripe)

	# Shop title
	_station_label                      = _lbl("", 23, C_ACCENT, true)
	_station_label.position             = Vector2(0, 10)
	_station_label.size                 = Vector2(W, 30)
	_station_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bg.add_child(_station_label)

	# Shop subtitle (description first line)
	_subtitle_label                      = _lbl("", 14, C_TEXT_DIM)
	_subtitle_label.position             = Vector2(0, 40)
	_subtitle_label.size                 = Vector2(W, 18)
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bg.add_child(_subtitle_label)

	# Close button
	_close_button          = Button.new()
	_close_button.text     = "✕"
	_close_button.position = Vector2(W - PAD - 48, 8)
	_close_button.size     = Vector2(48, 40)
	_close_button.flat     = true
	_close_button.add_theme_font_size_override("font_size", 20)
	_close_button.add_theme_color_override("font_color",       C_TEXT_DIM)
	_close_button.add_theme_color_override("font_hover_color", C_RED)
	_close_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_close_button.pressed.connect(close)
	bg.add_child(_close_button)

	# ── Body ──────────────────────────────────
	var body_y := 65
	var body_h := H - body_y - PAD

	# ── Left panel ────────────────────────────
	var lp := _make_box(Vector2(LIST_W, body_h), Vector2(PAD, body_y), C_PANEL_DARK, C_BORDER)
	bg.add_child(lp)

	var lh      := _lbl("ITEMS", 14, C_TEXT_DIM, true)
	lh.position  = Vector2(15, 12)
	lp.add_child(lh)

	var scroll                    := ScrollContainer.new()
	scroll.position                = Vector2(0, 36)
	scroll.size                    = Vector2(LIST_W, body_h - 36)
	scroll.vertical_scroll_mode   = ScrollContainer.SCROLL_MODE_AUTO
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	lp.add_child(scroll)

	_item_list                      = VBoxContainer.new()
	_item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_item_list)

	# ── Right panel ───────────────────────────
	var rw   := W - PAD * 2 - LIST_W - 15
	var rp_x := PAD + LIST_W + 15
	var rp   := _make_box(Vector2(rw, body_h), Vector2(rp_x, body_y), C_PANEL, C_BORDER)
	bg.add_child(rp)

	# Large item name
	_item_name_label          = _lbl("Select an item", 22, C_ACCENT, true)
	_item_name_label.position = Vector2(PAD, PAD)
	_item_name_label.size     = Vector2(rw - PAD * 2, 36)
	rp.add_child(_item_name_label)

	# Amount subtitle
	_item_amount_lbl          = _lbl("", 16, C_TEXT_DIM)
	_item_amount_lbl.position = Vector2(PAD, PAD + 40)
	_item_amount_lbl.size     = Vector2(rw - PAD * 2, 24)
	rp.add_child(_item_amount_lbl)

	# Item icon (64×64)
	_item_icon               = TextureRect.new()
	_item_icon.position      = Vector2(PAD, PAD + 72)
	_item_icon.size          = Vector2(64, 64)
	_item_icon.expand_mode   = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_item_icon.stretch_mode  = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rp.add_child(_item_icon)

	# Description
	_item_desc_label               = _lbl("", 17, C_TEXT_DIM)
	_item_desc_label.position      = Vector2(PAD, PAD + 148)
	_item_desc_label.size          = Vector2(rw - PAD * 2, 90)
	_item_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rp.add_child(_item_desc_label)

	# Divider
	var div      := ColorRect.new()
	div.color     = C_ACCENT_DIM
	div.size      = Vector2(rw - PAD * 2, 2)
	div.position  = Vector2(PAD, PAD + 246)
	rp.add_child(div)

	# Price section header
	var ph      := _lbl("PRICE", 14, C_TEXT_DIM, true)
	ph.position  = Vector2(PAD, PAD + 258)
	rp.add_child(ph)

	# Price content container
	_price_container          = VBoxContainer.new()
	_price_container.position = Vector2(PAD, PAD + 282)
	_price_container.size     = Vector2(rw - PAD * 2, 180)
	rp.add_child(_price_container)

	# Quantity spinner
	_qty_box               = SpinBox.new()
	_qty_box.position      = Vector2(PAD, body_h - 138)
	_qty_box.size          = Vector2(160, 40)
	_qty_box.min_value     = 1
	_qty_box.max_value     = 999
	_qty_box.step          = 1
	_qty_box.value         = 1
	_qty_box.add_theme_font_size_override("font_size", 18)
	_qty_box.hide()
	rp.add_child(_qty_box)

	# Buy button
	_buy_button = _action_btn("🛒  Buy", Vector2(PAD, body_h - 78), Vector2(rw - PAD * 2, 60))
	_buy_button.pressed.connect(_on_buy_pressed)
	rp.add_child(_buy_button)


# ════════════════════════════════════════════════
#  Refresh
# ════════════════════════════════════════════════

func _refresh() -> void:
	if _station == null or _station.shop_resource == null:
		return
	var res := _station.shop_resource
	_station_label.text = res.shop_name.to_upper()

	# Subtitle: first line of description
	var desc_lines := res.description.split("\n")
	_subtitle_label.text = desc_lines[0] if desc_lines.size() > 0 else ""

	_populate_item_list()
	if _selected_item != null:
		_show_item(_selected_item)


# ════════════════════════════════════════════════
#  Item list
# ════════════════════════════════════════════════

func _populate_item_list() -> void:
	for b in _item_buttons:
		b.queue_free()
	_item_buttons.clear()

	if _station == null or _station.shop_resource == null:
		return

	for shop_item in _station.shop_resource.items:
		if shop_item == null:
			continue
		var in_stock := shop_item.is_in_stock()
		var btn      := Button.new()
		btn.flat      = true
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(LIST_W, 54)
		btn.add_theme_font_size_override("font_size", 17)
		btn.add_theme_color_override("font_color",         C_TEXT if in_stock else C_TEXT_DIM)
		btn.add_theme_color_override("font_hover_color",   C_TEXT)
		btn.add_theme_color_override("font_pressed_color", C_ACCENT)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		btn.disabled = not in_stock

		var sb_n := StyleBoxFlat.new()
		sb_n.bg_color            = Color.TRANSPARENT
		sb_n.content_margin_left = 48
		btn.add_theme_stylebox_override("normal", sb_n)

		var sb_h := StyleBoxFlat.new()
		sb_h.bg_color            = Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.10)
		sb_h.content_margin_left = 48
		btn.add_theme_stylebox_override("hover", sb_h)

		# Small icon
		var icon_tex := shop_item.get_icon()
		if icon_tex:
			var icon_rect           := TextureRect.new()
			icon_rect.texture        = icon_tex
			icon_rect.position       = Vector2(8, 11)
			icon_rect.size           = Vector2(32, 32)
			icon_rect.stretch_mode   = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.mouse_filter   = Control.MOUSE_FILTER_IGNORE
			btn.add_child(icon_rect)
		else:
			# Grey placeholder
			var ph_rect         := ColorRect.new()
			ph_rect.color        = C_BORDER
			ph_rect.position     = Vector2(8, 11)
			ph_rect.size         = Vector2(32, 32)
			ph_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.add_child(ph_rect)

		btn.text = shop_item.get_display_name()

		# Price chip
		var price_txt := _price_text(shop_item)
		var price_col := C_ACCENT if shop_item.price_type == ShopItem.PriceType.SHARDS else C_TEXT_DIM
		var price_chip        := _pill_label(price_txt, price_col, C_BADGE_BG)
		price_chip.position    = Vector2(LIST_W - 105, 12)
		price_chip.size        = Vector2(95, 30)
		price_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(price_chip)

		# Stock badge
		var stock_txt := ""
		if not in_stock:
			stock_txt = "sold out"
		elif shop_item.stock == -1:
			stock_txt = "∞"
		else:
			stock_txt = "x%d" % shop_item.stock
		var stock_col  := C_TEXT_MICRO if in_stock else C_RED
		var stock_chip := _pill_label(stock_txt, stock_col, C_PANEL_DARK)
		stock_chip.position    = Vector2(LIST_W - 105, 42)
		stock_chip.size        = Vector2(95, 22)
		stock_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(stock_chip)

		if not in_stock:
			btn.modulate.a = 0.5

		var captured := shop_item
		var btn_idx  := _item_buttons.size()
		btn.pressed.connect(_select_item.bind(captured, btn_idx))
		_item_list.add_child(btn)
		_item_buttons.append(btn)


func _price_text(shop_item: ShopItem) -> String:
	match shop_item.price_type:
		ShopItem.PriceType.SHARDS:
			return "◈ %.0f" % shop_item.shard_price
		ShopItem.PriceType.ITEMS:
			return "Barter"
		ShopItem.PriceType.FREE:
			return "Free"
	return ""


func _select_item(shop_item: ShopItem, btn_idx: int) -> void:
	_selected_item = shop_item
	_show_item(shop_item)
	# Highlight selected button
	for i in _item_buttons.size():
		var active := i == btn_idx
		var sb     := StyleBoxFlat.new()
		sb.bg_color          = Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.14) if active else Color.TRANSPARENT
		sb.border_width_left = 6 if active else 0
		sb.border_color      = C_ACCENT
		sb.content_margin_left = 48
		_item_buttons[i].add_theme_stylebox_override("normal", sb)


# ════════════════════════════════════════════════
#  Item detail panel
# ════════════════════════════════════════════════

func _show_item(shop_item: ShopItem) -> void:
	_item_name_label.text = shop_item.get_display_name().to_upper()
	_item_amount_lbl.text = "x%d" % shop_item.amount if shop_item.amount > 1 else ""
	_item_icon.texture    = shop_item.get_icon()
	_item_desc_label.text = shop_item.description

	# Price section
	for c in _price_container.get_children():
		c.queue_free()

	match shop_item.price_type:
		ShopItem.PriceType.SHARDS:
			var avail := Crafting.available_shards()
			var qty   := int(_qty_box.value)
			var cost  := shop_item.shard_price * qty
			var label := "◈  %.0f / %.0f shards" % [avail, cost]
			if GameManager.is_in_lobby:
				label += "  (player + safe)"
			var lbl       := _lbl(label, 18, C_GREEN if avail >= cost else C_RED)
			_price_container.add_child(lbl)

		ShopItem.PriceType.ITEMS:
			for ing in shop_item.item_costs:
				if ing == null or ing.item_resource == null:
					continue
				var have := Crafting.get_material_count(ing.item_resource)
				var need := ing.amount * int(_qty_box.value)
				_price_container.add_child(
					_ing_row(ing.item_resource.Name, need, have)
				)

		ShopItem.PriceType.FREE:
			_price_container.add_child(_lbl("Free!", 20, C_GREEN, true))

	# Quantity spinner
	var is_stackable := shop_item.item_resource != null and shop_item.item_resource.isStackable
	if is_stackable:
		_qty_box.show()
		if shop_item.stock != -1:
			_qty_box.max_value = shop_item.stock
		elif shop_item.price_type == ShopItem.PriceType.SHARDS and shop_item.shard_price > 0:
			var avail := Crafting.available_shards()
			_qty_box.max_value = max(1, floor(avail / shop_item.shard_price))
		else:
			_qty_box.max_value = 999
		_qty_box.value = clamp(_qty_box.value, 1, _qty_box.max_value)
	else:
		_qty_box.hide()
		_qty_box.value = 1

	# Buy button state
	_buy_button.disabled = not (shop_item.is_in_stock() and can_afford(shop_item, int(_qty_box.value)))
	_buy_button.text     = "🛒  Buy"
	_style_action_btn(_buy_button, _buy_button.disabled)


# ════════════════════════════════════════════════
#  Affordability
# ════════════════════════════════════════════════

func can_afford(shop_item: ShopItem, qty: int) -> bool:
	match shop_item.price_type:
		ShopItem.PriceType.SHARDS:
			return Crafting.available_shards() >= shop_item.shard_price * qty
		ShopItem.PriceType.ITEMS:
			for ing in shop_item.item_costs:
				if ing == null or ing.item_resource == null:
					continue
				if Crafting.get_material_count(ing.item_resource) < ing.amount * qty:
					return false
			return true
		ShopItem.PriceType.FREE:
			return true
	return false


# ════════════════════════════════════════════════
#  Buy
# ════════════════════════════════════════════════

func _on_buy_pressed() -> void:
	if _selected_item == null or _station == null:
		return
	var qty := int(_qty_box.value) if not _qty_box.is_hidden() else 1
	if not _selected_item.is_in_stock():
		return
	if not can_afford(_selected_item, qty):
		return

	# Deduct cost
	match _selected_item.price_type:
		ShopItem.PriceType.SHARDS:
			Crafting._consume_shards(_selected_item.shard_price * qty)
		ShopItem.PriceType.ITEMS:
			for ing in _selected_item.item_costs:
				if ing == null or ing.item_resource == null:
					continue
				Crafting._consume_material(ing.item_resource, ing.amount * qty)
		ShopItem.PriceType.FREE:
			pass

	# Give item
	Crafting._give_item(_selected_item.item_resource, _selected_item.amount * qty)

	# Decrement stock
	if _selected_item.stock != -1:
		_selected_item.stock -= qty

	# Refresh UI
	_populate_item_list()
	_show_item(_selected_item)

	# Feedback
	_buy_button.text     = "✓  Bought!"
	_buy_button.disabled = true
	await get_tree().create_timer(1.2).timeout
	if is_instance_valid(_buy_button):
		_buy_button.text = "🛒  Buy"
		if _selected_item != null:
			_show_item(_selected_item)


# ════════════════════════════════════════════════
#  Widget helpers
# ════════════════════════════════════════════════

func _make_box(sz: Vector2, pos: Vector2, bg_col: Color,
			   border_col: Color = Color.TRANSPARENT) -> Control:
	var c      := Control.new()
	c.size      = sz
	c.position  = pos
	var sb     := StyleBoxFlat.new()
	sb.bg_color = bg_col
	if border_col != Color.TRANSPARENT:
		sb.border_color = border_col
		sb.set_border_width_all(1)
	sb.set_corner_radius_all(_CORNER)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size  = 4
	var panel              := Panel.new()
	panel.size              = sz
	panel.position          = Vector2.ZERO
	panel.mouse_filter      = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", sb)
	c.add_child(panel)
	return c


func _lbl(txt: String, sz: int, col: Color, bold: bool = false) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	return l


func _pill_label(txt: String, font_col: Color, bg_col: Color) -> Panel:
	var panel  := Panel.new()
	var sb     := StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.set_corner_radius_all(_CORNER)
	panel.add_theme_stylebox_override("panel", sb)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lbl                 := _lbl(txt, 13, font_col, true)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(lbl)
	return panel


func _ing_row(item_name: String, need: int, have: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 33)
	row.add_theme_constant_override("separation", 6)

	var dot := _lbl("▸", 18, C_BORDER_LIT)
	dot.custom_minimum_size = Vector2(18, 0)
	row.add_child(dot)

	var nl := _lbl(item_name, 18, C_TEXT)
	nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(nl)

	var enough      := have >= need
	var col         := C_GREEN if enough else C_RED
	var chip_bg_col := Color(col.r, col.g, col.b, 0.18)
	var chip        := Panel.new()
	chip.custom_minimum_size = Vector2(84, 26)
	chip.size_flags_vertical  = Control.SIZE_SHRINK_CENTER
	chip.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	var chip_sb               := StyleBoxFlat.new()
	chip_sb.bg_color           = chip_bg_col
	chip_sb.set_corner_radius_all(_CORNER)
	chip.add_theme_stylebox_override("panel", chip_sb)
	var cl := _lbl("%d / %d" % [have, need], 17, col, true)
	cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	cl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	chip.add_child(cl)
	row.add_child(chip)

	return row


func _action_btn(txt: String, pos: Vector2, sz: Vector2) -> Button:
	var btn     := Button.new()
	btn.text     = txt
	btn.position = pos
	btn.size     = sz
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_style_action_btn(btn, false)
	return btn


func _style_action_btn(btn: Button, is_disabled: bool) -> void:
	var mk := func(col: Color) -> StyleBoxFlat:
		var s               := StyleBoxFlat.new()
		s.bg_color           = col
		s.set_corner_radius_all(_CORNER)
		s.content_margin_top    = 9
		s.content_margin_bottom = 9
		return s
	btn.add_theme_stylebox_override("normal",   mk.call(C_ACCENT_DIM if is_disabled else C_ACCENT))
	btn.add_theme_stylebox_override("hover",    mk.call(C_BTN_HOVER))
	btn.add_theme_stylebox_override("pressed",  mk.call(C_BTN_PRESS))
	btn.add_theme_stylebox_override("disabled", mk.call(C_ACCENT_DIM))
	btn.add_theme_color_override("font_color",          C_BG)
	btn.add_theme_color_override("font_hover_color",    C_BG)
	btn.add_theme_color_override("font_pressed_color",  C_BG)
	btn.add_theme_color_override("font_disabled_color", Color(C_BG.r, C_BG.g, C_BG.b, 0.4))
