class_name OPopup
extends Window

# Konfiguration
@export var close_on_click_outside: bool = true

func _ready():
	#transparent_bg = true
	borderless = true
	exclusive = false
	always_on_top = true
	unresizable = true
	close_requested.connect(hide)
	visible = false

func open_popup(pos: Vector2, size := Vector2(200, 150)):
	position = pos
	self.size = size
	show()

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		# Scroll-Event abfangen und konsumieren
		event.accept()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent):
	if close_on_click_outside and event is InputEventMouseButton and event.pressed:
		# MouseWheel nicht behandeln
		var global_mouse := get_mouse_position()
		var rect := Rect2(global_canvas_transform.get_origin(), size)
		if not rect.has_point(global_mouse):
			hide()
