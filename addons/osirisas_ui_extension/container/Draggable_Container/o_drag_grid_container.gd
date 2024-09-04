@tool
class_name ODragContainer
extends Container

## A Container where you can place Nodes which have a draggables Container as a parent into 
## the Container and drag them on a grid
## The grid divides the space into equal amount of spaces (2x2, 3x1) and so on

signal item_dropped(item: ODraggableContainer, new_pos: Vector2i, old_pos: Vector2i)
signal item_inserted(item: ODraggableContainer, pos: Vector2i)
signal item_extruded(item: ODraggableContainer, old_pos: Vector2i)

signal container_full(container: ODragContainer)

@export_category("Drag Container")
@export_category("Items")

@export var init_items: Array[PackedScene]:
	set(value):
		var max_items: int = grid.x * grid.y
		if value.size() > max_items:
			init_items = value.slice(0, max_items)
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

var _items: Array[ODraggableContainer] = []:
	set(value):
		var max_items: int = grid.x * grid.y
		if value.size() > max_items:
			printerr("Container is full")
			_items = value.slice(0,max_items)
		else:
			_items = _items

var _scroll_container := ScrollContainer.new()
var _body := Control.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	
	_body.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	_scroll_container.add_child(_body)
	_scroll_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_scroll_container)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
