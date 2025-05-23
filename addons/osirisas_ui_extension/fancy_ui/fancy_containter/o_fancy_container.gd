@tool
class_name OFancyContainer
extends Container

enum LabelPosition {
	TOP_LEFT,
	TOP_CENTER,
	TOP_RIGHT,
	BOTTOM_LEFT,
	BOTTOM_CENTER,
	BOTTOM_RIGHT
}


@export_group("Body Settings")
@export var padding_top: int = 4:
	set(value):
		padding_top = value
		queue_redraw()
@export var padding_bottom: int = 4:
	set(value):
		padding_bottom = value
		queue_redraw()
@export var padding_right: int = 4:
	set(value):
		padding_right = value
		queue_redraw()
@export var padding_left: int = 4:
	set(value):
		padding_left = value
		queue_redraw()

@export var background_color: Color = Color(1,1,1,0):
	set(value):
		background_color = value
		queue_redraw()

@export_group("Border")
@export var border_color: Color = Color.DARK_GRAY:
	set(value):
		border_color = value
		queue_redraw()
@export var border_radius_top_left: int = 4:
	set(value):
		border_radius_top_left = value
		queue_redraw()

@export var border_radius_top_right: int = 4:
	set(value):
		border_radius_top_right = value
		queue_redraw()

@export var border_radius_bottom_right: int = 4:
	set(value):
		border_radius_bottom_right = value
		queue_redraw()

@export var border_radius_bottom_left: int = 4:
	set(value):
		border_radius_bottom_left = value
		queue_redraw()

@export var border_width: float = 1.0:
	set(value):
		border_width = value
		queue_redraw()

@export var draw_top: bool = true:
	set(value):
		draw_top = value
		queue_redraw()
@export var draw_bottom: bool = true:
	set(value):
		draw_bottom = value
		queue_redraw()
@export var draw_right: bool = true:
	set(value):
		draw_right = value
		queue_redraw()
@export var draw_left: bool = true:
	set(value):
		draw_left = value
		queue_redraw()

@export var mitred_top_left: bool = false:
	set(value):
		mitred_top_left = value
		queue_redraw()

@export var mitred_top_right: bool = false:
	set(value):
		mitred_top_right = value
		queue_redraw()

@export var mitred_bottom_right: bool = false:
	set(value):
		mitred_bottom_right = value
		queue_redraw()

@export var mitred_bottom_left: bool = false:
	set(value):
		mitred_bottom_left = value
		queue_redraw()


@export_group("Label")
@export var font: Font = SystemFont.new():
	set(value):
		font = value
		queue_redraw()

@export var label_position: LabelPosition = LabelPosition.TOP_LEFT:
	set(value):
		label_position = value
		queue_redraw()
		queue_sort()

@export var label_text: String = "label":
	set(value):
		label_text = value
		queue_redraw()
@export var label_font_size: int = 10:
	set(value):
		label_font_size = value
		queue_redraw()
@export var label_spacing: int = 2:
	set(value):
		label_spacing = value
		queue_redraw()
@export var label_positioning_x: int = 12:
	set(value):
		label_positioning_x = value
		queue_redraw()
@export var label_color: Color = Color.DARK_GRAY:
	set(value):
		label_color = value
		queue_redraw()




func _ready() -> void:
	queue_sort()
	#property_list_changed.connect(func(): queue_redraw())

func _process(delta: float) -> void:
	pass

func _notification(what):
	if what == NOTIFICATION_SORT_CHILDREN:
		_sort_children()
	elif what == NOTIFICATION_RESIZED:
		queue_redraw()
		queue_sort()

func _sort_children():
	if not font:
		return

	var usable_rect := get_usable_rect()

	for child in get_children():
		if not child is Control or child.is_set_as_top_level():
			continue
		child.position = usable_rect.position
		child.size = usable_rect.size

