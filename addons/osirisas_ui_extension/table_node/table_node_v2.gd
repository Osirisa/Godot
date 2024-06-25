@tool
class_name TableNode_v2
extends Control

## This Class provides you with a Table where you can add | remove | hide rows and columns
## 
## With the Table you can add | remove | hide rows and columns and fill the cells with
## Control - nodes and its children (preferably Buttons, Line-Edits and Labels 

#-----------------------------------------Signals--------------------------------------------------#

## Signal when the user clicks on a cell
signal cell_clicked(row:int, column:int)

## Signal when the user edits a cell (double click)
signal cell_edit(row:int,column:int)

## Signal when the user edited
signal cell_edit_finished(row:int,column:int)

## Signal when a column sorting was requested
signal column_sort_requested(column: int, sort: Sorting)

## Signal when a column sorting was finished
signal column_sort_finished(column: int, sort: Sorting)

#-----------------------------------------Enums----------------------------------------------------#
enum Sorting {
	ASCENDING,
	DESCENDING,
}
#-----------------------------------------Constants------------------------------------------------#

#-----------------------------------------Export Var-----------------------------------------------#

@export_category("Header")
## The header titles
@export var header_titles: Array[String] = []:
	set(value): 
		if Engine.is_editor_hint():
			if(value.size() > header_titles.size()):
				for i in range(header_titles.size(), value.size()):
					var header_text = value[i]
					
					if not header_text:
						value[i] = "header"+ str(i)
		
		header_titles = value
		
		for i in range(column_widths.size(), header_titles.size()):
			column_widths.append(standard_cell_dimension.x)
		
		if header_titles.size() < column_widths.size():
			column_widths = column_widths.slice(0, header_titles.size())

		for i in range(_column_visiblity.size(), header_titles.size()):
			_column_visiblity.append(true)
			
		if header_titles.size() < _column_visiblity.size():
			_column_visiblity = _column_visiblity.slice(0, header_titles.size())
		
		column_widths = column_widths
		column_count = header_titles.size()

		#TBD::
		#_init_v_separators()
		refresh_x_offsets_arr()
		_create_headers.call_deferred()
		#_update_layout()
		notify_property_list_changed()

## The cell height of the header
@export var header_cell_height := 30:
	set(value):
		header_cell_height = value
		#TBD::
		#_update_layout()

@export_category("Body")
## The starting widths for each column
@export var column_widths: Array[int] = []:
	set(value): 
		column_widths = value
		
		_column_widths_temp.clear()
		_column_widths_temp = column_widths.duplicate()
		#TBD::
		#_update_layout()

## The standard cell dimension a row / a column gets created with
@export var standard_cell_dimension := Vector2i(150,25)

@export_category("Resizing")
## Enables the resizing (drag on the separator for resizing the cells)
@export var resizing := true
## To stop the resizing below a certain threshhold of the cell
@export var min_size := Vector2i(50,20)

@export_category("Special")
@export_group("Culling")
## Culling makes it that only so many rows are being inserted to maximize performacne (For Large Tables)
@export var row_culling := true
## Count for the maximum simultaneously "Active / inserted" Rows at any Moment 
@export var max_row_count_active_culling := 60:
	set(value):
		max_row_count_active_culling = value
		
		if (_x_offsets.size() > 0) and (_y_offsets.size() > 0):
			_update_visible_rows.call_deferred()

@export_group("Pagination")
## Pagination for very large tables
@export var pagination := false :
	set(value):
		pagination = value
		
		refresh_y_offsets_arr()
		_clr_body.call_deferred()
		_update_body_size.call_deferred()
		_update_visible_rows.call_deferred()
		
		_scroll_container.get_v_scroll_bar().value = 0

## Count of rows per Page
@export var max_row_count_per_page := 250:
	set(value):
		max_row_count_per_page = value
		
		max_pages = int(row_count / max_row_count_per_page)
		
		refresh_y_offsets_arr()
		_clr_body.call_deferred()
		_update_body_size.call_deferred()
		_update_visible_rows.call_deferred()
		
		_scroll_container.get_v_scroll_bar().value = 0

