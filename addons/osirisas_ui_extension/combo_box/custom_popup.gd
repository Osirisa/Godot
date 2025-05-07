class_name OPopup
extends Window

signal about_to_hide()
signal focused()

# Konfiguration
@export var hide_on_unfocus: bool = true
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
	#if event is InputEventMouseMotion and event.relative.x + event.relative.y > 0:
		#print("focus")
		#grab_focus()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and not hide_on_unfocus:
		print("disabled")
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and hide_on_unfocus:
		print("hide")
		hide()
	if what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		focused.emit()
