extends Control
class_name CraftingUI

# ── Palette ──────────────────────────────────────
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

# ── Scene node refs ───────────────────────────────
@onready var _station_label:    Label         = $Background/StationLabel
@onready var _subtitle_label:   Label         = $Background/SubtitleLabel
@onready var _tab_craft_btn:    Button        = $Background/TabCraftBtn
@onready var _tab_upgrade_btn:  Button        = $Background/TabUpgradeBtn
@onready var _craft_tab:        Control       = $Background/CraftTab
@onready var _recipe_list:      VBoxContainer = $Background/CraftTab/LeftPanel/RecipeScroll/RecipeList
@onready var _search_bar:       LineEdit      = $Background/CraftTab/LeftPanel/SearchBar
@onready var _recipe_name:      Label         = $Background/CraftTab/RightPanel/RecipeName
@onready var _recipe_desc:      Label         = $Background/CraftTab/RightPanel/RecipeDesc
@onready var _ingredient_list:  VBoxContainer = $Background/CraftTab/RightPanel/IngredientList
@onready var _shard_cost_label: Label         = $Background/CraftTab/RightPanel/ShardCostLabel
@onready var _craft_button:     Button        = $Background/CraftTab/RightPanel/CraftButton
@onready var _material_list:    VBoxContainer = $Background/CraftTab/LeftPanel/MaterialScroll/MaterialList
@onready var _upgrade_tab:      Control       = $Background/UpgradeTab
@onready var _upgrade_desc:     Label         = $Background/UpgradeTab/UpgradeDesc
@onready var _upgrade_cost_list:VBoxContainer = $Background/UpgradeTab/UpgradeCostList
@onready var _upgrade_shard_lbl:Label         = $Background/UpgradeTab/UpgradeShardLabel
@onready var _upgrade_button:   Button        = $Background/UpgradeTab/UpgradeButton
@onready var _level_progress:   ProgressBar   = $Background/UpgradeTab/LevelProgress

# ── State ─────────────────────────────────────────
var _station:         CraftingStationNode = null
var _selected_recipe: CraftingRecipe      = null
var _recipe_buttons:  Array[Button]       = []
var _recipe_for_btn:  Array[CraftingRecipe] = []
var _craft_tween:     Tween               = null
var _open_tween:      Tween               = null


func _ready() -> void:
	if not get_parent() is CanvasLayer:
		var cl       := CanvasLayer.new()
		cl.layer      = 10
		cl.name       = "CraftingUILayer"
		get_tree().root.call_deferred("add_child", cl)
		await get_tree().process_frame
		get_parent().remove_child(self)
		cl.add_child(self)

	_tab_craft_btn.pressed.connect(func():   _switch_tab(0))
	_tab_upgrade_btn.pressed.connect(func(): _switch_tab(1))
	_craft_button.pressed.connect(_on_craft_pressed)
	_upgrade_button.pressed.connect(_on_upgrade_pressed)
	_search_bar.text_changed.connect(_on_search_changed)

	_style_action_btn(_craft_button, true)
	_style_action_btn(_upgrade_button, false)
	_switch_tab(0)
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
		btn.custom_minimum_size = Vector2(345, 51)
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
			var x                := Label.new()
			x.text                = "x"
			x.add_theme_font_size_override("font_size", 15)
			x.add_theme_color_override("font_color", C_RED)
			x.position            = Vector2(345 - 33, 0)
			x.size                = Vector2(27, 51)
			x.vertical_alignment  = VERTICAL_ALIGNMENT_CENTER
			btn.add_child(x)

		var ing_count := 0
		for ing in recipe.ingredients:
			if ing != null and ing.item_resource != null:
				ing_count += 1
		var badge          := _pill_label("%d ing." % ing_count, C_TEXT_MICRO, C_BADGE_BG)
		badge.position      = Vector2(345 - 120, 12)
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
		sb.bg_color            = Color(C_ACCENT.r, C_ACCENT.g, C_ACCENT.b, 0.14) if active else Color.TRANSPARENT
		sb.border_width_left   = 6 if active else 0
		sb.border_color        = C_ACCENT
		sb.content_margin_left = 15
		_recipe_buttons[i].add_theme_stylebox_override("normal", sb)


# ════════════════════════════════════════════════
#  Recipe details
# ════════════════════════════════════════════════

func _show_recipe(recipe: CraftingRecipe) -> void:
	_recipe_name.text = recipe.recipe_name.to_upper()
	_recipe_desc.text = recipe.description

	if recipe.needs_shards:
		var have  := Crafting.available_shards()
		var label := "%.0f / %.0f shards" % [have, recipe.shard_cost]
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
	_craft_button.text     = "Craft"
	_style_action_btn(_craft_button, _craft_button.disabled)

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

	var in_inv   := _count_inv_only(item_name)
	var enough   := have >= need
	var col      := C_GREEN if enough else C_RED
	if GameManager.is_in_lobby and in_inv < need and enough:
		col = C_SAFE

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

	var mats := Crafting.get_all_materials()
	if mats.is_empty():
		var lbl := Label.new()
		lbl.text = "  none"
		lbl.add_theme_font_size_override("font_size", 15)
		lbl.add_theme_color_override("font_color", C_TEXT_DIM)
		_material_list.add_child(lbl)
		return

	for mat in mats:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)

		var in_inv := _count_inv_only(mat.Name) > 0
		var col    := C_TEXT_DIM if in_inv else C_SAFE
		var prefix := "[safe] " if (not in_inv and GameManager.is_in_lobby) else "  "
		var nl := Label.new()
		nl.text = prefix + mat.Name
		nl.add_theme_font_size_override("font_size", 15)
		nl.add_theme_color_override("font_color", col)
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(nl)

		var cnt := Label.new()
		cnt.text = "x%d  " % (mat.amount if mat.isStackable else 1)
		cnt.add_theme_font_size_override("font_size", 15)
		cnt.add_theme_color_override("font_color", C_TEXT)
		row.add_child(cnt)
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
		var label := "%.0f / %.0f shards" % [have, data.upgrade_shard_cost]
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
	_craft_button.text = "Crafted!" if success else "Cannot craft"
	if success:
		_refresh()
	await get_tree().create_timer(1.2).timeout
	if is_instance_valid(_craft_button):
		_craft_button.text = "Craft"


func _on_upgrade_pressed() -> void:
	if _station == null:
		return
	if _station.upgrade():
		_upgrade_button.text = "Upgraded!"
		_refresh()
		await get_tree().create_timer(1.2).timeout
		if is_instance_valid(_upgrade_button):
			_upgrade_button.text = "Upgrade Station"


# ════════════════════════════════════════════════
#  Widget helpers
# ════════════════════════════════════════════════

func _pill_label(txt: String, font_col: Color, bg_col: Color) -> Panel:
	var panel  := Panel.new()
	var sb     := StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.set_corner_radius_all(_CORNER)
	panel.add_theme_stylebox_override("panel", sb)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lbl                    := Label.new()
	lbl.text                    = txt
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", font_col)
	lbl.horizontal_alignment    = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment      = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(lbl)
	return panel


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