func get_usable_rect() -> Rect2:
	if not font:
		return Rect2(Vector2.ZERO, size)

	var label_height := int(font.get_height(label_font_size))
	var max_top_radius := max(border_radius_top_left, border_radius_top_right)
	var max_bottom_radius := max(border_radius_bottom_left, border_radius_bottom_right)

	var label_space_top := 0
	var label_space_bottom := 0

	match label_position:
		LabelPosition.TOP_LEFT, LabelPosition.TOP_CENTER, LabelPosition.TOP_RIGHT:
			label_space_top = label_height / 2 + max_top_radius + border_width
		LabelPosition.BOTTOM_LEFT, LabelPosition.BOTTOM_CENTER, LabelPosition.BOTTOM_RIGHT:
			label_space_bottom = label_height / 2 + max_bottom_radius + border_width

	var inner_pos := Vector2(padding_left, padding_top + label_space_top)
	var inner_size := Vector2(
		size.x - (padding_left + padding_right),
		size.y - (padding_top + padding_bottom + label_space_top + label_space_bottom)
	)

	return Rect2(inner_pos, inner_size)


func _draw() -> void:
	if not font:
		return

	var rect = Rect2(Vector2.ZERO, size)
	var label_size = font.get_string_size(label_text.strip_edges(), -1, -1, label_font_size)
	var label_width = int(label_size.x)
	var label_height = int(label_size.y)
	var label_center_y = int(label_height / 2)
	var label_baseline_y = font.get_ascent(label_font_size)
	
	var top_y: int
	var bottom_y: int
	var pos_label: bool
	
	match label_position:
		LabelPosition.TOP_LEFT,LabelPosition.TOP_CENTER, LabelPosition.TOP_RIGHT:
			top_y = label_center_y
			bottom_y = size.y - border_width
			pos_label = true
		LabelPosition.BOTTOM_LEFT, LabelPosition.BOTTOM_CENTER, LabelPosition.BOTTOM_RIGHT:
			top_y = border_width
			bottom_y = size.y - label_center_y
			pos_label = false
	
	# Hintergrund
	draw_rect(rect, background_color, true)

