extends Control
class_name ShopUI

const C_BG          := Color(0.10, 0.09, 0.08)
const C_PANEL       := Color(0.15, 0.13, 0.11)
const C_PANEL_DARK  := Color(0.08, 0.07, 0.06)
const C_BORDER      := Color(0.28, 0.24, 0.19)
const C_BORDER_LIT  := Color(0.50, 0.43, 0.32)
const C_ACCENT      := Color(0.78, 0.62, 0.38)
const C_ACCENT_DIM  := Color(0.38, 0.29, 0.14)
const C_TEXT        := Color(0.88, 0.84, 0.76)
const C_TEXT_DIM    := Color(0.52, 0.48, 0.42)
const C_TEXT_MICRO  := Color(0.36, 0.33, 0.29)
const C_GREEN       := Color(0.46, 0.70, 0.42)
const C_RED         := Color(0.75, 0.35, 0.32)
const C_SAFE        := Color(0.46, 0.62, 0.76)
const C_BTN_HOVER   := Color(0.88, 0.72, 0.46)
const C_BTN_PRESS   := Color(0.48, 0.36, 0.16)
const C_BADGE_BG    := Color(0.20, 0.18, 0.15)
const _CORNER       := 9

const RARITY_NAMES  := ["Common", "Uncommon", "Rare", "Epic", "Legendary"]
const RARITY_COLORS := [
	Color(0.85, 0.85, 0.85),
	Color(0.30, 0.80, 0.30),
	Color(0.30, 0.50, 0.95),
	Color(0.65, 0.30, 0.90),
	Color(1.00, 0.55, 0.10),
]

@onready var _station_label:   Label         = $Background/StationLabel
@onready var _subtitle_label:  Label         = $Background/SubtitleLabel
@onready var _item_list:       VBoxContainer = $Background/LeftPanel/ItemScroll/ItemList
@onready var _item_name_label: Label         = $Background/RightPanel/ItemNameLabel
@onready var _item_amount_lbl: Label         = $Background/RightPanel/ItemAmountLabel
@onready var _item_icon:       TextureRect   = $Background/RightPanel/ItemIcon
@onready var _item_desc_label: Label         = $Background/RightPanel/ItemDescLabel
@onready var _price_container: VBoxContainer = $Background/RightPanel/PriceContainer
@onready var _qty_box:         SpinBox       = $Background/RightPanel/QtyBox
@onready var _buy_button:      Button        = $Background/RightPanel/BuyButton
@onready var _close_button:    Button        = $Background/CloseButton
@onready var _upgrade_panel:         Control = $Background/UpgradePanel
@onready var _upgrade_weapon_label:  Label   = $Background/UpgradePanel/UpgradeWeaponLabel
@onready var _upgrade_rarity_label:  Label   = $Background/UpgradePanel/RarityRow/UpgradeRarityLabel
@onready var _upgrade_arrow_label:   Label   = $Background/UpgradePanel/RarityRow/UpgradeArrowLabel
@onready var _upgrade_next_label:    Label   = $Background/UpgradePanel/RarityRow/UpgradeNextLabel
@onready var _upgrade_cost_container:VBoxContainer = $Background/UpgradePanel/UpgradeCostContainer
@onready var _upgrade_button:        Button  = $Background/UpgradePanel/UpgradeButton
@onready var _left_panel:            Panel   = $Background/LeftPanel
@onready var _right_panel_ctrl:      NinePatchRect = $Background/RightPanel

var _item_buttons: Array[Button] = []
var _station:       ShopStationNode = null
var _selected_item: ShopItem        = null
var _open_tween:    Tween           = null


func _ready() -> void:
	if not get_parent() is CanvasLayer:
		var cl       := CanvasLayer.new()
		cl.layer      = 10
		cl.name       = "ShopUILayer"
		get_tree().root.call_deferred("add_child", cl)
		await get_tree().process_frame
		get_parent().remove_child(self)
		cl.add_child(self)

	_buy_button.pressed.connect(_on_buy_pressed)
	_upgrade_button.pressed.connect(_on_upgrade_rarity_pressed)
	_style_action_btn(_buy_button, true)
	_style_action_btn(_upgrade_button, true)
	hide()


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


func _refresh() -> void:
	if _station == null or _station.shop_resource == null:
		return
	var res := _station.shop_resource
	_station_label.text = res.shop_name.to_upper()

	var desc_lines := res.description.split("\n")
	_subtitle_label.text = desc_lines[0] if desc_lines.size() > 0 else ""

	var is_upgrade_shop := _station.upgrade_weapon_rarity
	_upgrade_panel.visible        = is_upgrade_shop
	_right_panel_ctrl.visible     = not is_upgrade_shop
	_left_panel.visible           = not is_upgrade_shop

	if is_upgrade_shop:
		_refresh_upgrade_panel()
	else:
		_populate_item_list()
		if _selected_item != null:
			_show_item(_selected_item)