@export_category("Themes")
##If not defined, it uses the theme applied to the Table or its parents
@export var header_theme: Theme
##If not defined, it uses the theme applied to the Table or its parents
@export var body_theme: Theme
##if a row gets selected, it uses an other theme applied. (if not defined...)
@export var selection_theme: Theme


#-----------------------------------------Public Var-----------------------------------------------#

## The current column count (incl. hidden colummns)
var column_count: int = 0
## The current row count (incl. hidden rows)
var row_count: int = 0

## How many pages there are in total (do not set it!)
var max_pages := 1
## The current visible page (starts with 0)
var current_page: int = 0:
	set(value):
		current_page = clampi(value, 0, max_pages)
		
		if _shortened:
			#print("update shortened")
			_update_body_size.call_deferred()
			_shortened = false
		
		if ((current_page + 1) * max_row_count_per_page) > row_count:
			#print("update")
			_update_body_size.call_deferred()
			_shortened = true
		
		refresh_y_offsets_arr()
		_clr_body.call_deferred()
		_update_visible_rows.call_deferred()

#-----------------------------------------Private Var----------------------------------------------#

# Utility Class
var _table_util := preload("res://addons/osirisas_ui_extension/table_node/table_utility.gd")

# Array for the standard cell heights 
var _body_cell_heights := []
# Array for the changed cell heights (due to resizing)
var _body_cell_heights_temp := []
# Array for the changed cell widths (due to resizing)
var _column_widths_temp := []


var _x_offsets := []
var _y_offsets := []

# Array with all the Rows (and its contents) in it
var _rows: Array[RowContent] = []

# Array for the visibility of the columns
var _column_visiblity: Array[bool] = []

# Seperators
var _separator_group := Control.new()

var _header_separators := []
var _vertical_separators := []

var _horizontal_separators := []

# Groups for header and body for cleaner overview
var _header_cell_group := Control.new()
var _body_cell_group := Control.new()

#The main group for all body related things (separators, cells and panel)
var _body_group := Control.new()

# Panels for Background-Color etc.
var _panel_header := Panel.new()
var _panel_body := Panel.new()

var _scroll_container := ScrollContainer.new()

# Selections
var _selected_rows: Array[RowContent] = []
var _current_row: RowContent = null
var _last_selected_row := -1

# Threads
var _sort_thread: Thread = null
 
# Pagination extra
var _shortened := false

#-----------------------------------------Onready Var----------------------------------------------#

#-----------------------------------------Init and Ready-------------------------------------------#

func _init():
	pass

# Called when the node enters the scene tree for the first time.
func _ready():
	
	var v_cont := VBoxContainer.new()
	v_cont.set_anchors_preset(Control.PRESET_FULL_RECT)
	v_cont.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v_cont.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	 # Ensure the ScrollContainer fills the parent container
	_scroll_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	_scroll_container.clip_contents = true
	_scroll_container.custom_minimum_size = Vector2(0,0)
	
	_scroll_container.get_v_scroll_bar().connect("value_changed", Callable(self,"_update_visible_rows"))
	_scroll_container.get_h_scroll_bar().connect("value_changed", Callable(self,"_scroll_header_horizontally"))
	
	_body_group.add_child(_body_cell_group)
	_body_group.add_child(_separator_group)
	_body_group.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	_scroll_container.add_child(_body_group)
	
	_header_cell_group.custom_minimum_size = Vector2i(_x_offsets.back(), header_cell_height)
	
	refresh_x_offsets_arr()
	refresh_y_offsets_arr()
	
	v_cont.add_child(_header_cell_group)
	v_cont.add_child(_scroll_container)
	
	add_child(v_cont)
	_create_headers()
	
	clip_contents = true

#-----------------------------------------Virtual methods------------------------------------------#

#-----------------------------------------Public methods-------------------------------------------#

#region Header Edit -------------

