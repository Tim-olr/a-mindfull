extends Control

const W := 1140.0
const H := 740.0
const PAD := 18.0
const NODE_W := 190.0
const NODE_H := 62.0
const NODE_GAP := 10.0
const COL_W := 210.0

const C_BG          := Color(0.07, 0.06, 0.05)
const C_PANEL       := Color(0.12, 0.10, 0.09)
const C_BORDER      := Color(0.28, 0.22, 0.15)
const C_ACCENT      := Color(0.80, 0.60, 0.25)
const C_TEXT        := Color(0.90, 0.85, 0.76)
const C_TEXT_DIM    := Color(0.50, 0.45, 0.38)
const C_LOCKED      := Color(0.22, 0.20, 0.18)
const C_LOCKED_BRD  := Color(0.32, 0.28, 0.22)
const C_UNLOCKED    := Color(0.22, 0.40, 0.22)
const C_UNLOCKED_BRD:= Color(0.35, 0.65, 0.30)
const C_AVAILABLE   := Color(0.30, 0.25, 0.10)
const C_AVAILABLE_BRD := Color(0.80, 0.62, 0.20)
const C_BRANCH_VIT  := Color(0.80, 0.30, 0.30)
const C_BRANCH_WPN  := Color(0.30, 0.55, 0.80)
const C_BRANCH_STA  := Color(0.55, 0.35, 0.80)

var _shard_label: Label

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	WiseTree.tree_changed.connect(_refresh)

func _build() -> void:
	var vp := get_viewport().get_visible_rect().size
	var px := (vp.x - W) * 0.5
	var py := (vp.y - H) * 0.5

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.60)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var panel := _make_panel(Vector2(W, H), C_PANEL, C_BORDER)
	panel.position = Vector2(px, py)
	add_child(panel)

	var stripe := ColorRect.new()
	stripe.color = C_ACCENT
	stripe.size = Vector2(W, 3)
	stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(stripe)

	var title := _lbl("THE WISE TREE", 22, C_ACCENT)
	title.position = Vector2(W * 0.5 - 160, 10)
	title.size = Vector2(320, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)

	_shard_label = _lbl("", 14, C_TEXT_DIM)
	_shard_label.position = Vector2(W - 280, 12)
	_shard_label.size = Vector2(270, 22)
	_shard_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel.add_child(_shard_label)

	var sep := ColorRect.new()
	sep.color = C_BORDER
	sep.position = Vector2(PAD, 44)
	sep.size = Vector2(W - PAD * 2, 1)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(sep)

	var close_lbl := _lbl("[Esc] Close", 12, C_TEXT_DIM)
	close_lbl.position = Vector2(PAD, H - 28)
	close_lbl.size = Vector2(200, 20)
	panel.add_child(close_lbl)

	var body := Control.new()
	body.position = Vector2(PAD, 52)
	body.size = Vector2(W - PAD * 2, H - 52 - 36)
	body.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_child(body)

	var content_w := W - PAD * 2
	var branch_w := content_w / 3.0

	_build_branch(body, WiseTree.get_branch("skills"),    0.0,          branch_w, C_BRANCH_VIT, "SKILLS")
	_build_branch(body, WiseTree.get_branch("weaponry"),  branch_w,     branch_w, C_BRANCH_WPN, "WEAPONRY")
	_build_branch(body, WiseTree.get_branch("stations"),  branch_w * 2, branch_w, C_BRANCH_STA, "STATIONS")

	_refresh()

func _build_branch(parent: Control, nodes: Array, x: float, bw: float, header_color: Color, title: String) -> void:
	var hdr_bar := ColorRect.new()
	hdr_bar.color = Color(header_color.r, header_color.g, header_color.b, 0.25)
	hdr_bar.position = Vector2(x + 4, 0)
	hdr_bar.size = Vector2(bw - 8, 36)
	hdr_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(hdr_bar)

	var hdr_line := ColorRect.new()
	hdr_line.color = header_color
	hdr_line.position = Vector2(x + 4, 33)
	hdr_line.size = Vector2(bw - 8, 3)
	hdr_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(hdr_line)

	var hdr_lbl := _lbl(title, 15, header_color)
	hdr_lbl.position = Vector2(x + 8, 8)
	hdr_lbl.size = Vector2(bw - 16, 24)
	hdr_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(hdr_lbl)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(x + 4, 42)
	scroll.size = Vector2(bw - 8, parent.size.y - 42)
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", NODE_GAP)
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll.add_child(vbox)

	for nd: Dictionary in nodes:
		var btn := _make_node_button(nd)
		btn.name = "Node_" + nd["id"]
		vbox.add_child(btn)

