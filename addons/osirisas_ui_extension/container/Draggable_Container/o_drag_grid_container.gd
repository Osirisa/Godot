@tool
class_name ODragContainer
extends Container

## A Container where you can place Nodes which have a draggables Container as a parent into 
## the Container and drag them on a grid
## The grid divides the space into equal amount of spaces (2x2, 3x1) and so on

signal item_dropped(item: Control, new_pos: Vector2i, old_pos: Vector2i)
signal item_inserted(item: Control, pos: Vector2i)
signal item_extruded(item: Control, old_pos: Vector2i)

signal container_full(container: ODragContainer)

enum E_StartingPoint {
	TOP_LEFT,
	TOP_RIGHT,
	BOTTOM_LEFT,
	BOTTOM_RIGHT,
}

enum E_FillDirection {
	HORIZONTAL,
	VERTICAL,
}

static var all_drag_containers: Array[ODragContainer] = []

@export_category("Drag Container")
@export_category("Items")

@export var init_items: Array[PackedScene]:
	set(value):
		var max_items: int = grid.x * grid.y

		if (value.size() >= max_items) and (is_node_ready() or (Engine.is_editor_hint() and _var_grid_ready)) :

			init_items = value.slice(0, max_items)
		else:
			init_items = value
		
		if Engine.is_editor_hint() and self.is_node_ready():
			_initialize_items.call_deferred()

@export_group("Grid")
## The Grid, on which you can position your nodes on
@export var grid := Vector2i(1,1):
	set(value):
		_var_grid_ready = true
		
		var x = maxi(value.x, 1)
		var y = maxi(value.y, 1)
		
		grid = Vector2i(x, y)
		if _items.size() > 0:
			_items = _items
		init_items = init_items

## The spaces around the positions
@export var grid_separation := Vector2(0,0)

@export var min_grid_pos_size := Vector2(100,100)
@export var max_grid_pos_size := Vector2(100,100)

@export var min_items_size := Vector2(100, 100)
@export var max_items_size := Vector2(100, 100)

@export var magnet_reorder := true

@export var starting_point := E_StartingPoint.TOP_LEFT
@export var fill_direction := E_FillDirection.HORIZONTAL:
	set(value):
		fill_direction = value
		if self.is_node_ready():
			_position_items.call_deferred()


@export_group("Animation")
## For smooth translations on the other nodes when a sort happens 
@export var interpolation_speed := 5.0

@export_group("Scrolling")
## When holding a draggable and mouse position is near the side of the screen / parents boundaries
@export var auto_scroll_speed := 200.0
## the margin from where the scrolling starts
@export var auto_scroll_margin := 50.0
## The speed for the slow speed point (goes slow until that point)
@export var auto_scroll_slow_speed := 100.0
## For a smoother experience, a slow speed point for the margin (set to 0 if deactivate)
@export var auto_scroll_slow_point := 25.0:
	set(value):
		auto_scroll_slow_point = min(value, auto_scroll_margin)
		if auto_scroll_slow_point < 0:
			auto_scroll_slow_point = 0

var dragging := false
var drag_offset: Vector2

var full := false

var _items: Array[Control] = []:
	set(value):
		var max_items: int = grid.x * grid.y
		if value.size() > max_items:
			printerr("Container is full")
			_items = value.slice(0,max_items)
		else:
			_items = value

var _cell_positions: Array[Array]
var _cell_dimensions: Vector2
var _scroll_container := ScrollContainer.new()
var _body := Control.new()

var _var_grid_ready := false

var _first_time := true

var _tween: Tween

# Called when the node enters the scene tree for the first time.
func _ready():
	all_drag_containers.append(self)
	
	resized.connect(_on_resized)
	
	_body.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	_scroll_container.add_child(_body)
	_scroll_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll_container.clip_contents = true
	
	add_child(_scroll_container)
	
	_initialize_cell_positions_array()
	_calc_grid_positions()
	
	_items.resize(grid.x * grid.y)
	
	_initialize_items.call_deferred()

func _exit_tree():
	# Unregister this container from the static array when it is removed from the scene
	all_drag_containers.erase(self)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


## Adds a new Item(Widget) to the DragContainer
## If the set position is occupied, the other Item will be send to the back
func add_dragable_item(new_item: Control, arr_position = -1) -> void:
	_add_dragable(new_item, arr_position)


## Adds a new Scene(Widget) to the DragContainer
## If the set position is occupied, the other Item will be send to the back
func add_dragable_scene(dragable_scene: PackedScene, arr_position: int = -1) -> void:
	var new_item: Control = dragable_scene.instantiate()
	
	_body.add_child(new_item)
	new_item.set_deferred("size", _cell_dimensions)
	
	_add_dragable(new_item, arr_position)