# --- Top Left Arc / Mitred ---
	#var corner_top_left = Vector2(border_width, border_width + label_center_y)
	var corner_top_left = Vector2(border_width, top_y)
	if border_radius_top_left > 0:
		if mitred_top_left:
			draw_corner_beveled(corner_top_left, Vector2(1, 0), Vector2(0, 1), border_radius_top_left)
		else:
			draw_arc(corner_top_left + Vector2(border_radius_top_left, border_radius_top_left), border_radius_top_left, PI, 3 * PI / 2, 24, border_color, border_width, true)
	
	
	# --- Label ---
	var label_pos := Vector2()
	match label_position:
		LabelPosition.TOP_LEFT:
			label_pos = Vector2(label_positioning_x + border_width, label_baseline_y)
		LabelPosition.TOP_CENTER:
			label_pos = Vector2(size.x / 2 - label_width / 2, label_baseline_y)
		LabelPosition.TOP_RIGHT:
			label_pos = Vector2(size.x - label_width - label_positioning_x - border_width, label_baseline_y)
		LabelPosition.BOTTOM_LEFT:
			label_pos = Vector2(label_positioning_x + border_width, size.y - border_width - label_height + label_baseline_y)
		LabelPosition.BOTTOM_CENTER:
			label_pos = Vector2(size.x / 2 - label_width / 2, size.y - border_width - label_height + label_baseline_y)
		LabelPosition.BOTTOM_RIGHT:
			label_pos = Vector2(size.x - label_width - label_positioning_x - border_width, size.y - border_width - label_height + label_baseline_y)
	
	draw_string(font, label_pos, label_text, -1, -1, label_font_size, label_color)
	
	
	
	# --- Top Lines (split left and right of label) ---

	if draw_top:
		
		var left_x = get_arc_offset(border_radius_top_left) + border_width
		var right_x = size.x - get_arc_offset(border_radius_top_right) - border_width
		
		var label_left = label_pos.x - label_spacing
		var label_right = label_pos.x + label_width + label_spacing
		
		if not pos_label:
			draw_line(Vector2(left_x, top_y), Vector2(right_x, top_y), border_color, border_width, true)
		else:
			if label_left > left_x:
				draw_line(Vector2(left_x, top_y), Vector2(label_left, top_y), border_color, border_width, true)
			
			if right_x > label_right:
				draw_line(Vector2(label_right, top_y), Vector2(right_x, top_y), border_color, border_width, true)


	# --- Top Right Arc / Mitred ---
	var corner_top_right = Vector2(size.x - border_width, top_y)
	#var corner_top_right = Vector2(size.x - border_width, border_width + label_center_y)
	if border_radius_top_right > 0:
		if mitred_top_right:
			draw_corner_beveled(corner_top_right, Vector2(-1, 0), Vector2(0, 1), border_radius_top_right)
		else:
			draw_arc(corner_top_right + Vector2(-border_radius_top_right, border_radius_top_right), border_radius_top_right, 0, -PI / 2, 12, border_color, border_width, true)


	# --- Right Line ---
	if draw_right:
		var top_offset = get_arc_offset(border_radius_top_right)
		var bottom_offset = get_arc_offset(border_radius_bottom_right)
		draw_line(
			Vector2(size.x - border_width, top_offset + top_y),
			Vector2(size.x - border_width, bottom_y - bottom_offset),
			border_color, border_width, true
		)


	# --- Bottom Right Arc / Mitred ---
	var corner_bottom_right = Vector2(size.x - border_width, bottom_y)
	if border_radius_bottom_right > 0:
		if mitred_bottom_right:
			draw_corner_beveled(corner_bottom_right, Vector2(-1, 0), Vector2(0, -1), border_radius_bottom_right)
		else:
			draw_arc(corner_bottom_right + Vector2(-border_radius_bottom_right, -border_radius_bottom_right), border_radius_bottom_right, 0, PI / 2, 12, border_color, border_width, true)

	# --- Bottom Line ---
	if draw_bottom:
		
		var left_x = get_arc_offset(border_radius_bottom_left) + border_width
		var right_x = size.x - get_arc_offset(border_radius_bottom_right) - border_width
		
		var label_bottom_y = size.y - int(font.get_height(label_font_size) / 2)
		var label_left = label_pos.x - label_spacing
		var label_right = label_pos.x + label_width + label_spacing
		if pos_label:
			draw_line(Vector2(right_x, bottom_y), Vector2(left_x, bottom_y), border_color, border_width, true)
		else:
			if label_left > left_x:
				draw_line(Vector2(label_left, bottom_y), Vector2(left_x, bottom_y), border_color, border_width, true)
			
			if right_x > label_right:
				draw_line(Vector2(right_x, bottom_y), Vector2(label_right, bottom_y), border_color, border_width, true)
	
	
	# --- Bottom Left Arc / Mitred ---
	var corner_bottom_left = Vector2(border_width, bottom_y)
	if border_radius_bottom_left > 0:
		if mitred_bottom_left:
			draw_corner_beveled(corner_bottom_left, Vector2(1, 0), Vector2(0, -1), border_radius_bottom_left)
		else:
			draw_arc(corner_bottom_left + Vector2(border_radius_bottom_left, -border_radius_bottom_left), border_radius_bottom_left, PI, PI / 2, 12, border_color, border_width, true)

	# --- Left Line ---
	if draw_left:
		var top_offset = get_arc_offset(border_radius_top_left)
		var bottom_offset = get_arc_offset(border_radius_bottom_left)
		draw_line(
			Vector2(border_width, top_y + top_offset),
			Vector2(border_width, bottom_y - bottom_offset),
			border_color, border_width, true
		)


func draw_corner_beveled(pos: Vector2, dir1: Vector2, dir2: Vector2, length: float) -> void:
	var p1 = pos + dir1.normalized() * length
	var p2 = pos + dir2.normalized() * length
	draw_line(p1, p2, border_color, border_width, true)



func get_arc_offset(radius: int) -> int:
	return radius if radius > 0 else 0
