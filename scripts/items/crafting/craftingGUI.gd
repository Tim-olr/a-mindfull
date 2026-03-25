extends Control
class_name CraftingUI

## ─────────────────────────────────────────────
##  CraftingUI  —  fully self-contained, no scene file needed.
##  Add a bare Control node anywhere, attach this script.
##  Reparents itself onto a CanvasLayer automatically.
## ─────────────────────────────────────────────

# ── Palette ───────────────────────────────────
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
const W         := 1170
const H         := 780
const PAD       := 21
const LIST_W    := 345
const TAB_H     := 54
const _CORNER   := 9

# ── Nodes ─────────────────────────────────────
var _station_label:    Label
var _subtitle_label:   Label
var _hub_label:        Label         # shows "HUB — Safe included" banner
var _tab_craft_btn:    Button
var _tab_upgrade_btn:  Button
var _craft_tab:        Control
var _recipe_list:      VBoxContainer
var _search_bar:       LineEdit
var _recipe_name:      Label
var _recipe_desc:      Label
var _ingredient_list:  VBoxContainer
var _shard_cost_label: Label
var _craft_button:     Button
var _material_list:    VBoxContainer
var _upgrade_tab:      Control
var _upgrade_desc:     Label
var _upgrade_cost_list:VBoxContainer
var _upgrade_shard_lbl:Label
var _upgrade_button:   Button
var _level_progress:   ProgressBar

# ── State ─────────────────────────────────────
var _station:         CraftingStationNode = null
var _selected_recipe: CraftingRecipe      = null
var _recipe_buttons:  Array[Button]       = []
var _recipe_for_btn:  Array[CraftingRecipe] = []
var _craft_tween:     Tween               = null
var _open_tween:      Tween               = null


# ════════════════════════════════════════════════
#  Bootstrap
# ════════════════════════════════════════════════

func _ready() -> void:
	if not get_parent() is CanvasLayer:
		var cl       := CanvasLayer.new()
		cl.layer      = 10
		cl.name       = "CraftingUILayer"
		get_tree().root.call_deferred("add_child", cl)
		await get_tree().process_frame
		get_parent().remove_child(self)
		cl.add_child(self)

	_build_ui()
	hide()
	Crafting.craft_succeeded.connect(func(_r, _s): _on_craft_result(true))
	Crafting.craft_failed.connect(func(_r, _s):    _on_craft_result(false))


# ════════════════════════════════════════════════
#  Public API
# ════════════════════════════════════════════════