func _add_dragable(new_item: Control, arr_position: int = -1) -> void:
	if full:
		printerr("Container: " + self.name + " is full")
		return
	
	new_item.size = _cell_dimensions
	if new_item.get_parent():
		new_item.get_parent().remove_child(new_item)
	
	_body.add_child(new_item)

	var comp := _get_dragable_comp(new_item)
	if comp != null and not Engine.is_editor_hint():
		comp.current_container = self
		comp.end_dragging.connect(_on_item_dropped)

	if arr_position < 0:
		for i in range(_items.size()):
			if _items[i] == null:
				_items[i] = new_item
				break
	else:
		var old_index = _items.find(new_item)
		if old_index < 0:
			old_index = _items.size() - 1

		var new_index = arr_position

		if _items[new_index]:
			_items[old_index] = _items[new_index]
		else:
			_items[old_index] = null
		_items[new_index] = new_item

	if magnet_reorder:
		_magnet_reorder_items()
	
	#var coord = _get_coord_of_index(arr_position)
	#new_item.position = _cell_positions[coord.x][coord.y]
	_position_items.call_deferred()


func remove_dragable(item: Control) -> void:
	var index := _items.find(item)
	if index != -1:
		_remove_dragable_at(index)

func remove_dragable_at(index: int) -> void:
	if index >= 0 and index < _items.size():
		_remove_dragable_at(index)


func _remove_dragable_at(index: int) -> void:
	var item := _items[index]
	if item:
		if item.is_inside_tree() and _body.has_node(item.get_path()):
			_body.remove_child(item)
		
		var comp = _get_dragable_comp(item)
		if comp:
			comp.end_dragging.disconnect(_on_item_dropped)

		#item.queue_free()
		_items[index] = null
	
	if magnet_reorder:
		
		_magnet_reorder_items()

	_position_items.call_deferred()


func _initialize_items() -> void:
	for item in _items:
		if item:
			_body.remove_child(item)
	
	_items.clear()
	_items.resize(grid.x * grid.y) 
	
	for scene in init_items:
		if scene:
			add_dragable_scene(scene)
	_position_items.call_deferred()

#func _initialize_items() -> void:
	#var controls: Array[Control]
	#for scene in init_items:
		#if scene:
			#controls.append(scene.instantiate())
	#
	#var idx = 0
	#for item: Control in controls:
		#idx += 1
		#var comp = _get_dragable_comp(item)
		#if comp != null:
			#comp.end_dragging.connect(_on_item_dropped)
				#
		#_items[idx - 1] = item
		#_body.add_child(item)

func _get_dragable_comp(item: Control) -> ODragableComponent:
	for child in item.get_children():
			if child is ODragableComponent:
				return child as ODragableComponent
	return null

func _initialize_cell_positions_array() -> void:
	_cell_positions.resize(grid.x)
	for i in range(grid.x):
		for j in range(grid.y):
			_cell_positions[i].append(Vector2(0,0))

func _restart_tween() -> void:
	if _tween:
		_tween.stop()
		_tween.kill()
	if not _tween or not _tween.is_valid():
		_tween = create_tween()
		_tween.set_parallel(true)
		_tween.bind_node(self)

func _position_items() -> void:
	_restart_tween()
	
	for item_idx in range(grid.x * grid.y):
		var coord: Vector2i = _get_coord_of_index(item_idx)
		
		# Position items if they exist
		if _items[item_idx] and _items[item_idx] != null:
			var target_position = _cell_positions[coord.x][coord.y]
			var item: Control = _items[item_idx]
			
			if !_first_time and not Engine.is_editor_hint():
				if _tween != null and item.position != target_position:
				# Tween to the new position using the single Tween instance
					_tween.tween_property(
						item, 
						"position", 
						target_position, 
						0.25,  # Duration
					).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

			else:
				item.position = _cell_positions[coord.x][coord.y]
		else:
			# Dummy Tween to "Satisfy" compiler
			_tween.tween_interval(0.001)
	
	_first_time = false


func _get_coord_of_index(index: int) -> Vector2i:
	var x: int = 0
	var y: int = 0
	
	match starting_point:
		E_StartingPoint.TOP_LEFT:
			if fill_direction == E_FillDirection.HORIZONTAL:
				x = index % grid.x
				y = index / grid.x
			else:  # VERTICAL
				x = index / grid.y
				y = index % grid.y
		
		E_StartingPoint.TOP_RIGHT:
			if fill_direction == E_FillDirection.HORIZONTAL:
				x = grid.x - 1 - (index % grid.x)
				y = index / grid.x
			else:  # VERTICAL
				x = grid.x - 1 - (index / grid.y)
				y = index % grid.y
		
		E_StartingPoint.BOTTOM_LEFT:
			if fill_direction == E_FillDirection.HORIZONTAL:
				x = index % grid.x
				y = grid.y - 1 - (index / grid.x)
			else:  # VERTICAL
				x = index / grid.y
				y = grid.y - 1 - (index % grid.y)
		
		E_StartingPoint.BOTTOM_RIGHT:
			if fill_direction == E_FillDirection.HORIZONTAL:
				x = grid.x - 1 - (index % grid.x)
				y = grid.y - 1 - (index / grid.x)
			else:  # VERTICAL
				x = grid.x - 1 - (index / grid.y)
				y = grid.y - 1 - (index % grid.y)
	
	return Vector2i(x, y)