func add_column(title: String, cell_width := standard_cell_dimension.x, column_visiblity := true) -> void:
	
	column_widths.append(cell_width)
	_column_widths_temp.append(cell_width)
	
	_column_visiblity.append(column_visiblity)
	
	column_count += 1
	
	header_titles.append(title)

	for i in row_count:
		_rows[i].nodes.append(Label.new())
	
	refresh_x_offsets_arr()
	_update_visible_rows.call_deferred()

#TBD:: insert_column(title,column_pos)
#TBD:: remove_column(column_pos)

#endregion

#region Row Edit ----------------

## Adds a row to the table directly below the previous row can also called with no data, then it fills the row with empty labels
func add_row(data: Array[Control] = [], clip_text: bool = true, height: float = standard_cell_dimension.y) -> void:
	
	if data.size() > column_count:
		push_warning("data array input bigger then column count, excess nodes wont be shown!")
	
	var new_row := RowContent.new()
	
	_body_cell_heights.append(height)
	_body_cell_heights_temp.append(height)
	
	
	new_row.nodes = data
	new_row.row_visible = true
	
	_rows.append(new_row)
	row_count += 1
	
	#pagniation
	max_pages = int(row_count / max_row_count_per_page)
	
	refresh_y_offsets_arr()
	_update_body_size()
	_update_visible_rows.call_deferred()


#TBD:: insert_row(title,pos)

## Takes in following template: [ [node:Control, node2:Control],[nod...,...]...] as data use this
## for populating the table with data
## Use this for heavy table filling, as it wont update the visible rows until its finished loading the data
func add_rows_batch(data :Array, clip_text: bool = true, height: float = standard_cell_dimension.y) -> void:
	
	for d in data:
		var new_row := RowContent.new()
		
		_body_cell_heights.append(height)
		_body_cell_heights_temp.append(height)
		
		new_row.row_visible = true
		
		for node in d:
			new_row.nodes.append(node)
			new_row.editable.append(true)
		
		_rows.append(new_row)
		row_count += 1
	
	max_pages = int(row_count / max_row_count_per_page)
	
	refresh_y_offsets_arr()
	_update_body_size()
	_update_visible_rows.call_deferred()

## Overrides the row from the Table 
func set_row(data: Array[Control], row: int) -> void:
	pass

## Removes the row from the Table
func remove_row(row: int) -> void:
	pass

#endregion

#region Table Edit --------------

## Clears the whole Table
func clear() -> void:
	pass

func update_table() -> void:
	refresh_y_offsets_arr()
	refresh_x_offsets_arr()
	_update_visible_rows.call_deferred()

#endregion

#region Cell edit ---------------

func get_row(row: int) -> Array:
	return[]
	pass

func get_cell(row: int, column: int) -> Control:
	return Control.new()
	pass

func set_cell(node: Control,row: int, column: int, remain_clip_setting: bool = true) -> void:
	pass

func set_row_height(row: int, height: float) -> void:
	pass

func set_column_width(column: int, width: float) -> void:
	pass

#endregion 

#region Visibility --------------

func set_visibility_row(row: int, visible: bool) -> void:
	pass

func get_visibility_row(row: int) -> bool:
	return false
	pass

func set_visibility_column(column: int, visible: bool) -> void:
	pass

func get_visibility_column(column: int) -> bool:
	return false
	pass

#endregion

#region Editablity --------------

#TBD:: set_editable_status_cell -> void:
#TBD:: get_editable_status_cell -> bool:

#endregion

#region Sorting -----------------

func sort_rows_by_column(column: int, sort: Sorting) -> void:
	pass

#endregion

#region Selection ---------------

#TBD:: select row
#TBD:: select rows

## Selects all rows
func select_all_rows() -> void:
	pass

## Deselects all rows
func deselect_all_rows() -> void:
	pass

## Returns if the Table has a selection
func has_selection() -> bool:
	return false
	pass

## Returns the positions of the last selected Row 
func get_current_row() -> int:
	return 0
	pass

## Returns the positions of the Rows that got selected
func get_selection_positions() -> Array[int]:
	return []
	pass

#endregion

#region Sizes -------------------

## Get the total size of the header
func get_size_vec_of_header() -> Vector2i:
	return Vector2i(0,0)
	pass

