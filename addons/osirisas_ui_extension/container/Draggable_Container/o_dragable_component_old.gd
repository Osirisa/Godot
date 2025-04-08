class_name ODragableComponent_OLD
extends Control
##@deprecated: Use "ODragableComponent" instead.

signal start_dragging()
signal end_dragging(parent: Control)

@export var enable_dragging := true
@export var drag_delay := 1.0
@export var direct_parent: bool = true
@export var parent_to_drag: Control = null

var _dragging := false
var _drag_delta_start_pos: Vector2
var _drag_timer: Timer

func _enter_tree():
	mouse_filter = Control.MOUSE_FILTER_PASS
	#set_anchors_preset(Control.PRESET_FULL_RECT, true)

# Called when the node enters the scene tree for the first time.
func _ready():
	if direct_parent:
		parent_to_drag = get_parent()
	
	_drag_timer = Timer.new()
	_drag_timer.one_shot = true  # Only trigger once
	_drag_timer.wait_time = drag_delay  # Set the delay time
	_drag_timer.timeout.connect(_on_drag_timer_timeout)
	
	add_child(_drag_timer)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _input(event):
	if enable_dragging:
		if event is InputEventMouseButton and mouse_on_widget() and event.button_index == MOUSE_BUTTON_LEFT:
			#print(event)
			if event.pressed:
				_drag_delta_start_pos = get_global_mouse_position()
				_drag_timer.start()  # Start the delay timer
			else:
				_drag_timer.stop()  # Stop the timer if it's running
				if _dragging:
					#get_parent().top_level = false # -> BUG FOR NOW
					_dragging = false
					end_dragging.emit(parent_to_drag)
		
		elif event is InputEventMouseMotion and _dragging:
			# Only move the parent if we are dragging
			if parent_to_drag:
				#parent.top_level = true # -> BUG FOR NOW
				var global_mouse_pos = get_global_mouse_position()
				var drag_delta = global_mouse_pos - _drag_delta_start_pos
				parent_to_drag.position += drag_delta  # Adjust the parent position
				_drag_delta_start_pos = global_mouse_pos  # Update drag start position
				
				accept_event()  # Consume the event
		elif _dragging:
				_dragging = false
				end_dragging.emit(parent_to_drag)

func mouse_on_widget() -> bool:
	return get_global_rect().has_point(get_global_mouse_position())


func _on_drag_timer_timeout():
	_dragging = true
	start_dragging.emit()