func open_for_station(station: CraftingStationNode) -> void:
	_station         = station
	_selected_recipe = null
	if _search_bar:
		_search_bar.text = ""
	modulate.a = 0.0
	scale      = Vector2(0.92, 0.92)
	show()
	_switch_tab(0)
	_refresh()
	if _open_tween:
		_open_tween.kill()
	_open_tween = create_tween().set_parallel(true)
	_open_tween.tween_property(self, "scale",      Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_open_tween.tween_property(self, "modulate:a", 1.0,               0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func close() -> void:
	_station = null
	if _craft_tween:
		_craft_tween.kill()
		_craft_tween = null
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
	var grad           := Gradient.new()
	grad.set_color(0, C_ACCENT)
	grad.set_color(1, Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.0))
	var grad_tex       := GradientTexture1D.new()
	grad_tex.gradient   = grad
	var stripe          := TextureRect.new()
	stripe.texture       = grad_tex
	stripe.stretch_mode  = TextureRect.STRETCH_SCALE
	stripe.size          = Vector2(W, 5)
	stripe.position      = Vector2.ZERO
	bg.add_child(stripe)

	# Station title
	_station_label                      = _lbl("", 23, C_ACCENT, true)
	_station_label.position             = Vector2(0, 10)
	_station_label.size                 = Vector2(W, 30)
	_station_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bg.add_child(_station_label)

	# Station subtitle (Lv. X / Y)
	_subtitle_label                      = _lbl("", 14, C_TEXT_DIM)
	_subtitle_label.position             = Vector2(0, 40)
	_subtitle_label.size                 = Vector2(W, 18)
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bg.add_child(_subtitle_label)

	# ── Tabs ──────────────────────────────────
	var tab_y := 65
	var half  := (W - PAD * 2) / 2.0
	_tab_craft_btn   = _tab_btn("⚒  Craft",   Vector2(PAD,        tab_y), half)
	_tab_upgrade_btn = _tab_btn("▲  Upgrade", Vector2(PAD + half, tab_y), half)
	_tab_craft_btn.pressed.connect(func():   _switch_tab(0))
	_tab_upgrade_btn.pressed.connect(func(): _switch_tab(1))
	bg.add_child(_tab_craft_btn)
	bg.add_child(_tab_upgrade_btn)

	var tab_sep      := ColorRect.new()
	tab_sep.color     = C_BORDER
	tab_sep.size      = Vector2(W - PAD * 2, 2)
	tab_sep.position  = Vector2(PAD, tab_y + TAB_H)
	bg.add_child(tab_sep)

	# ── Body ──────────────────────────────────
	var body_y := tab_y + TAB_H + 12
	var body_h := H - body_y - PAD

	_craft_tab           = _build_craft_tab(body_y, body_h)
	_upgrade_tab         = _build_upgrade_tab(body_y, body_h)
	_upgrade_tab.visible = false
	bg.add_child(_craft_tab)
	bg.add_child(_upgrade_tab)


func _build_craft_tab(body_y: int, body_h: int) -> Control:
	var tab      := Control.new()
	tab.position  = Vector2(PAD, body_y)
	tab.size      = Vector2(W - PAD * 2, body_h)

	# ── Left panel ────────────────────────────
	var lp := _make_box(Vector2(LIST_W, body_h), Vector2.ZERO, C_PANEL_DARK, C_BORDER)
	tab.add_child(lp)

	var rh      := _lbl("RECIPES", 14, C_TEXT_DIM, true)
	rh.position  = Vector2(15, 12)
	lp.add_child(rh)

	# Search bar
	_search_bar                     = LineEdit.new()
	_search_bar.position            = Vector2(8, 32)
	_search_bar.size                = Vector2(LIST_W - 16, 30)
	_search_bar.placeholder_text    = "Search recipes…"
	_search_bar.add_theme_font_size_override("font_size", 14)
	_search_bar.add_theme_color_override("font_color",             C_TEXT)
	_search_bar.add_theme_color_override("font_placeholder_color", C_TEXT_DIM)
	var sb_le                       := StyleBoxFlat.new()
	sb_le.bg_color                   = C_PANEL
	sb_le.border_color               = C_BORDER
	sb_le.set_border_width_all(1)
	sb_le.set_corner_radius_all(_CORNER)
	sb_le.content_margin_left        = 8
	sb_le.content_margin_right       = 8
	_search_bar.add_theme_stylebox_override("normal", sb_le)
	_search_bar.add_theme_stylebox_override("focus",  sb_le)
	_search_bar.text_changed.connect(_on_search_changed)
	lp.add_child(_search_bar)

	var scroll                    := ScrollContainer.new()
	scroll.position                = Vector2(0, 66)
	scroll.size                    = Vector2(LIST_W, body_h - 66 - 141)
	scroll.vertical_scroll_mode   = ScrollContainer.SCROLL_MODE_AUTO
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	lp.add_child(scroll)

	_recipe_list                      = VBoxContainer.new()
	_recipe_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_recipe_list)

	# Material divider
	var md      := ColorRect.new()
	md.color     = C_BORDER
	md.size      = Vector2(LIST_W, 2)
	md.position  = Vector2(0, body_h - 138)
	lp.add_child(md)

	var mh      := _lbl("MATERIALS", 14, C_TEXT_DIM, true)
	mh.position  = Vector2(15, body_h - 126)
	lp.add_child(mh)

	var ms                    := ScrollContainer.new()
	ms.position                = Vector2(0, body_h - 102)
	ms.size                    = Vector2(LIST_W, 93)
	ms.vertical_scroll_mode   = ScrollContainer.SCROLL_MODE_AUTO
	ms.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	lp.add_child(ms)

	_material_list                      = VBoxContainer.new()
	_material_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ms.add_child(_material_list)

	# ── Right panel ───────────────────────────
	var rw := W - PAD * 2 - LIST_W - 15
	var rp  := _make_box(Vector2(rw, body_h), Vector2(LIST_W + 15, 0), C_PANEL, C_BORDER)
	tab.add_child(rp)

	_recipe_name          = _lbl("Select a recipe", 21, C_ACCENT, true)
	_recipe_name.position = Vector2(PAD, PAD)
	_recipe_name.size     = Vector2(rw - PAD * 2, 33)
	rp.add_child(_recipe_name)

	var ns      := ColorRect.new()
	ns.color     = C_ACCENT_DIM
	ns.size      = Vector2(rw - PAD * 2, 2)
	ns.position  = Vector2(PAD, PAD + 39)
	rp.add_child(ns)

	_recipe_desc               = _lbl("", 17, C_TEXT_DIM)
	_recipe_desc.position      = Vector2(PAD, PAD + 48)
	_recipe_desc.size          = Vector2(rw - PAD * 2, 57)
	_recipe_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rp.add_child(_recipe_desc)

	var ih      := _lbl("INGREDIENTS", 14, C_TEXT_DIM, true)
	ih.position  = Vector2(PAD, PAD + 114)
	rp.add_child(ih)

	_ingredient_list          = VBoxContainer.new()
	_ingredient_list.position = Vector2(PAD, PAD + 138)
	_ingredient_list.size     = Vector2(rw - PAD * 2, 255)
	rp.add_child(_ingredient_list)

	_shard_cost_label          = _lbl("", 18, C_ACCENT)
	_shard_cost_label.position = Vector2(PAD, PAD + 402)
	_shard_cost_label.size     = Vector2(rw - PAD * 2, 30)
	rp.add_child(_shard_cost_label)

	_craft_button = _action_btn("⚒  Craft",
		Vector2(PAD, body_h - 78),
		Vector2(rw - PAD * 2, 60))
	_craft_button.pressed.connect(_on_craft_pressed)
	rp.add_child(_craft_button)

	return tab


