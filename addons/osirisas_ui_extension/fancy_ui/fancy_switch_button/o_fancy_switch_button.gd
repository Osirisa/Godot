class_name OFancySwitchButton
extends Control

@export var is_on := false:
	set(value):
		if is_on == value:
			return
		is_on = value
		animate_handle()

@export var animation_duration := 0.25

var handle_position := 0.0:
	set(value):
		handle_position = value
		queue_redraw()
	
var tween: Tween

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)
	set_handle_position()

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		is_on = !is_on

func animate_handle():
	if tween:
		tween.kill()
	tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	var position_switched: float = 1.0 if is_on else 0.0
	tween.tween_property(self, "handle_position", position_switched, animation_duration)

func set_handle_position():
	handle_position = 1.0 if is_on else 0.0

func _draw():
	var bg_color := Color(0.2, 0.7, 0.3) if is_on else Color(0.5, 0.5, 0.5)
	var handle_color := Color(1, 1, 1, 0.8)
	var radius: float = min(size.y, size.x * 0.5) * 0.5

	# Background
	draw_style_box(get_theme_stylebox("panel"), Rect2(Vector2.ZERO, size))

	draw_rect(Rect2(Vector2.ZERO, size), bg_color, true)

	# Handle
	var handle_radius := radius * 0.9
	var margin := radius * 0.1
	var handle_x := lerp(radius + margin, size.x - radius - margin, handle_position)
	var handle_center := Vector2(handle_x, size.y / 2)

	draw_circle(handle_center, handle_radius, handle_color)