func _refresh_upgrade_panel() -> void:
	var weapon := _get_equipped_weapon()
	if weapon == null or weapon.resource == null:
		_upgrade_weapon_label.text   = "No weapon equipped"
		_upgrade_rarity_label.text   = ""
		_upgrade_arrow_label.text    = ""
		_upgrade_next_label.text     = ""
		_upgrade_button.disabled     = true
		_style_action_btn(_upgrade_button, true)
		for c in _upgrade_cost_container.get_children():
			c.queue_free()
		return

	var res        := weapon.resource
	var cur_rarity = res.rarity
	var max_rarity := 4

	_upgrade_weapon_label.text = res.Name

	if cur_rarity >= max_rarity:
		_upgrade_rarity_label.text  = RARITY_NAMES[cur_rarity]
		_upgrade_rarity_label.add_theme_color_override("font_color", RARITY_COLORS[cur_rarity])
		_upgrade_arrow_label.text   = ""
		_upgrade_next_label.text    = "Max rarity reached"
		_upgrade_next_label.add_theme_color_override("font_color", C_TEXT_DIM)
		_upgrade_button.disabled    = true
		_style_action_btn(_upgrade_button, true)
		for c in _upgrade_cost_container.get_children():
			c.queue_free()
		return

	var next_rarity = cur_rarity + 1

	_upgrade_rarity_label.text = RARITY_NAMES[cur_rarity]
	_upgrade_rarity_label.add_theme_color_override("font_color", RARITY_COLORS[cur_rarity])
	_upgrade_arrow_label.text  = "->"
	_upgrade_next_label.text   = RARITY_NAMES[next_rarity]
	_upgrade_next_label.add_theme_color_override("font_color", RARITY_COLORS[next_rarity])

	for c in _upgrade_cost_container.get_children():
		c.queue_free()

	var upgrade_data := _get_upgrade_cost_data(next_rarity)
	for cost_entry in upgrade_data:
		if cost_entry.type == "shards":
			var have  := Crafting.available_shards()
			var label := "%.0f / %.0f shards" % [have, cost_entry.amount]
			if GameManager.is_in_lobby:
				label += "  (player + safe)"
			var lbl := Label.new()
			lbl.text = label
			lbl.add_theme_font_size_override("font_size", 18)
			lbl.add_theme_color_override("font_color", C_GREEN if have >= cost_entry.amount else C_RED)
			_upgrade_cost_container.add_child(lbl)
		elif cost_entry.type == "item":
			var have := Crafting.get_material_count(cost_entry.item_resource)
			_upgrade_cost_container.add_child(
				_ing_row(cost_entry.item_resource.Name, cost_entry.amount, have)
			)

	var can_afford_upgrade := _can_afford_upgrade(next_rarity)
	_upgrade_button.disabled = not can_afford_upgrade
	_style_action_btn(_upgrade_button, not can_afford_upgrade)


func _get_upgrade_cost_data(target_rarity: int) -> Array:
	if _station == null or _station.shop_resource == null:
		return []
	var res := _station.shop_resource
	if not res.has_method("get_rarity_upgrade_costs"):
		var shard_costs := [0, 50, 150, 350, 700]
		return [{ "type": "shards", "amount": shard_costs[target_rarity] }]
	return res.get_rarity_upgrade_costs(target_rarity)


func _can_afford_upgrade(target_rarity: int) -> bool:
	var costs := _get_upgrade_cost_data(target_rarity)
	for cost_entry in costs:
		if cost_entry.type == "shards":
			if Crafting.available_shards() < cost_entry.amount:
				return false
		elif cost_entry.type == "item":
			if Crafting.get_material_count(cost_entry.item_resource) < cost_entry.amount:
				return false
	return true


func _on_upgrade_rarity_pressed() -> void:
	var weapon := _get_equipped_weapon()
	if weapon == null or weapon.resource == null:
		return

	var res := weapon.resource
	var cur_rarity = res.rarity
	if cur_rarity >= 4:
		return

	var next_rarity = cur_rarity + 1
	if not _can_afford_upgrade(next_rarity):
		return

	var costs := _get_upgrade_cost_data(next_rarity)
	for cost_entry in costs:
		if cost_entry.type == "shards":
			Crafting._consume_shards(cost_entry.amount)
		elif cost_entry.type == "item":
			Crafting._consume_material(cost_entry.item_resource, cost_entry.amount)

	var old_damage_buff = weapon.rarity_damage_buff()
	res.rarity           = next_rarity
	var new_damage_buff  = weapon.rarity_damage_buff()
	weapon.damageMod    += (new_damage_buff - old_damage_buff)
	res.rarity_applied   = true

	_upgrade_button.text     = "Upgraded!"
	_upgrade_button.disabled = true
	_style_action_btn(_upgrade_button, true)
	weapon.change_rarity(next_rarity)
	await get_tree().create_timer(1.2).timeout
	if is_instance_valid(_upgrade_button):
		_upgrade_button.text = "Upgrade"
		_refresh_upgrade_panel()