## Get the total size of the body
func get_size_vec_of_body() -> Vector2i:
	return Vector2i(0,0)
	pass

#endregion

#-----------------------------------------Private methods------------------------------------------#
func _create_headers() -> void:
	
	if !_header_cell_group:
		return
	
	for child in _header_cell_group.get_children():
		_header_cell_group.remove_child(child)
		child.queue_free()
	
	for i in range(header_titles.size()):
		var header_btn = Button.new()
		var header_margin_container = MarginContainer.new()
		
		header_btn.text = header_titles[i]
		
		header_margin_container.add_child(header_btn)
		header_margin_container.position = Vector2i(_x_offsets[i], 0)
		header_margin_container.size = Vector2i(column_widths[i], header_cell_height)
		header_margin_container.custom_minimum_size = Vector2i(column_widths[i], header_cell_height)
		
		_header_cell_group.add_child(header_margin_container)

func _scroll_header_horizontally(value):
	print(value)
	_header_cell_group.position.x = -value

## Main function for inserting and visualizing the nodes
func _update_visible_rows(value = 0) -> void:
	var scroll_position = _scroll_container.get_v_scroll_bar().ratio
	
	var start: int
	var end: int
	
	if row_culling:
		start = clampi((row_count * scroll_position), 0, row_count)
		end = clampi((row_count * scroll_position) + max_row_count_active_culling, 0, row_count)
	else:
		start = 0
		end = row_count
	
	if pagination:
		if row_culling:
			start = (max_row_count_per_page * scroll_position)
			start = clampi( start + (max_row_count_per_page * current_page), 0, row_count)
			
			end = (max_row_count_per_page * scroll_position) + max_row_count_active_culling
			end = clampi(end + max_row_count_per_page * current_page, 0, max_row_count_per_page * (current_page + 1))
			end = clampi(end, 0, row_count)
		else :
			start = clampi(current_page * max_row_count_per_page, 0, row_count)
			end = clampi(max_row_count_per_page * (current_page + 1), 0, row_count)
		
		#print(current_page)
		#print(max_row_count_per_page)
		#print(start)
		#print(end)
	
	if row_culling:
		_clr_body()
	
	for i in range(start, end):
		if _rows[i].row_visible:
			for x in range(_rows[i].nodes.size()):
				var node = _rows[i].nodes[x]
				
				if !(node.get_parent() is MarginContainer):
					var margin_parent = _create_margin_container(node, i, x)
					_body_cell_group.add_child(margin_parent)
		else:
			end = clampi(end + 1, 0, row_count)

func _clr_body() -> void:
	for child in _body_cell_group.get_children():
			child.remove_child(child.get_child(0))
			_body_cell_group.remove_child(child)
			child.queue_free()

func _table_size() -> Vector2i:
	
	var table_size := Vector2i(0,0)
	table_size.x = _x_offsets.back()
	
	if not _y_offsets.size() > 0:
		return table_size 
	
	if pagination:
		var last_pos = clampi((max_row_count_per_page * (current_page + 1)) - 1, 0, row_count - 1)
		table_size.y = _y_offsets[last_pos] + _body_cell_heights_temp[last_pos] + 8
	else:
		table_size.y = _y_offsets.back() + _body_cell_heights_temp.back() + 8
	
	return table_size

func _update_body_size() -> void:
	_body_group.custom_minimum_size = _table_size()
	minimum_size_changed.emit()

func _create_margin_container(node: Control, row_index: int, col_index:int) -> MarginContainer:
	var margin_parent = MarginContainer.new()
	
	margin_parent.add_child(node)
	margin_parent.custom_minimum_size = Vector2(_column_widths_temp[col_index], _body_cell_heights_temp[row_index])
	margin_parent.size =  Vector2(_column_widths_temp[col_index], _body_cell_heights_temp[row_index])
	margin_parent.position = Vector2(_x_offsets[col_index], _y_offsets[row_index])
	
	var callable = Callable(self, "_on_cell_gui_input").bind(_rows[row_index], node)
	margin_parent.connect("gui_input", callable)
	
	if body_theme:
		margin_parent.theme = body_theme
		
	return margin_parent

