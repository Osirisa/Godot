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

@export_category("Drag Container")
@export_category("Items")

@export var init_items: Array[PackedScene]:
	set(value):
		var max_items: int = grid.x * grid.y
		if value.size() >= max_items:
			init_items = value.slice(0, max_items + 1)
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

@export var min_items_size := Vector2(100, 100)
@export var max_items_size := Vector2(100, 100)

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

# Called when the node enters the scene tree for the first time.
func _ready():
	
	resized.connect(_on_resized)
	
	_body.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	_scroll_container.add_child(_body)
	_scroll_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_scroll_container)
	_initialize_cell_positions_array()
	_calc_grid_positions()
	
	_initialize_items()
	_postion_items()
	_adj_items_size()

func _initialize_items() -> void:
	var controls: Array[Control]
	for scene in init_items:
		controls.append(scene.instantiate())
	
	for item: Control in controls:
		for child in item.get_children():
			if child is ODraggableComponent:
				_items.append(item)
				_body.add_child(item)
	


func _initialize_cell_positions_array() -> void:
	_cell_positions.resize(grid.x)
	for i in range(grid.x):
		for j in range(grid.y):
			_cell_positions[i].append(Vector2(0,0))
			
	#print(_cell_positions)

func _postion_items() -> void:
	var x: int
	var y: int
	
	for item_idx in range(_items.size()):
		x = item_idx % grid.x
		y = item_idx / grid.x
		
		#print(str(x) +" " +  str(y))
		_items[item_idx].position = _cell_positions[x][y]

func _calc_grid_positions() -> void:
	_cell_dimensions.x = (size.x - (grid.x - 1) * grid_separation.x) / grid.x
	_cell_dimensions.y = (size.y - (grid.y - 1) * grid_separation.y) / grid.y
	
	for col in range(grid.x):
		for row in range(grid.y):
			
			var min_x: = col * (min_items_size.x + grid_separation.x)
			var min_y: = row * (min_items_size.y + grid_separation.y)
			
			var max_x
			var max_y
			if max_items_size.x > 0:
				max_x = col * (max_items_size.x + grid_separation.x)
			else:
				max_x = INF
			
			if max_items_size.y > 0:
				max_y = col * (max_items_size.y + grid_separation.y)
			else:
				max_y = INF
			
			var normal_x = col * (_cell_dimensions.x + grid_separation.x)
			var normal_y = row * (_cell_dimensions.y + grid_separation.y)
			
			var x_pos: float = clampf(normal_x, min_x, max_x)
			var y_pos: float = clampf(normal_y, min_y, max_y)
			
			#print("Position for cell [", col, "][", row, "]: x =", x_pos, " y =", y_pos)
			_cell_positions[col][row] = Vector2(x_pos, y_pos)

func _adj_items_size() -> void:
	for item in _items:
		if max_items_size.x > 0:
			item.size.x = min(_cell_dimensions.x, max_items_size.x)
		else:
			item.size.x = _cell_dimensions.x
			
		if max_items_size.y > 0:
			item.size.y = min(_cell_dimensions.y, max_items_size.y)
		else:
			item.size.y = _cell_dimensions.y

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_resized() -> void:
	_calc_grid_positions()
	_postion_items()
	_adj_items_size()