func _make_node_button(nd: Dictionary) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(NODE_W, NODE_H)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.text = ""
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.tooltip_text = nd["desc"]

	var lbl_name := Label.new()
	lbl_name.text = nd["name"]
	lbl_name.add_theme_font_size_override("font_size", 13)
	lbl_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_name.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	lbl_name.position = Vector2(6, 6)
	lbl_name.size = Vector2(NODE_W - 12, 28)
	lbl_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(lbl_name)

	var lbl_desc := Label.new()
	lbl_desc.text = nd["desc"]
	lbl_desc.add_theme_font_size_override("font_size", 11)
	lbl_desc.add_theme_color_override("font_color", C_TEXT_DIM)
	lbl_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_desc.position = Vector2(6, 30)
	lbl_desc.size = Vector2(NODE_W - 12, 18)
	lbl_desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(lbl_desc)

	var lbl_cost := Label.new()
	lbl_cost.text = "%d shards" % nd["cost"]
	lbl_cost.add_theme_font_size_override("font_size", 11)
	lbl_cost.add_theme_color_override("font_color", C_ACCENT)
	lbl_cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl_cost.position = Vector2(6, NODE_H - 20)
	lbl_cost.size = Vector2(NODE_W - 12, 16)
	lbl_cost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(lbl_cost)

	btn.pressed.connect(func(): _on_node_pressed(nd["id"]))
	return btn

func _refresh() -> void:
	_shard_label.text = "Safe Shards: %.0f" % GlobalSafe.shards
	_refresh_branch("skills")
	_refresh_branch("weaponry")
	_refresh_branch("stations")

func _refresh_branch(branch: String) -> void:
	for nd: Dictionary in WiseTree.get_branch(branch):
		var node_id: String = nd["id"]
		var btn := _find_node_button(node_id)
		if btn == null:
			continue
		_style_button(btn, node_id)

func _find_node_button(node_id: String) -> Button:
	var target_name := "Node_" + node_id
	return _search_node(self, target_name)

func _search_node(root: Node, target: String) -> Button:
	for child in root.get_children():
		if child.name == target and child is Button:
			return child
		var found := _search_node(child, target)
		if found != null:
			return found
	return null

func _style_button(btn: Button, node_id: String) -> void:
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(6)

	if WiseTree.is_unlocked(node_id):
		sb.bg_color = C_UNLOCKED
		sb.border_color = C_UNLOCKED_BRD
		sb.set_border_width_all(2)
		btn.disabled = true
		btn.modulate = Color.WHITE
	elif WiseTree.can_unlock(node_id):
		sb.bg_color = C_AVAILABLE
		sb.border_color = C_AVAILABLE_BRD
		sb.set_border_width_all(2)
		btn.disabled = false
		btn.modulate = Color.WHITE
	else:
		sb.bg_color = C_LOCKED
		sb.border_color = C_LOCKED_BRD
		sb.set_border_width_all(1)
		btn.disabled = true
		btn.modulate = Color(0.7, 0.7, 0.7, 0.8)

	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_stylebox_override("disabled", sb)

func _on_node_pressed(node_id: String) -> void:
	WiseTree.unlock(node_id)

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("esc"):
		hide()
		get_viewport().set_input_as_handled()

func _make_panel(sz: Vector2, bg: Color, border: Color) -> Control:
	var c := Control.new()
	c.size = sz
	c.mouse_filter = Control.MOUSE_FILTER_PASS
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(10)
	var p := Panel.new()
	p.size = sz
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(p)
	return c

func _lbl(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
