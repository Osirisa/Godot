class_name ODragableComponent
extends Control

signal start_dragging()
signal end_dragging(parent: Control)

@export var enable_dragging := true
@export var drag_delay := 1.0
@export var direct_parent: bool = true
@export var parent_to_drag: Control = null

var current_container: ODragContainer = null

var _popup_container := Popup.new()

var _dragging := false
var _drag_delta_start_pos: Vector2
var _drag_timer: Timer

var _original_parents_parent = null
var _original_size := Vector2i()

func _enter_tree():
	mouse_filter = Control.MOUSE_FILTER_PASS
	#set_anchors_preset(Control.PRESET_FULL_RECT, true)

# Called when the node enters the scene tree for the first time.
func _ready():
	if direct_parent:
		parent_to_drag = get_parent()
	
	get_tree().root.add_child.call_deferred(_popup_container)
	_popup_container.popup_hide.connect(_on_popup_hide)
	
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
				_drag_delta_start_pos = DisplayServer.mouse_get_position()
				_drag_timer.start()  # Start the delay timer
			else:
				_drag_timer.stop()  # Stop the timer if it's running
				if _dragging:
					stop_dragging()
		
		elif event is InputEventMouseMotion and _dragging:
			# Only move the parent if we are dragging
			if parent_to_drag:
				#parent.top_level = true # -> BUG FOR NOW
				var global_mouse_pos = DisplayServer.mouse_get_position()
				var drag_delta = global_mouse_pos - Vector2i(_drag_delta_start_pos)
				_popup_container.position += Vector2i(drag_delta)  # Adjust the parent position
				_drag_delta_start_pos = global_mouse_pos  # Update drag start position
				
				accept_event()  # Consume the event
		elif _dragging:
			stop_dragging()

func mouse_on_widget() -> bool:
	return get_global_rect().has_point(get_global_mouse_position())


func _on_drag_timer_timeout() -> void:
	_dragging = true
	start_dragging.emit()
	
	_original_parents_parent = parent_to_drag.get_parent()
	_original_size = parent_to_drag.size
	
	var screen_pos = parent_to_drag.get_screen_position()
	
	parent_to_drag.get_parent().remove_child(parent_to_drag)
	parent_to_drag.position = Vector2i.ZERO
	
	_popup_container.add_child(parent_to_drag)
	
	_popup_container.popup(Rect2i(screen_pos, _original_size))
	parent_to_drag.size = _original_size

func _on_popup_hide()-> void:
	stop_dragging()

func stop_dragging() -> void:
	if not _original_parents_parent:
			return
	
	_dragging = false
	
	var pos = _popup_container.position + Vector2i(position)
	var found_container: ODragContainer = _find_closest_drag_container(pos)
	
	var container_to_add: ODragContainer = null
	
	_popup_container.remove_child(parent_to_drag)
	
	if found_container:
		container_to_add = found_container
		
		if current_container != found_container:
			container_to_add = found_container
			current_container.remove_dragable(parent_to_drag)
			print(found_container.calc_arr_pos_global(pos))
			print(pos)
			found_container.add_dragable_item(parent_to_drag, found_container.calc_arr_pos_global(pos))
			
		else:
			container_to_add._body.add_child(parent_to_drag)
			parent_to_drag.global_position = _popup_container.position
			end_dragging.emit(parent_to_drag)
	
	else:
		container_to_add = current_container
		container_to_add._body.add_child(parent_to_drag)
		parent_to_drag.global_position = _popup_container.position
		end_dragging.emit(parent_to_drag)
	
	
	parent_to_drag.size = _original_size
	
	_popup_container.set_block_signals(true)
	_popup_container.hide()
	_popup_container.set_block_signals(false)




func _find_closest_drag_container(pos: Vector2) -> ODragContainer:
	var min_dist = INF
	var target_container: ODragContainer = null
	
	for container in ODragContainer.all_drag_containers:
		if not container.visible:
			continue
		var rect = container.get_global_rect()
		
		#check if this container has the position
		if rect.has_point(pos):
			#check for the distance (if some container overlap, find the best one)
			var dist = rect.get_center().distance_to(pos)
			if dist < min_dist:
				min_dist = dist
				target_container = container
	return target_container
