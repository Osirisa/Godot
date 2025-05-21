class_name OPulseAnimButton
extends Button

var ripple_pos := Vector2.ZERO
var ripple_radius := 0.0
var ripple_active := false
var ripple_max := 200.0
var ripple_tween: Tween

func _ready():
	#set_process(true)
	connect("pressed", Callable(self, "_on_pressed"))
	clip_contents = true

func _on_pressed():
	ripple_pos = get_local_mouse_position()
	ripple_radius = 0.0
	ripple_active = true
	
	if ripple_tween:
		ripple_tween.kill()
	ripple_tween = create_tween()
	ripple_tween.tween_property(self, "ripple_radius", ripple_max, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	ripple_tween.tween_callback(Callable(self, "_reset_ripple"))

func _process(delta):
	if ripple_active:
		queue_redraw()

func _reset_ripple():
	ripple_active = false
	queue_redraw()

func _draw():
	if ripple_active:
		var alpha := clamp(1.0 - (ripple_radius / ripple_max), 0.0, 1.0)
		draw_circle(ripple_pos, ripple_radius, Color(1, 1, 1, 0.2 * alpha))