func _build_upgrade_tab(body_y: int, body_h: int) -> Control:
	var tab      := Control.new()
	tab.position  = Vector2(PAD, body_y)
	tab.size      = Vector2(W - PAD * 2, body_h)

	var up := _make_box(Vector2(W - PAD * 2, body_h), Vector2.ZERO, C_PANEL, C_BORDER)
	tab.add_child(up)

	# Level progress bar
	_level_progress                 = ProgressBar.new()
	_level_progress.position        = Vector2(PAD, PAD)
	_level_progress.size            = Vector2(W - PAD * 4, 10)
	_level_progress.min_value       = 0.0
	_level_progress.max_value       = 1.0
	_level_progress.value           = 0.0
	_level_progress.show_percentage = false
	var pb_bg                       := StyleBoxFlat.new()
	pb_bg.bg_color                   = C_PANEL_DARK
	pb_bg.set_corner_radius_all(_CORNER)
	var pb_fill                     := StyleBoxFlat.new()
	pb_fill.bg_color                 = C_ACCENT
	pb_fill.set_corner_radius_all(_CORNER)
	_level_progress.add_theme_stylebox_override("background", pb_bg)
	_level_progress.add_theme_stylebox_override("fill",       pb_fill)
	up.add_child(_level_progress)

	_upgrade_desc               = _lbl("", 20, C_ACCENT, true)
	_upgrade_desc.position      = Vector2(PAD, PAD + 18)
	_upgrade_desc.size          = Vector2(W - PAD * 4, 90)
	_upgrade_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	up.add_child(_upgrade_desc)

	var us      := ColorRect.new()
	us.color     = C_ACCENT_DIM
	us.size      = Vector2(W - PAD * 4, 2)
	us.position  = Vector2(PAD, PAD + 117)
	up.add_child(us)

	var uh      := _lbl("UPGRADE COST", 14, C_TEXT_DIM, true)
	uh.position  = Vector2(PAD, PAD + 129)
	up.add_child(uh)

	_upgrade_cost_list          = VBoxContainer.new()
	_upgrade_cost_list.position = Vector2(PAD, PAD + 156)
	_upgrade_cost_list.size     = Vector2(W - PAD * 4, 300)
	up.add_child(_upgrade_cost_list)

	_upgrade_shard_lbl          = _lbl("", 18, C_ACCENT)
	_upgrade_shard_lbl.position = Vector2(PAD, PAD + 468)
	_upgrade_shard_lbl.size     = Vector2(W - PAD * 4, 30)
	up.add_child(_upgrade_shard_lbl)

	_upgrade_button = _action_btn("▲  Upgrade Station",
		Vector2(PAD, body_h - 78),
		Vector2(W - PAD * 4, 60))
	_upgrade_button.pressed.connect(_on_upgrade_pressed)
	up.add_child(_upgrade_button)

	return tab