func _calc_grid_positions() -> void:
	_cell_dimensions.x = (size.x - (grid.x - 1) * grid_separation.x) / grid.x
	_cell_dimensions.y = (size.y - (grid.y - 1) * grid_separation.y) / grid.y
	
	if max_items_size.x > 0:
		_cell_dimensions.x = min(_cell_dimensions.x, max_items_size.x)
	_cell_dimensions.x = max(_cell_dimensions.x, min_items_size.x)
	
	if max_items_size.y > 0:
		_cell_dimensions.y = min(_cell_dimensions.y, max_items_size.y)
	_cell_dimensions.y = max(_cell_dimensions.y, min_items_size.y)
	
	
	for col in range(grid.x):
		for row in range(grid.y):
			
			var min_x: = col * (min_grid_pos_size.x + grid_separation.x)
			var min_y: = row * (min_grid_pos_size.y + grid_separation.y)
			
			var max_x
			var max_y
			
			if max_grid_pos_size.x > 0:
				max_x = col * (max_grid_pos_size.x + grid_separation.x)
			else:
				max_x = INF
			
			if max_grid_pos_size.y > 0:
				max_y = row * (max_grid_pos_size.y + grid_separation.y)
			else:
				max_y = INF
			
			var normal_x = col * (_cell_dimensions.x + grid_separation.x)
			var normal_y = row * (_cell_dimensions.y + grid_separation.y)
			
			var x_pos: float = clampf(normal_x, min_x, max_x)
			var y_pos: float = clampf(normal_y, min_y, max_y)
			
			#print("Position for cell [", col, "][", row, "]: x =", x_pos, " y =", y_pos)
			_cell_positions[col][row] = Vector2(x_pos, y_pos)
	
	_body.custom_minimum_size.x = int(_cell_positions[grid.x-1][grid.y-1].x + _cell_dimensions.x)
	_body.custom_minimum_size.y = int(_cell_positions[grid.x-1][grid.y-1].y + _cell_dimensions.y)

func _adj_items_size() -> void:
	for item in _items:
		if item:
			item.set_deferred("size", _cell_dimensions)

func calc_arr_pos(pos: Vector2i) -> int:
	var x = int((pos.x + _cell_dimensions.x/2) / (_cell_dimensions.x + grid_separation.x))
	var y = int((pos.y + _cell_dimensions.y/2) / (_cell_dimensions.y + grid_separation.y))
	
	var item_idx
	match fill_direction:
		E_FillDirection.VERTICAL:
			item_idx = x * grid.y + y
		_:
			item_idx = y * grid.x + x
	
	item_idx = clamp(item_idx, 0, (grid.x * grid.y) - 1)
	
	return item_idx

func calc_arr_pos_global(global_pos: Vector2i) -> int:
	var pos = global_pos - Vector2i(get_global_position())
	
	var x = int((pos.x + _cell_dimensions.x/2) / (_cell_dimensions.x + grid_separation.x))
	var y = int((pos.y + _cell_dimensions.y/2) / (_cell_dimensions.y + grid_separation.y))
	
	var item_idx
	match fill_direction:
		E_FillDirection.VERTICAL:
			item_idx = x * grid.y + y
		_:
			item_idx = y * grid.x + x
	
	item_idx = clamp(item_idx, 0, (grid.x * grid.y) - 1)
	
	return item_idx

func _insert_item(item) -> void:
	var old_index = _items.find(item)
	
	var new_pos: Vector2 = item.position
	var new_index = calc_arr_pos(new_pos)
	
	var item_on_pos: Control = null
	
	if _items[new_index]:
		_items[old_index] = _items[new_index]
	else:
		_items[old_index] = null
	_items[new_index] = item

func _magnet_reorder_items() ->void:
	for idx in range(_items.size()-1, -1, -1):
		if !_items[idx]:
			_items.remove_at(idx)
			_items.append(null)

func _on_resized() -> void:
	_calc_grid_positions()
	_adj_items_size.call_deferred()
	_position_items.call_deferred()

func _on_item_dropped(item) -> void:
	_insert_item(item)
	
	if magnet_reorder:
		_magnet_reorder_items()
	
	_position_items()
