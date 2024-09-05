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
		if value.size() >= max_items and (_var_ready or Engine.is_editor_hint()) :
			init_items = value.slice(0, max_items)
			pass
		else:
			init_items = value


@export_group("Grid")
## The Grid, on which you can position your nodes on
@export var grid := Vector2i(1,1):
	set(value):
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
		if _var_ready:
			_position_items()


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
			_items = _items

var _cell_positions: Array[Array]
var _cell_dimensions: Vector2
var _scroll_container := ScrollContainer.new()
var _body := Control.new()
var _var_ready := false

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
	
	add_child(_scroll_container)
	
	_initialize_cell_positions_array()
	_calc_grid_positions()
	
	_items.resize(grid.x * grid.y)
	_initialize_items()
	
	_adj_items_size.call_deferred()
	_position_items()
	
	_var_ready = true

func _exit_tree():
	# Unregister this container from the static array when it is removed from the scene
	all_drag_containers.erase(self)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _initialize_items() -> void:
	var controls: Array[Control]
	for scene in init_items:
		controls.append(scene.instantiate())
	
	var idx = 0
	for item: Control in controls:
		idx += 1
		for child in item.get_children():
			if child is ODragableComponent:
				child = child as ODragableComponent
				child.end_dragging.connect(_on_item_dropped)
				
				_items[idx - 1] = item
				_body.add_child(item)

func _initialize_cell_positions_array() -> void:
	_cell_positions.resize(grid.x)
	for i in range(grid.x):
		for j in range(grid.y):
			_cell_positions[i].append(Vector2(0,0))

func _restart_tween() -> void:
	if _tween and _tween.is_running():
		_tween.stop()
		_tween.kill()
	if not _tween or not _tween.is_valid():
		_tween = create_tween()
		_tween.set_parallel(true)

func _position_items() -> void:
	var x: int
	var y: int
	
	_restart_tween()
	
	for item_idx in range(grid.x * grid.y):
		match starting_point:
			E_StartingPoint.TOP_LEFT:
				if fill_direction == E_FillDirection.HORIZONTAL:
					x = item_idx % grid.x
					y = item_idx / grid.x
				else:  # VERTICAL
					x = item_idx / grid.y
					y = item_idx % grid.y
			
			E_StartingPoint.TOP_RIGHT:
				if fill_direction == E_FillDirection.HORIZONTAL:
					x = grid.x - 1 - (item_idx % grid.x)
					y = item_idx / grid.x
				else:  # VERTICAL
					x = grid.x - 1 - (item_idx / grid.y)
					y = item_idx % grid.y
			
			E_StartingPoint.BOTTOM_LEFT:
				if fill_direction == E_FillDirection.HORIZONTAL:
					x = item_idx % grid.x
					y = grid.y - 1 - (item_idx / grid.x)
				else:  # VERTICAL
					x = item_idx / grid.y
					y = grid.y - 1 - (item_idx % grid.y)
			
			E_StartingPoint.BOTTOM_RIGHT:
				if fill_direction == E_FillDirection.HORIZONTAL:
					x = grid.x - 1 - (item_idx % grid.x)
					y = grid.y - 1 - (item_idx / grid.x)
				else:  # VERTICAL
					x = grid.x - 1 - (item_idx / grid.y)
					y = grid.y - 1 - (item_idx % grid.y)
		
		# Position items if they exist
		if _items[item_idx]:
			var target_position = _cell_positions[x][y]
			var item: Control = _items[item_idx]
			
			if _tween:
			# Tween to the new position using the single Tween instance
				_tween.tween_property(
					item, 
					"position", 
					target_position, 
					0.25,  # Duration
				).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

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
			item.size = _cell_dimensions

func _calc_arr_pos(pos: Vector2i) -> int:
	var x = int((pos.x + _cell_dimensions.x/2) / (_cell_dimensions.x + grid_separation.x))
	var y = int((pos.y + _cell_dimensions.y/2) / (_cell_dimensions.y + grid_separation.y))
	
	var item_idx
	match fill_direction:
		E_FillDirection.VERTICAL:
			item_idx = x * grid.y + y
		_:
			item_idx = y * grid.x + x
	
	item_idx = clamp(item_idx, 0, (grid.x * grid.y) - 1)
	print(item_idx)
	return item_idx

func _magnet_reorder_items() ->void:
	for idx in range(_items.size()):
		if !_items[idx]:
			_items.remove_at(idx)
			_items.append(null)

func _on_resized() -> void:
	_calc_grid_positions()
	_adj_items_size.call_deferred()
	_position_items.call_deferred()

func _on_item_dropped(item) -> void:
	var old_index = _items.find(item)
	
	var new_pos: Vector2 = item.position
	var new_index = _calc_arr_pos(new_pos)
	
	var item_on_pos: Control = null
	
	if _items[new_index]:
		_items[old_index] = _items[new_index]
	else:
		_items[old_index] = null
	_items[new_index] = item
	
	if magnet_reorder:
		_magnet_reorder_items()
	
	_position_items()