# ════════════════════════════════════════════════
#  Refresh
# ════════════════════════════════════════════════

func _refresh() -> void:
	if _station == null:
		return
	var base   := _station.station_resource.station_name if _station.station_resource else "Station"
	var max_lv := _station.station_resource.get_max_level() if _station.station_resource else 1
	_station_label.text  = base.to_upper()
	_subtitle_label.text = "Lv. %d / %d" % [_station.current_level, max_lv]

	_populate_recipe_list()
	_populate_material_panel()
	_populate_upgrade_tab()

	if _selected_recipe != null:
		_show_recipe(_selected_recipe)
		# Re-highlight in list if still visible
		for i in _recipe_for_btn.size():
			if _recipe_for_btn[i] == _selected_recipe:
				_highlight_recipe_btn(i)
				break

	var can_up := _station.station_resource.can_level_up(_station.current_level)
	_tab_upgrade_btn.modulate = Color.WHITE if can_up else Color(0.5, 0.5, 0.5, 0.7)
	_tab_upgrade_btn.disabled = not can_up


func _switch_tab(tab: int) -> void:
	_craft_tab.visible   = tab == 0
	_upgrade_tab.visible = tab == 1
	_style_tab_btn(_tab_craft_btn,   tab == 0)
	_style_tab_btn(_tab_upgrade_btn, tab == 1)


# ════════════════════════════════════════════════
#  Search
# ════════════════════════════════════════════════

func _on_search_changed(_text: String) -> void:
	if _station == null:
		return
	_populate_recipe_list()


# ════════════════════════════════════════════════
#  Recipe list
# ════════════════════════════════════════════════

func _populate_recipe_list() -> void:
	for b in _recipe_buttons:
		b.queue_free()
	_recipe_buttons.clear()
	_recipe_for_btn.clear()

	var filter  := _search_bar.text.to_lower() if _search_bar else ""
	var recipes := _station.get_current_recipes()
	for i in recipes.size():
		var recipe := recipes[i]
		if filter != "" and not recipe.recipe_name.to_lower().contains(filter):
			continue
		var can     := Crafting.can_craft(recipe)
		var btn     := Button.new()
		btn.text                = recipe.recipe_name
		btn.flat                = true
		btn.alignment           = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(LIST_W, 51)
		btn.add_theme_font_size_override("font_size", 18)
		btn.add_theme_color_override("font_color",         C_TEXT if can else C_TEXT_DIM)
		btn.add_theme_color_override("font_hover_color",   C_TEXT)
		btn.add_theme_color_override("font_pressed_color", C_ACCENT)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

		var sb_n := StyleBoxFlat.new()
		sb_n.bg_color            = Color.TRANSPARENT
		sb_n.content_margin_left = 15
		btn.add_theme_stylebox_override("normal", sb_n)

		var sb_h := StyleBoxFlat.new()
		sb_h.bg_color            = Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.10)
		sb_h.content_margin_left = 15
		btn.add_theme_stylebox_override("hover", sb_h)

		if not can:
			var x                := _lbl("✕", 15, C_RED)
			x.position            = Vector2(LIST_W - 33, 0)
			x.size                = Vector2(27, 51)
			x.vertical_alignment  = VERTICAL_ALIGNMENT_CENTER
			btn.add_child(x)

		# Ingredient count pill badge
		var ing_count := 0
		for ing in recipe.ingredients:
			if ing != null and ing.item_resource != null:
				ing_count += 1
		var badge          := _pill_label("%d ing." % ing_count, C_TEXT_MICRO, C_BADGE_BG)
		badge.position      = Vector2(LIST_W - 120, 12)
		badge.size          = Vector2(72, 27)
		badge.mouse_filter  = Control.MOUSE_FILTER_IGNORE
		btn.add_child(badge)

		var btn_idx := _recipe_buttons.size()
		btn.pressed.connect(_select_recipe.bind(recipe, btn_idx))
		_recipe_list.add_child(btn)
		_recipe_buttons.append(btn)
		_recipe_for_btn.append(recipe)


