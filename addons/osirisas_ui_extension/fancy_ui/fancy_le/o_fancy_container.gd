@tool
class_name OFancyContainer
extends Container

@export_group("Body Settings")
@export var padding: int = 8:
	set(value):
		padding = value
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
@export var border_radius: int = 4:
	set(value):
		border_radius = value
		queue_redraw()
@export var border_width: int = 1:
	set(value):
		border_width = value
		queue_redraw()

@export_group("Label")
@export var font: Font = SystemFont.new():
	set(value):
		font = value
		queue_redraw()
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

	var label_height = int(font.get_ascent(label_font_size) / 2)
	var label_offset_top = label_height + border_radius + border_width
	var top_padding = label_offset_top + padding
	var inner_size = Vector2(size.x - padding * 2, size.y - top_padding - padding)
	return Rect2(Vector2(padding, top_padding), inner_size)


func _draw() -> void:
	var zero_rect = Rect2i(Vector2i.ZERO, size)
	#var label_height := int(font.get_ascent(label_font_size) / 2)
	var label_height = int(font.get_string_size(label_text.strip_edges(), -1, -1 ,label_font_size).y)
	var label_width := int(font.get_string_size(label_text.strip_edges(), -1, -1 ,label_font_size).x)
	
	draw_rect(zero_rect,background_color if background_color else Color(1,1,1,0), true)
	
	# Top left Arc
	draw_arc(Vector2i(border_radius + border_width, border_radius + label_height / 2), border_radius, PI, 3*PI/2,12, border_color, border_width, false)
	
	# Top left - Label
	if ((border_radius + border_width - 1) - (label_positioning_x - label_spacing + border_width) < 0):
		draw_line(Vector2(border_radius + border_width - 1, label_height / 2), Vector2(label_positioning_x - label_spacing + border_width, label_height / 2), border_color, border_width, false)
	
	# Label
	draw_string(font, Vector2(label_positioning_x + border_width, font.get_ascent(label_font_size)), label_text, -1, -1, label_font_size, label_color)
	
	# Label - Top Right
	if ((border_width + label_positioning_x + label_width + label_spacing) - (size.x - border_radius - border_width + 1) < 0):
		draw_line(Vector2(border_width + label_positioning_x + label_width + label_spacing, label_height / 2), Vector2(size.x - border_radius - border_width + 1, label_height / 2), border_color, border_width, false)
	
	# Top Right Arc
	draw_arc(Vector2i(size.x - border_radius - border_width, border_radius + label_height / 2), border_radius,  0 , - PI/2 , 12, border_color, border_width, false)
	
	# Right | Top - Bottom
	draw_line(Vector2(size.x - border_width, label_height / 2 + border_radius - 1), Vector2(size.x - border_width, size.y - border_radius - border_width + 1), border_color, border_width, false)
	
	# Bottom Right Arc
	draw_arc(Vector2(size.x - border_width - border_radius, size.y - border_radius - border_width), border_radius,  0 , PI/2 , 12, border_color, border_width, false)
	
	# Bottom Right - Bottom Left
	draw_line(Vector2(size.x - border_width - border_radius + 1, size.y - border_width), Vector2(border_radius + border_width - 1, size.y - border_width), border_color, border_width, false)
	
	# Bottom Left Arc
	draw_arc(Vector2(border_radius + border_width, size.y - border_radius - border_width), border_radius,  PI , PI/2 , 12, border_color, border_width, false)
	
	# Left | Bottom - Top
	draw_line(Vector2( border_width, size.y - border_radius - border_width + 1), Vector2(border_width, border_radius + label_height / 2 - 1), border_color, border_width, false)