func _create_h_separators() -> void:
	for sep in _horizontal_separators:
		sep.queue_free()
	_horizontal_separators.clear()
	
	for i in range(_rows.size()):  # No separator after the last row
		var sep = HSeparator.new()
		sep.name = "HSep%d" % i
		sep.mouse_default_cursor_shape = Control.CURSOR_VSIZE
		#print("addchild")
		if is_instance_valid(_separator_group):
			_separator_group.add_child(sep)
			_horizontal_separators.append(sep)
		var callable = Callable(self, "_on_separator_input").bind(i,HSeparator)
		sep.connect("gui_input", callable)

func _create_v_separators() -> void:
	pass

func _update_headers() -> void:
	pass

func _update_h_separators() -> void:
	pass

func _update_v_separators() -> void:
	pass

func _on_separator_input(event, index, type) -> void:
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_LEFT and resizing:
		# Adjust the column width based on mouse movement
		if type == VSeparator:
			_column_widths_temp[index] = max(min_size.x, _column_widths_temp[index] + event.relative.x)
			
		if type == HSeparator:
			_body_cell_heights_temp[index] = max(min_size.y,_body_cell_heights_temp[index] + event.relative.y)
		
		#_update_layout() 

func refresh_x_offsets_arr() -> void:
	_x_offsets.clear()
	
	var offsets := []
	
	for i in range (column_count):
		offsets.append(0)
		
		for x in range (i):
			if _column_visiblity[x]:
				offsets[i] += _column_widths_temp[x]
	
	_x_offsets = offsets.duplicate()

func refresh_y_offsets_arr() -> void:
	_y_offsets.clear()
	
	var offsets := []
	var start: int
	var end: int
	
	for i in row_count:
		offsets.append(0)
	
	if pagination:
		start = clampi(max_row_count_per_page * current_page, 0, row_count)
		end = clampi(max_row_count_per_page * (current_page + 1), 0, row_count)
	else:
		start = 0
		end = row_count
	
	#print("------y_offsets---")
	#print(start)
	#print(end)
	
	for i in range(start, end):
		
		for x in range (start, i):
			if _rows[i].row_visible:
				offsets[i] += _body_cell_heights_temp[x]
	
	_y_offsets = offsets.duplicate()

func _on_cell_gui_input(event: InputEvent,row_c: RowContent, node: Control) -> void:
	var row = _rows.find(row_c)
	var column = row_c.nodes.find(node)
	
	if event is InputEventMouseButton and event.double_click:
		#_edit_cell(row,column)
		print("doubleclick")
	if event is InputEventMouseButton and event.pressed and event.button_mask & MOUSE_BUTTON_LEFT:
		emit_signal("cell_clicked",row,column)
		
	if event is InputEventMouseButton and event.pressed and event.button_mask & MOUSE_BUTTON_LEFT:
		if Input.is_key_pressed(KEY_SHIFT):
			#_select_multiple_rows(row)
			pass
		elif Input.is_key_pressed(KEY_CTRL):
			#_toggle_row_selection(row)
			pass
		else:
			#_select_single_row(row)
			pass
#<--------------------------|Slots|------------------------------>#

#-----------------------------------------Subclasses-----------------------------------------------#

class Sorter:
	var column: int
	var ascending: bool
	
	func _init(column: int, ascending: bool):
		self.column = column
		self.ascending = ascending
	
	func _sort(a, b):
		var node_a = a.nodes[column]
		var node_b = b.nodes[column]
		
		var text_a: String = node_a.text if node_a.text != null else ""
		var text_b: String = node_b.text if node_b.text != null else ""
		
		if ascending:
			return text_a.naturalcasecmp_to(text_b) < 0
		else:
			return text_a.naturalcasecmp_to(text_b) > 0

class RowContent:
	var nodes: Array[Control] = []
	var row_visible := true
	var editable: Array[bool] = []
	
	var row_height: int = 0
	var row_height_temp: int = 0