func _select_recipe(recipe: CraftingRecipe, btn_idx: int) -> void:
	_selected_recipe = recipe
	_show_recipe(recipe)
	_highlight_recipe_btn(btn_idx)


func _highlight_recipe_btn(btn_idx: int) -> void:
	for i in _recipe_buttons.size():
		var active := i == btn_idx
		var sb     := StyleBoxFlat.new()
		sb.bg_color          = Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.14) if active else Color.TRANSPARENT
		sb.border_width_left = 6 if active else 0
		sb.border_color      = C_ACCENT
		sb.content_margin_left = 15
		_recipe_buttons[i].add_theme_stylebox_override("normal", sb)


# ════════════════════════════════════════════════
#  Recipe details
# ════════════════════════════════════════════════

func _show_recipe(recipe: CraftingRecipe) -> void:
	_recipe_name.text = recipe.recipe_name.to_upper()
	_recipe_desc.text = recipe.description

	if recipe.needs_shards:
		var have  := Crafting.available_shards()    # hub-aware
		var label := "◈  %.0f / %.0f shards" % [have, recipe.shard_cost]
		if GameManager.is_in_lobby:
			label += "  (player + safe)"
		_shard_cost_label.text     = label
		_shard_cost_label.modulate = C_GREEN if have >= recipe.shard_cost else C_RED
		_shard_cost_label.show()
	else:
		_shard_cost_label.hide()

	for c in _ingredient_list.get_children():
		c.queue_free()
	for ing in recipe.ingredients:
		if ing == null or ing.item_resource == null:
			continue
		_ingredient_list.add_child(
			_ing_row(ing.item_resource.Name, ing.amount,
			Crafting.get_material_count(ing.item_resource))
		)

	var can_craft := Crafting.can_craft(recipe)
	_craft_button.disabled = not can_craft
	_craft_button.text     = "⚒  Craft"
	_style_action_btn(_craft_button, _craft_button.disabled)

	# Pulsing glow when enabled
	if _craft_tween:
		_craft_tween.kill()
		_craft_tween = null
	if can_craft:
		_craft_tween = create_tween().set_loops()
		_craft_tween.tween_property(_craft_button, "modulate:a", 0.85, 1.0)
		_craft_tween.tween_property(_craft_button, "modulate:a", 1.0,  1.0)
	else:
		_craft_button.modulate.a = 1.0


func _ing_row(item_name: String, need: int, have: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 33)
	row.add_theme_constant_override("separation", 6)

	# ▸ chevron in C_BORDER_LIT
	var dot := _lbl("▸", 18, C_BORDER_LIT)
	dot.custom_minimum_size = Vector2(18, 0)
	row.add_child(dot)

	var nl := _lbl(item_name, 18, C_TEXT)
	nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(nl)

	# Rounded chip background behind the count label
	var in_inv   := _count_inv_only(item_name)
	var enough   := have >= need
	var col      := C_GREEN if enough else C_RED
	if GameManager.is_in_lobby and in_inv < need and enough:
		col = C_SAFE                                        # safe is covering the gap

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


## Inventory-only count (no safe) used for hub tinting.
func _count_inv_only(item_name: String) -> int:
	var total := 0
	if GlobalPlayer.inventory == null:
		return 0
	var inv = GlobalPlayer.inventory.inventory
	if inv == null:
		return 0
	for slot in inv.slots_with_items:
		if slot == null:
			continue
		var held: ItemResource = slot.item
		if held == null or held.Name != item_name:
			continue
		total += held.amount if held.isStackable else 1
	return total


# ════════════════════════════════════════════════
#  Material panel
# ════════════════════════════════════════════════

func _populate_material_panel() -> void:
	for c in _material_list.get_children():
		c.queue_free()

	var mats := Crafting.get_all_materials()    # hub-aware
	if mats.is_empty():
		_material_list.add_child(_lbl("  none", 15, C_TEXT_DIM))
		return

	for mat in mats:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)

		var in_inv := _count_inv_only(mat.Name) > 0
		var col    := C_TEXT_DIM if in_inv else C_SAFE

		# Prefix with lock symbol if sourced from safe in hub mode
		var prefix := "🔒 " if (not in_inv and GameManager.is_in_lobby) else "  "
		var nl := _lbl(prefix + mat.Name, 15, col)
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(nl)
		row.add_child(_lbl("x%d  " % (mat.amount if mat.isStackable else 1), 15, C_TEXT, true))
		_material_list.add_child(row)