func _get_equipped_weapon() -> Weapon:
	if GlobalPlayer.player == null:
		return null
	var player := GlobalPlayer.manager
	return player.get_weapon()


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
		btn.custom_minimum_size = Vector2(345, 54)
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
			var ph_rect         := ColorRect.new()
			ph_rect.color        = C_BORDER
			ph_rect.position     = Vector2(8, 11)
			ph_rect.size         = Vector2(32, 32)
			ph_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.add_child(ph_rect)

		btn.text = shop_item.get_display_name()

		var price_txt := _price_text(shop_item)
		var price_col := C_ACCENT if shop_item.price_type == ShopItem.PriceType.SHARDS else C_TEXT_DIM
		var price_chip         := _pill_label(price_txt, price_col, C_BADGE_BG)
		price_chip.position     = Vector2(345 - 105, 12)
		price_chip.size         = Vector2(95, 30)
		price_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(price_chip)

		var stock_txt := ""
		if not in_stock:
			stock_txt = "sold out"
		elif shop_item.stock == -1:
			stock_txt = "unlimited"
		else:
			stock_txt = "x%d" % shop_item.stock
		var stock_col  := C_TEXT_MICRO if in_stock else C_RED
		var stock_chip := _pill_label(stock_txt, stock_col, C_PANEL_DARK)
		stock_chip.position     = Vector2(345 - 105, 42)
		stock_chip.size         = Vector2(95, 22)
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
			return "%.0f shards" % shop_item.shard_price
		ShopItem.PriceType.ITEMS:
			return "Barter"
		ShopItem.PriceType.FREE:
			return "Free"
	return ""


func _select_item(shop_item: ShopItem, btn_idx: int) -> void:
	_selected_item = shop_item
	_show_item(shop_item)
	for i in _item_buttons.size():
		var active := i == btn_idx
		var sb     := StyleBoxFlat.new()
		sb.bg_color            = Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.14) if active else Color.TRANSPARENT
		sb.border_width_left   = 6 if active else 0
		sb.border_color        = C_ACCENT
		sb.content_margin_left = 48
		_item_buttons[i].add_theme_stylebox_override("normal", sb)


func _show_item(shop_item: ShopItem) -> void:
	_item_name_label.text = shop_item.get_display_name().to_upper()
	_item_amount_lbl.text = "x%d" % shop_item.amount if shop_item.amount > 1 else ""
	_item_icon.texture    = shop_item.get_icon()
	_item_desc_label.text = shop_item.description

	for c in _price_container.get_children():
		c.queue_free()

	match shop_item.price_type:
		ShopItem.PriceType.SHARDS:
			var avail := Crafting.available_shards()
			var qty   := int(_qty_box.value)
			var cost  := shop_item.shard_price * qty
			var label := "%.0f / %.0f shards" % [avail, cost]
			if GameManager.is_in_lobby:
				label += "  (player + safe)"
			var lbl := Label.new()
			lbl.text = label
			lbl.add_theme_font_size_override("font_size", 18)
			lbl.add_theme_color_override("font_color", C_GREEN if avail >= cost else C_RED)
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
			var lbl := Label.new()
			lbl.text = "Free"
			lbl.add_theme_font_size_override("font_size", 20)
			lbl.add_theme_color_override("font_color", C_GREEN)
			_price_container.add_child(lbl)

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

	_buy_button.disabled = not (shop_item.is_in_stock() and can_afford(shop_item, int(_qty_box.value)))
	_buy_button.text     = "Buy"
	_style_action_btn(_buy_button, _buy_button.disabled)


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


func _on_buy_pressed() -> void:
	if _selected_item == null or _station == null:
		return
	var qty := int(_qty_box.value) if not _qty_box.is_hidden() else 1
	if not _selected_item.is_in_stock():
		return
	if not can_afford(_selected_item, qty):
		return

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

	Crafting._give_item(_selected_item.item_resource, _selected_item.amount * qty)

	if _selected_item.stock != -1:
		_selected_item.stock -= qty

	_populate_item_list()
	_show_item(_selected_item)

	_buy_button.text     = "Bought!"
	_buy_button.disabled = true
	await get_tree().create_timer(1.2).timeout
	if is_instance_valid(_buy_button):
		_buy_button.text = "Buy"
		if _selected_item != null:
			_show_item(_selected_item)


func _pill_label(txt: String, font_col: Color, bg_col: Color) -> Panel:
	var panel  := Panel.new()
	var sb     := StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.set_corner_radius_all(_CORNER)
	panel.add_theme_stylebox_override("panel", sb)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lbl                 := Label.new()
	lbl.text                 = txt
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", font_col)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(lbl)
	return panel


func _ing_row(item_name: String, need: int, have: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 33)
	row.add_theme_constant_override("separation", 6)

	var dot := Label.new()
	dot.text = "-"
	dot.add_theme_font_size_override("font_size", 18)
	dot.add_theme_color_override("font_color", C_BORDER_LIT)
	dot.custom_minimum_size = Vector2(18, 0)
	row.add_child(dot)

	var nl := Label.new()
	nl.text = item_name
	nl.add_theme_font_size_override("font_size", 18)
	nl.add_theme_color_override("font_color", C_TEXT)
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
	var cl := Label.new()
	cl.text = "%d / %d" % [have, need]
	cl.add_theme_font_size_override("font_size", 17)
	cl.add_theme_color_override("font_color", col)
	cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	cl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	chip.add_child(cl)
	row.add_child(chip)

	return row


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