# ════════════════════════════════════════════════
#  Upgrade tab
# ════════════════════════════════════════════════

func _populate_upgrade_tab() -> void:
	if _station == null:
		return
	var data := _station.get_current_level_data()
	if data == null:
		return

	# Level progress bar
	var max_lv := _station.station_resource.get_max_level() if _station.station_resource else 1
	_level_progress.max_value = float(max_lv)
	_level_progress.value     = float(_station.current_level)

	_upgrade_desc.text = "Upgrade to Level %d" % (_station.current_level + 1)
	if data.level_name != "":
		_upgrade_desc.text += "\n" + data.level_name
	elif data.level_description != "":
		_upgrade_desc.text += "\n" + data.level_description

	for c in _upgrade_cost_list.get_children():
		c.queue_free()
	for ing in data.upgrade_ingredients:
		if ing == null or ing.item_resource == null:
			continue
		_upgrade_cost_list.add_child(
			_ing_row(ing.item_resource.Name, ing.amount,
			Crafting.get_material_count(ing.item_resource))
		)

	if data.upgrade_needs_shards:
		var have  := Crafting.available_shards()
		var label := "◈  %.0f / %.0f shards" % [have, data.upgrade_shard_cost]
		if GameManager.is_in_lobby:
			label += "  (player + safe)"
		_upgrade_shard_lbl.text     = label
		_upgrade_shard_lbl.modulate = C_GREEN if have >= data.upgrade_shard_cost else C_RED
		_upgrade_shard_lbl.show()
	else:
		_upgrade_shard_lbl.hide()

	_upgrade_button.disabled = not _station.can_upgrade()
	_style_action_btn(_upgrade_button, _upgrade_button.disabled)


# ════════════════════════════════════════════════
#  Button callbacks
# ════════════════════════════════════════════════

func _on_craft_pressed() -> void:
	if _selected_recipe == null or _station == null:
		return
	Crafting.craft(_selected_recipe, _station)


func _on_craft_result(success: bool) -> void:
	_craft_button.text = "✓  Crafted!" if success else "✕  Can't craft"
	if success:
		_refresh()
		await get_tree().create_timer(1.2).timeout
		if is_instance_valid(_craft_button):
			_craft_button.text = "⚒  Craft"


func _on_upgrade_pressed() -> void:
	if _station == null:
		return
	if _station.upgrade():
		_upgrade_button.text = "✓  Upgraded!"
		_refresh()
		await get_tree().create_timer(1.2).timeout
		if is_instance_valid(_upgrade_button):
			_upgrade_button.text = "▲  Upgrade Station"


# ════════════════════════════════════════════════
#  Widget helpers
# ════════════════════════════════════════════════

func _make_box(sz: Vector2, pos: Vector2, bg_col: Color,
			   border_col: Color = Color.TRANSPARENT) -> Control:
	var c       := Control.new()
	c.size       = sz
	c.position   = pos
	var sb      := StyleBoxFlat.new()
	sb.bg_color  = bg_col
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
	var lbl                    := _lbl(txt, 13, font_col, true)
	lbl.horizontal_alignment    = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment      = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(lbl)
	return panel


func _tab_btn(txt: String, pos: Vector2, w: float) -> Button:
	var btn     := Button.new()
	btn.text     = txt
	btn.position = pos
	btn.size     = Vector2(w, TAB_H)
	btn.flat     = true
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_style_tab_btn(btn, false)
	return btn


func _style_tab_btn(btn: Button, active: bool) -> void:
	var sb                  := StyleBoxFlat.new()
	sb.bg_color              = Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.08) if active else Color.TRANSPARENT
	sb.border_width_bottom   = 4 if active else 0
	sb.border_color          = C_ACCENT
	sb.set_corner_radius_all(_CORNER)
	btn.add_theme_stylebox_override("normal",  sb)
	btn.add_theme_stylebox_override("hover",   sb)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_color_override("font_color",         C_ACCENT if active else C_TEXT_DIM)
	btn.add_theme_color_override("font_hover_color",   C_ACCENT if active else C_TEXT)
	btn.add_theme_color_override("font_pressed_color", C_ACCENT)


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
