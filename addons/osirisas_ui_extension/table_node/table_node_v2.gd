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
signal column_sort_requested(column: int, sort: E_Sorting)

## Signal when a column sorting was finished
signal column_sort_finished(column: int, sort: E_Sorting)

## Private Signal (for the sorting thread, gives out the new sorted array)
signal _c_sort_finished(sorted_rows: Array)
#-----------------------------------------Enums----------------------------------------------------#
enum E_Sorting {
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
		_column_count = header_titles.size()
		
		#TBD::
		#_init_v_separators()
		_refresh_x_offsets_arr()
		_create_v_separators()
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
@export var row_culling := true:
	set(value):
		row_culling = value
		_init_v_scroll()

## Count for the maximum simultaneously "Active / inserted" Rows at any Moment 
@export var max_row_count_active_culling := 60:
	set(value):
		max_row_count_active_culling = value
		
		if !_x_offsets.is_empty() and !_y_offsets.is_empty():
			_update_visible_rows.call_deferred()

@export_group("Pagination")
## Pagination for very large tables
@export var pagination := false :
	set(value):
		pagination = value
		
		_refresh_y_offsets_arr()
		
		_clr_body.call_deferred()
		_create_h_separators.call_deferred()
		_update_h_separators.call_deferred()
		_update_v_separators.call_deferred()
		_update_body_size.call_deferred()
		_update_visible_rows.call_deferred()
		
		_scroll_container.get_v_scroll_bar().value = 0

## Count of rows per Page
@export var max_row_count_per_page := 250:
	set(value):
		max_row_count_per_page = value
		
		_refresh_max_pages()
		_refresh_y_offsets_arr()
		
		_clr_body.call_deferred()
		_create_h_separators.call_deferred()
		_update_h_separators.call_deferred()
		_update_v_separators.call_deferred()
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

## The current visible page (starts with 0)
var current_page: int = 0:
	set(value):
		current_page = clampi(value, 0, _max_pages)
		
		_culling_active_rows_old.clear()
		
		if _shortened:
			#print("update shortened")
			_update_body_size.call_deferred()
			_shortened = false
		
		if ((current_page + 1) * max_row_count_per_page) > _row_count:
			#print("update")
			_update_body_size.call_deferred()
			_shortened = true
		
		_refresh_y_offsets_arr()
		
		_clr_body.call_deferred()
		_create_h_separators.call_deferred()
		_update_h_separators.call_deferred()
		_update_v_separators.call_deferred()
		_update_visible_rows.call_deferred()

#-----------------------------------------Private Var----------------------------------------------#

# Utility Class
var _table_util := preload("res://addons/osirisas_ui_extension/table_node/table_utility.gd")

# counts
var _column_count: int = 0
var _row_count: int = 0

# Array for the changed cell widths (due to resizing)
var _column_widths_temp := []

var _x_offsets := []
var _y_offsets := []

# Array with all the Rows (and its contents) in it
var _rows: Array[RowContent] = []

# Array for the visibility of the columns
var _column_visiblity: Array[bool] = []
var _invisible_rows: Array[RowContent] = []

var _last_visible_row: int = 0
var _last_visible_column: int = 0
var _offset_rows_visibility_pages: Array[int] = []

# Seperators
var _separator_group := Control.new()
var _header_separator_group := Control.new()

var _header_separators := []
var _vertical_separators := []

var _horizontal_separators := []

# Groups for header and body for cleaner overview
var _header_cell_group := Control.new()
var _body_cell_group := Control.new()

#The main group for all body related things (separators, cells and panel)
var _header_group := Control.new()
var _body_group := Control.new()

# Panels for Background-Color etc.
#TBD::
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
var _max_pages: int = 0
var _rows_visible_on_page: Array[RowContent] = []
var _shortened := false

# Culling extra
var _culling_active_rows_old: Array[int] = []

#-----------------------------------------Onready Var----------------------------------------------#

#-----------------------------------------Init and Ready-------------------------------------------#

func _init():
	pass

# Called when the node enters the scene tree for the first time.
func _ready():
	
	connect("_c_sort_finished",Callable(self, "_on_sorting_complete"))
	
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

	_refresh_last_visible_column()

	_init_v_scroll()
	_scroll_container.get_h_scroll_bar().connect("value_changed", Callable(self,"_scroll_header_horizontally"))
	
	_body_group.add_child(_body_cell_group)
	_body_group.add_child(_separator_group)
	_body_group.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	_scroll_container.add_child(_body_group)
	
	_header_group.custom_minimum_size = Vector2i(_x_offsets.back(),header_cell_height)
	_header_group.add_child(_header_cell_group)
	_header_group.add_child(_header_separator_group)
	
	_refresh_x_offsets_arr()
	_refresh_y_offsets_arr()
	
	v_cont.add_child(_header_group)
	v_cont.add_child(_scroll_container)
	
	add_child(v_cont)
	
	
	_create_headers.call_deferred()
	_create_h_separators.call_deferred()
	_create_v_separators.call_deferred()
	_update_h_separators.call_deferred()
	_update_v_separators.call_deferred()
	
	clip_contents = true


#-----------------------------------------Virtual methods------------------------------------------#

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		deselect_all_rows()

	elif event.is_action_pressed("ui_text_select_all"):
		select_all_rows()

#-----------------------------------------Public methods-------------------------------------------#

#region Header Edit -------------

func add_column(title: String, cell_width := standard_cell_dimension.x, column_visiblity := true) -> void:
	
	column_widths.append(cell_width)
	_column_widths_temp.append(cell_width)
	_column_visiblity.append(column_visiblity)
	
	_column_count += 1
	
	header_titles.append(title)
	
	_fill_rows_arr()
	
	_refresh_last_visible_column()
	_refresh_x_offsets_arr()
	
	_create_headers.call_deferred()
	_create_v_separators.call_deferred()
	_update_v_separators.call_deferred()
	_update_h_separators.call_deferred()
	_update_visible_rows.call_deferred()

func insert_column(title, column_pos, cell_width := standard_cell_dimension.x, column_visiblity := true):
	if not _table_util.check_column_input(column_pos, _column_count - 1):
		return
	
	column_widths.insert(column_pos, cell_width)
	_column_widths_temp.insert(column_pos, cell_width)
	
	_column_visiblity.insert(column_pos, column_visiblity)
	
	_column_count += 1
	
	header_titles.insert(column_pos, title)

	for i in _row_count:
		var row = _rows[i]
		
		var std_label = _table_util.create_standard_label()
		
		row.nodes.insert(column_pos, std_label)
		row.editable.insert(column_pos, true)
	
	_refresh_last_visible_column()
	_refresh_x_offsets_arr()
	
	_create_headers.call_deferred()
	_create_v_separators.call_deferred()
	_update_v_separators.call_deferred()
	_update_h_separators.call_deferred()
	_update_visible_rows.call_deferred()

func remove_column(column_pos):
	if not _table_util.check_column_input(column_pos, _column_count-1):
		return
	
	column_widths.remove_at(column_pos)
	_column_widths_temp.remove_at(column_pos)
	
	_column_visiblity.remove_at(column_pos)
	
	_column_count = _column_count - 1 if _column_count > 0 else 0 
	
	header_titles.remove_at(column_pos)

	for i in _row_count:
		var row = _rows[i]
		
		var parent = row.nodes[column_pos].get_parent()
		
		if parent:
			parent.remove_child(row.nodes[column_pos])
			parent.queue_free

		row.nodes.remove_at(column_pos)
		row.editable.remove_at(column_pos)
	
	_refresh_last_visible_column()
	_refresh_x_offsets_arr()
	
	_create_headers.call_deferred()
	_create_v_separators.call_deferred()
	_update_v_separators.call_deferred()
	_update_h_separators.call_deferred()
	_update_visible_rows.call_deferred()

func get_column_count() -> int:
	return _column_count

#endregion

#region Row Edit ----------------

## Adds a row to the table directly below the previous row can also called with no data, then it fills the row with empty labels
func add_row(data: Array[Control] = [], height: float = standard_cell_dimension.y) -> void:

	if data.size() > _column_count:
		push_warning("data array input bigger then column count, excess nodes wont be shown!")
	
	var new_row := RowContent.new()
	
	new_row.nodes = data
	new_row.row_visible = true
	new_row.row_height = height
	new_row.row_height_temp = height
	
	_rows.append(new_row)
	
	_row_count += 1
	
	_refresh_max_pages()
	_fill_rows_arr()
	
	_refresh_last_visible_row()
	_refresh_y_offsets_arr()
	_update_body_size()
	
	_create_h_separators.call_deferred()
	_update_h_separators.call_deferred()
	_update_v_separators.call_deferred()
	_update_visible_rows.call_deferred()


func insert_row(data: Array[Control], row_pos: int, height: float = standard_cell_dimension.y):
	if not _table_util.check_row_input(row_pos, _row_count - 1):
		return
	
	var new_row := RowContent.new()
	
	new_row.nodes = data
	new_row.row_visible = true
	new_row.row_height = height
	new_row.row_height_temp = height
	
	_rows.insert(row_pos, new_row)
	
	_row_count += 1
	

	_refresh_max_pages()
	_fill_rows_arr()

	_refresh_last_visible_row()
	_refresh_y_offsets_arr()
	_update_body_size()
	
	_create_h_separators.call_deferred()
	_update_h_separators.call_deferred()
	_update_v_separators.call_deferred()
	_update_visible_rows.call_deferred()


## Takes in following template: [ [node:Control, node2:Control],[nod...,...]...] as data use this
## for populating the table with data
## Use this for heavy table filling, as it wont update the visible rows until its finished loading the data
func add_rows_batch(data :Array, height: float = standard_cell_dimension.y) -> void:
	
	for d in data:
		var new_row := RowContent.new()
		
		new_row.row_visible = true
		
		for node in d:
			new_row.nodes.append(node)
			new_row.editable.append(true)
			new_row.row_height = height
			new_row.row_height_temp = height
		
		_rows.append(new_row)
		_row_count += 1
	
	_refresh_max_pages()
	_fill_rows_arr()

	_refresh_last_visible_row()
	_refresh_y_offsets_arr()
	_update_body_size()
	
	_create_h_separators.call_deferred()
	_update_h_separators.call_deferred()
	_update_visible_rows.call_deferred()

## Overrides the row from the Table 
func set_row(data: Array[Control], row: int, clip_text: bool = true, height: float = standard_cell_dimension.y) -> void:
	if not _table_util.check_row_input(row, _row_count - 1):
		return
	
	if data.size() > _column_count:
		push_warning("data array input bigger then column count, excess nodes wont be shown!")
	
	var edited_row := _rows[row]
	
	edited_row.nodes = data
	edited_row.row_visible = true
	edited_row.row_height = height
	edited_row.row_height_temp = height
	
	_refresh_last_visible_row()
	_refresh_y_offsets_arr()
	_update_body_size()
	
	_create_h_separators.call_deferred()
	_update_h_separators.call_deferred()
	_update_visible_rows.call_deferred()

## Removes the row from the Table
func remove_row(row: int) -> void:
	if not _table_util.check_row_input(row, _row_count - 1):
		return
	
	for node in _rows[row].nodes:
		var parent = node.get_parent()

		if parent:
			parent.queue_free()
		else:
			node.queue_free()

	if not _rows[row].row_visible:
			_invisible_rows.erase(_rows[row])
	
	_rows.remove_at(row)
	
	_row_count = _row_count - 1 if _row_count > 0 else 0
	
	_refresh_max_pages()
	_refresh_last_visible_row()
	_recalc_row_offsets_visibility()
	
	if (current_page > _max_pages) and pagination:
		current_page = current_page
	else:

		_refresh_last_visible_row()
		_refresh_y_offsets_arr()
		
		_create_h_separators.call_deferred()
		_update_h_separators.call_deferred()
		_update_v_separators.call_deferred()
		_update_visible_rows.call_deferred()	
	
	_update_body_size()

## Removes the rows from the Table e.g.: remove_row_batch([2,5,1,3,8])
func remove_rows_batch(rows_to_remove: Array[int]) -> void:
	
	rows_to_remove.sort()
	
	for index in range(rows_to_remove.size(), 0, -1):
		if not _rows[rows_to_remove[index]].row_visible:
			_invisible_rows.erase(_rows[rows_to_remove[index]])
		
		_rows.remove_at(rows_to_remove[index])
		_row_count = _row_count - 1 if _row_count > 0 else 0
	
	_refresh_max_pages()
	_refresh_last_visible_row()
	
	if (current_page > _max_pages) and pagination:
		current_page = current_page
	else:
		
		_refresh_y_offsets_arr()
		_culling_active_rows_old.clear()
		
		_create_h_separators.call_deferred()
		_update_h_separators.call_deferred()
		_update_v_separators.call_deferred()
		_update_visible_rows.call_deferred()	
	
	_update_body_size()

func get_row_count() -> int:
	return _row_count

#endregion

#region Table Edit --------------

## Clears the whole Table
func clear() -> void:
	_invisible_rows.clear()
	_rows.clear()
	header_titles.clear()
	
	_row_count = 0
	_column_count = 0
	
	_max_pages = 0
	current_page = 0
	
	_refresh_y_offsets_arr()
	_refresh_x_offsets_arr()
	_update_body_size()
	
	_create_headers.call_deferred()
	_create_h_separators.call_deferred()
	_create_v_separators.call_deferred()
	_update_h_separators.call_deferred()
	_update_v_separators.call_deferred()
	_update_visible_rows.call_deferred()

func update_table() -> void:
	_refresh_y_offsets_arr()
	_refresh_x_offsets_arr()
	
	_update_h_separators.call_deferred()
	_update_v_separators.call_deferred()

	_update_visible_rows.call_deferred()

#endregion

#region Cell edit ---------------

func get_row(row: int) -> Array:
	if not _table_util.check_row_input(row, _row_count- 1):
		return []
	var row_contens: Array = []
	row_contens = _rows[row].nodes.duplicate()
	
	return row_contens

func get_cell(row: int, column: int) -> Control:
	#--check if row and column matches size of the arrays--
	if not _table_util.check_row_input(row, _row_count- 1):
		return null
	
	if not _table_util.check_column_input(column, _column_count - 1):
		return null
	
	return _rows[row].nodes[column]

func set_cell(node: Control,row: int, column: int) -> void:
	if not _table_util.check_row_input(row, _row_count- 1):
		return
	
	if not _table_util.check_column_input(column, _column_count - 1):
		return
	
	_rows[row].nodes[column] = node

	_update_visible_rows.call_deferred()

func set_row_height(row: int, height: float) -> void:
	if not _table_util.check_row_input(row, _row_count- 1):
		return
	
	_rows[row].row_height_temp = height

	_refresh_y_offsets_arr()

	_update_h_separators.call_deferred()
	_update_visible_rows.call_deferred()

func set_column_width(column: int, width: float) -> void:
	if not _table_util.check_column_input(column, _column_count - 1):
		return
	
	_column_widths_temp[column] = width

	_refresh_x_offsets_arr()

	_update_v_separators.call_deferred()
	_update_visible_rows.call_deferred()
#endregion 

#region Visibility --------------

func set_visibility_row(row: int, visible: bool) -> void:
	if not _table_util.check_row_input(row, _row_count- 1):
		return
	
	var nodes = _rows[row].nodes
	
	for node_idx in range(nodes.size()):
		if _column_visiblity[node_idx]:
			nodes[node_idx].visible = visible
	
	_rows[row].row_visible = visible
	
	if visible:
		_invisible_rows.erase(_rows[row])
	else:
		_invisible_rows.append(_rows[row])
	
	_refresh_max_pages()
	_refresh_last_visible_row()
	_recalc_row_offsets_visibility()
	
	if (current_page > _max_pages) and pagination:
		current_page = current_page
	else:
		
		_refresh_y_offsets_arr()
		_culling_active_rows_old.clear()
		
		_create_h_separators.call_deferred()
		_update_h_separators.call_deferred()
		_update_v_separators.call_deferred()
		_update_visible_rows.call_deferred()	
	
	_update_body_size()

func get_visibility_row(row: int) -> bool:
	if not _table_util.check_row_input(row, _row_count- 1):
		return false
	
	return _rows[row].row_visible

func set_visibility_column(column: int, visible: bool) -> void:
	if not _table_util.check_column_input(column, _column_count - 1):
		return
	
	_column_visiblity[column] = visible

	for row in _rows:
		if row.row_visible:
			row.nodes[column].visible = visible
	
	_refresh_last_visible_column()
	update_table()
	_update_headers.call_deferred()

func get_visibility_column(column: int) -> bool:
	if not _table_util.check_column_input(column, _column_count - 1):
		return false
	
	return _column_visiblity[column]


func get_invisible_rows() -> Array[int]:
	var invisible_rows: Array[int] = []

	for row in _invisible_rows:
		var idx = _rows.find(row)
		if idx >= 0:
			invisible_rows.append(idx)

	return invisible_rows

func get_invisible_columns() -> Array[int]:
	var invisible_columns: Array[int] = []
	
	for col in range(_column_visiblity.size()):
		if not _column_visiblity[col]:
			invisible_columns.append(col)
	
	return invisible_columns
#endregion

#region Editablity --------------

func set_editable_status_cell(row: int, column: int, edit_status: bool) -> void:
	if not _table_util.check_row_input(row, _row_count- 1):
		return

	if not _table_util.check_column_input(column, _column_count - 1):
		return

	_rows[row].editable[column] = edit_status

func get_editable_status_cell(row: int, column: int) -> bool:
	if not _table_util.check_row_input(row, _row_count- 1):
		return false

	if not _table_util.check_column_input(column, _column_count - 1):
		return false

	return _rows[row].editable[column]

#endregion

#region Sorting -----------------

func sort_rows_by_column(column: int, sort: E_Sorting) -> void:
	if not _table_util.check_column_input(column, _column_count - 1):
		return
	
	_sort_thread = Thread.new()
	var callable = Callable(self, "_sort_thread_function").bind([column, sort])
	_sort_thread.start(callable)

#endregion

#region Selection ---------------

func select_row(row: int) -> void:
	if not _table_util.check_row_input(row, _row_count- 1):
		return

	_select_single_row(row)

func select_rows(start_row: int, end_row: int) -> void:
	if not _table_util.check_row_input(start_row, _row_count- 1):
		return

	if not _table_util.check_row_input(end_row, _row_count- 1):
		return

	_select_single_row(start_row)
	_select_multiple_rows(end_row)


## Selects all rows
func select_all_rows() -> void:
	for row in _rows:
		
		if row.selected == false:
			_selected_rows.append(row)
			row.selected = true
			_update_row_selection_visuals(row)


## Deselectes all rows
func deselect_all_rows() -> void:

	if _selected_rows.is_empty():
		return
	
	for row in _selected_rows:
		
		row.selected = false
		row.deselect = true
		_update_row_selection_visuals(row)
	
	_selected_rows.clear()

## Returns true if something is selected, else false
func has_selection() -> bool:
	if _selected_rows.is_empty():
		return false
	else:
		return true

## Returns the position of the last selected Row
func get_current_row() -> int:
	return _rows.find(_current_row)

## Returns the positions of the Rows that got selected
func get_selection_positions() -> Array[int]:
	var positions: Array[int] = []
	for row in _selected_rows:
		positions.append(_rows.find(row))
	positions.sort()
	return positions

#endregion

#region Sizes -------------------

## Get the total size of the header
func get_size_vec_of_header() -> Vector2i:
	var header_size: Vector2i = Vector2i(_table_size().x, header_cell_height)
	return header_size

## Get the total size of the body
func get_size_vec_of_body() -> Vector2i:
	return _table_size()

#endregion

#region Pagination -------------
## Returns the maximal pages calculated from the rowcount and the max.
## possible rows per page
func get_max_pages() -> int:
	return _max_pages

#endregion

#-----------------------------------------Private methods------------------------------------------#
func _init_v_scroll() -> void:
	var callable_culling := Callable(self,"_update_visible_rows")
	
	if row_culling:
		_scroll_container.get_v_scroll_bar().connect("value_changed", callable_culling)
	else:
		if _scroll_container.get_v_scroll_bar().is_connected("value_changed", callable_culling):
			_scroll_container.get_v_scroll_bar().disconnect("value_changed", callable_culling)


func _create_headers() -> void:
	
	if !_header_cell_group:
		return
	
	for child in _header_cell_group.get_children():
		_header_cell_group.remove_child(child)
		child.queue_free()
	
	for col_idx in range(header_titles.size()):
		var header_btn := Button.new()
		var header_margin_container := MarginContainer.new()
		
		header_btn.text = header_titles[col_idx]
		header_btn.clip_text = true
		header_btn.clip_contents = true
		
		var callable = Callable(self, "_on_header_clicked").bind(col_idx)
		header_btn.connect("pressed", callable)
		
		header_margin_container.add_child(header_btn)
		header_margin_container.position = Vector2i(_x_offsets[col_idx], 0)
		header_margin_container.size = Vector2i(column_widths[col_idx], header_cell_height)
		header_margin_container.custom_minimum_size = Vector2i(column_widths[col_idx], header_cell_height)
		
		_header_cell_group.add_child(header_margin_container)

func _update_headers() -> void:
	var children = _header_cell_group.get_children()

	for idx in children.size():
		if _column_visiblity[idx]:
			children[idx].show()
			children[idx].position = Vector2i(_x_offsets[idx], 0)
			children[idx].size = Vector2i(_column_widths_temp[idx], header_cell_height)
			children[idx].custom_minimum_size = Vector2i(_column_widths_temp[idx], header_cell_height)
		else:
			children[idx].hide()

func _scroll_header_horizontally(value):
	#print(value)
	_header_group.position.x = -value

func _refresh_max_pages() -> void:
	_max_pages = int((_row_count - 1 - _invisible_rows.size()) / max_row_count_per_page)
	#print(str(_max_pages) + ", " + str(_invisible_rows.size()))


func _refresh_last_visible_row() -> void:
	if _rows.is_empty():
		return

	for idx in range(_row_count - 1, -1, -1):
		if _rows[idx].row_visible:
			_last_visible_row = idx
			return

func _refresh_last_visible_column() -> void:
	if _column_visiblity.is_empty():
		return

	for idx in range (_column_count - 1, -1, -1):
		if _column_visiblity[idx]:
			_last_visible_column = idx
			return

func _recalc_row_offsets_visibility() -> void:
	
	_offset_rows_visibility_pages.clear()
	_offset_rows_visibility_pages.resize(_max_pages + 1)
	_offset_rows_visibility_pages.fill(0)
	
	for i in range(_max_pages + 1):
		
		var x = i - 1 if i > 0 else 0
		var start_rows = (max_row_count_per_page * i + _offset_rows_visibility_pages[x])
		var end_rows = start_rows + max_row_count_per_page
		
		end_rows = clampi(end_rows, 0, _row_count)
		start_rows = clampi(start_rows, 0, _row_count)
		
		var offsets = 0
		var valid_rows = 0
		
		var row_idx = start_rows
		while row_idx < end_rows:
			if _rows[row_idx].row_visible:
				valid_rows += 1
			else:
				offsets += 1
				end_rows = clampi(end_rows + 1, 0, _row_count)
			if valid_rows == max_row_count_per_page:
				break
			
			row_idx += 1
		
		if i > 0:
			_offset_rows_visibility_pages[i] = offsets + _offset_rows_visibility_pages[i - 1]
		else:
			_offset_rows_visibility_pages[i] = offsets
	
	#print(_offset_rows_visibility_pages)

## Main function for inserting and visualizing the nodes
func _update_visible_rows(value: int = 0) -> void:
	var start_index: int = 0
	var end_index: int = _row_count
	
	if value == 0:
		value = _scroll_container.get_v_scroll_bar().value
		
	for i in range(_y_offsets.size()):
		if _y_offsets[i] >= value:
			start_index = i - 1 if i > 0 else 0
			break 
	
	if pagination:
		var page_start: int = current_page * max_row_count_per_page
		var page_end: int = page_start + max_row_count_per_page
		
		if not _offset_rows_visibility_pages.is_empty():
			if current_page > 0:
				page_start += _offset_rows_visibility_pages[current_page - 1]
			
			page_end += _offset_rows_visibility_pages[current_page]
		
		if row_culling:
			start_index = max(start_index, page_start)
			end_index = min(start_index + max_row_count_active_culling, page_end)
			
		else :
			start_index = page_start
			end_index = page_end
		
	elif row_culling:
		end_index = min(start_index + max_row_count_active_culling, _row_count)
	
	start_index = clampi(start_index, 0, _row_count)
	end_index = clampi(end_index, 0, _row_count)
	
	if _culling_active_rows_old.is_empty():
		_clr_body()
		
		for row in _rows:
			row.row_culling_rendered = false
		
	elif row_culling:
		var clr_arr := []
		for idx in _culling_active_rows_old:
			if idx > end_index - 1 or idx < start_index:
				clr_arr.append(idx)
		
		for row_index in clr_arr:
			var row = _rows[row_index]
			row.row_culling_rendered = false
			
			for node in row.nodes:
				var parent = node.get_parent()
				if parent:
					parent.remove_child(node)
					_body_cell_group.remove_child(parent)
					parent.queue_free()
	
	_culling_active_rows_old.clear()
	
	begin_bulk_theme_override()
	var row_idx: int = start_index
	while row_idx < end_index:
		
		var row = _rows[row_idx]
		_culling_active_rows_old.append(row_idx)
		row.row_culling_rendered = true
		
		if row.row_visible:
			#print(str(end_index) + "visible")
			for col_idx in range(_column_count):
				var nodes = row.nodes
				var node
				var change_pos := true
				
				node = nodes[col_idx]
				var parent = node.get_parent()
				
				if !(parent is MarginContainer):
					_set_properties(node)
					var margin_parent = _create_margin_container(node, row_idx, col_idx)
					_body_cell_group.add_child(margin_parent)
					change_pos = false
					
				elif !(parent.size.x == _column_widths_temp[col_idx]) or !(parent.size.y == row.row_height_temp):
					parent.custom_minimum_size = Vector2(_column_widths_temp[col_idx], row.row_height_temp)
					parent.size =  Vector2(_column_widths_temp[col_idx], row.row_height_temp)
					
				if change_pos:
					parent.position = Vector2(_x_offsets[col_idx], _y_offsets[row_idx])
				
				_update_row_selection_visuals(row)
		else:
			end_index = clampi(end_index + 1, 0, _row_count)
		
		row_idx += 1
	end_bulk_theme_override()

func _set_properties(node: Control) -> void:
	if node is LineEdit:
		node.clip_contents = true
	elif node is Button or Label:
		node.clip_text = true
		node.clip_contents = true

func _fill_rows_arr() -> void:
	var nodes
	
	for row in _rows:
		nodes = row.nodes
		
		for col_idx in range(_column_count):
			if !(nodes.size() > col_idx):
				var std_label = _table_util.create_standard_label()
				
				nodes.append(std_label)
				row.editable.append(true)

func _clr_body() -> void:
	
	for child in _body_cell_group.get_children():
		child.remove_child(child.get_child(0))
		_body_cell_group.remove_child(child)
		child.queue_free()

func _table_size() -> Vector2i:
	
	var table_size := Vector2i(0,0)

	if _x_offsets.is_empty():
		return table_size 
	
	table_size.x = _x_offsets[_last_visible_column] + _column_widths_temp[_last_visible_column]
	
	if _y_offsets.is_empty():
		return table_size 
	
	if pagination:
		var last_pos = max_row_count_per_page * (current_page + 1) - 1
		
		if not _offset_rows_visibility_pages.is_empty():
			last_pos += _offset_rows_visibility_pages[current_page]
			
		last_pos = clampi(last_pos, 0, _row_count - 1)
		
		table_size.y = _y_offsets[last_pos] + _rows[last_pos].row_height_temp + 8
	else:
		table_size.y = _y_offsets[_last_visible_row] + _rows[_last_visible_row].row_height_temp + 8
	
	return table_size

func _update_body_size() -> void:
	_body_group.custom_minimum_size = _table_size()
	minimum_size_changed.emit()

func _create_margin_container(node: Control, row_index: int, col_index:int) -> MarginContainer:
	var margin_parent = MarginContainer.new()
	
	margin_parent.add_child(node)
	margin_parent.custom_minimum_size = Vector2(_column_widths_temp[col_index], _rows[row_index].row_height_temp)
	margin_parent.size =  Vector2(_column_widths_temp[col_index], _rows[row_index].row_height_temp)
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
	
	var start_idx: int = 0
	var end_idx: int = _row_count
	
	var offset: int = 0
	
	if pagination:
		var invis_count = _invisible_rows.size()
		offset = invis_count - max_row_count_per_page * int (invis_count / max_row_count_per_page)
		end_idx = max_row_count_per_page
		
		if not _offset_rows_visibility_pages.is_empty():
			end_idx = end_idx + _offset_rows_visibility_pages[current_page]
		
		if max_row_count_per_page * (current_page + 1) > _row_count:
			end_idx = _row_count - (max_row_count_per_page * current_page)
			end_idx -= offset
		
		end_idx = clampi(end_idx, 0, max_row_count_per_page)
	
	start_idx = clampi(start_idx, 0, _row_count)
	end_idx = clampi(end_idx, 0, _row_count)
	
	#print("Start: " + str(start_idx))
	#print("End: " + str(end_idx))
	
	for idx in range(start_idx, end_idx):  # No separator after the last row
		var sep = HSeparator.new()
		sep.name = "HSep%d" % idx
		sep.mouse_default_cursor_shape = Control.CURSOR_VSIZE
		
		#print("addchild")
		if is_instance_valid(_separator_group):
			_separator_group.add_child(sep)
			_horizontal_separators.append(sep)
		
		var row := idx
		if has_meta("sorting_state"):
			if not get_meta("sorting_state") == E_Sorting.DESCENDING:
				#print("ascending +")
				row += offset
		else:
			row += offset
		
		var callable = Callable(self, "_on_separator_input").bind(row ,HSeparator)
		sep.connect("gui_input", callable)
	
	#print("Offset: " + str(offset))
	#print("End: " + str(end_idx))

func _create_v_separators() -> void:
	for v_sep in _vertical_separators:
		v_sep.queue_free()
	_vertical_separators.clear()
	
	for head_sep in _header_separators:
		head_sep.queue_free()
	_header_separators.clear()

		
	for i in range(_column_count):
		var sep = VSeparator.new()
		var sep_header = VSeparator.new()
		
		sep.name = "VSep%d" % i
		sep.mouse_default_cursor_shape = Control.CURSOR_HSIZE
		
		sep_header.name = "VSep%d" % i
		sep_header.mouse_default_cursor_shape = Control.CURSOR_HSIZE
		sep_header.set_size(Vector2i(1, header_cell_height))
		
		if is_instance_valid(_header_separator_group):
			_header_separator_group.add_child(sep_header)
			_header_separators.append(sep_header)
			
		if is_instance_valid(_separator_group):
			_separator_group.add_child(sep)
			_vertical_separators.append(sep)
		
		var callable = Callable(self, "_on_separator_input").bind(i,VSeparator)
		sep_header.connect("gui_input", callable)
		sep.connect("gui_input", callable)

func _update_h_separators() -> void:
	var pos: int = 0
	var index: int = 0
	
	if _rows.is_empty():
		return
	
	for i in range (_horizontal_separators.size()):
		index = i
		
		if pagination:
			var invis_count = _invisible_rows.size()
			var offset = invis_count - max_row_count_per_page * int(invis_count / max_row_count_per_page)
			#var offset = _offset_rows_visibility_pages[current_page]
			
			
			index += (max_row_count_per_page * current_page)
			
			if has_meta("sorting_state"):
				if not get_meta("sorting_state") == E_Sorting.DESCENDING:
					#print("ascending +")
					index += offset
			else:
				index += offset
			
			index = clampi(index, 0, _row_count - 1)
			
		if _rows[index].row_visible:
			pos += _rows[index].row_height_temp
			
			_horizontal_separators[i].position = Vector2(0, pos)
			_horizontal_separators[i].visible = true
			
			_horizontal_separators[i].set_size(Vector2(_x_offsets[_last_visible_column] + _column_widths_temp[_last_visible_column], 1))
		else:
			_horizontal_separators[i].visible = false
	
	_update_headers.call_deferred()
	_update_body_size()

func _update_v_separators() -> void:
	#needs a litle offset for it to look good here: -2.5px
	var pos = -2.5
	
	for i in range(_vertical_separators.size()):
		if _column_widths_temp.size() > i:
			if _column_visiblity[i]:
				pos += _column_widths_temp[i]
				
				_vertical_separators[i].position = Vector2(pos, 0)
				_vertical_separators[i].visible = true
				
				_header_separators[i].position = Vector2(pos, 0)
				_header_separators[i].visible = true
				
				if _row_count > 0:
					if pagination:
						var index: int = max_row_count_per_page * (current_page + 1) - 1
						var rows_index := index
						if not _offset_rows_visibility_pages.is_empty():
							rows_index += _offset_rows_visibility_pages[current_page]
						rows_index = clampi(rows_index, 0, _row_count - 1)
						
						if index > _row_count:
							rows_index = _row_count - 1
						
						_vertical_separators[i].set_size(Vector2(1, _y_offsets[rows_index] + _rows[rows_index].row_height_temp))
					else:
						_vertical_separators[i].set_size(Vector2(1, _y_offsets[_last_visible_row] + _rows[_last_visible_row].row_height_temp))
				else:
					_vertical_separators[i].visible = false
				
			else:
				_vertical_separators[i].visible = false
				_header_separators[i].visible = false
	
	_update_headers.call_deferred()
	_update_body_size()

func _refresh_x_offsets_arr() -> void:
	_x_offsets.clear()
	
	var offsets := []
	offsets.resize(_column_count)
	offsets.fill(0)
	
	for i in range (_column_count):
		if _column_visiblity[i]:
			for x in range (i):
				if _column_visiblity[x]:
					offsets[i] += _column_widths_temp[x]
		else:
			if i > 0:
				offsets[i] = offsets[i-1]

	_x_offsets = offsets.duplicate()

func _refresh_y_offsets_arr() -> void:
	_y_offsets.clear()
	
	var offsets := []
	var start: int
	var end: int
	
	offsets.resize(_row_count)
	offsets.fill(0)
	
	if pagination:
		start = clampi(max_row_count_per_page * current_page, 0, _row_count)
		end = max_row_count_per_page * (current_page + 1)
		
		if not _offset_rows_visibility_pages.is_empty():
			if current_page > 0:
				start += _offset_rows_visibility_pages[current_page - 1]
			
			end += _offset_rows_visibility_pages[current_page]
		
		end = clampi(end, 0, _row_count)
	else:
		start = 0
		end = _row_count
	
	for i in range(start, end):
		if _rows[i].row_visible:
			offsets[i] += 2
			for x in range (start, i):
				if _rows[x].row_visible:
					offsets[i] += _rows[x].row_height_temp 
		else:
			if i > 0:
				offsets[i] = offsets[i-1]
	
	_y_offsets = offsets.duplicate()

func _sort_thread_function(args: Array) -> void:
	var column = args[0]
	var ascending: E_Sorting = args[1]
	
	#var sorted_rows = _rows.duplicate()
	
	var sorter = Sorter.new(column, ascending)
	_rows.sort_custom(sorter._sort)
	
	call_deferred("emit_signal", "_c_sort_finished", _rows)

func _select_single_row(row: int) -> void:
	deselect_all_rows()
	
	var curr_row = _rows[row]
	
	curr_row.selected = true
	
	_selected_rows.append(curr_row)
	_current_row = curr_row
	_last_selected_row = row
	
	_update_row_selection_visuals(curr_row)

func _toggle_row_selection(row: int) -> void:
	
	var curr_row = _rows[row]
	
	if not curr_row.selected:
		_selected_rows.append(curr_row)
		curr_row.selected = true
		_last_selected_row = row

	else:
		_selected_rows.erase(curr_row)
		curr_row.selected = false
		curr_row.deselect = true
	
	_current_row = curr_row
	_update_row_selection_visuals(curr_row)

func _select_multiple_rows(row: int) -> void:
	
	if _last_selected_row == -1:
		_select_single_row(row)
		return
	
	var start = min(_last_selected_row, row)
	var end = max(_last_selected_row, row)
	
	for idx in range(start, end + 1):
		var curr_row = _rows[idx]
		
		if curr_row.selected == false:
			_selected_rows.append(curr_row)
			curr_row.selected = true
			_update_row_selection_visuals(curr_row)
	
	_current_row = _rows[row]

func _update_row_selection_visuals(row: RowContent) -> void:
	
	if not row.row_culling_rendered:
		return
	
	if row.selected:
		for node in row.nodes:
			if selection_theme:
				_reapply_theme.call_deferred(node, selection_theme)
		
	elif row.deselect:
		for node in row.nodes:
			if body_theme:
				_reapply_theme.call_deferred(node, body_theme)
			else:
				_clear_node_theme.call_deferred(node)
		
		row.deselect = false

func _clear_node_theme(node: Control):
	node.theme = null
	var parent = node.get_parent()
	if parent:
		parent.theme = null

func _reapply_theme(node: Control, theme: Theme):
	node.theme = theme
	var parent = node.get_parent()
	if parent:
		parent.theme = theme
#<--------------------------|Slots|------------------------------>#

func _on_cell_gui_input(event: InputEvent,row_c: RowContent, node: Control) -> void:
	var row = _rows.find(row_c)
	var column = row_c.nodes.find(node)
	
	if event is InputEventMouseButton and event.double_click:
		#_edit_cell(row,column)
		pass
	if event is InputEventMouseButton and event.pressed and event.button_mask & MOUSE_BUTTON_LEFT:
		emit_signal("cell_clicked",row,column)
		
	if event is InputEventMouseButton and event.pressed and event.button_mask & MOUSE_BUTTON_LEFT:
		if Input.is_key_pressed(KEY_SHIFT):
			_select_multiple_rows(row)
			
		elif Input.is_key_pressed(KEY_CTRL):
			_toggle_row_selection(row)
		else:
			#print("select")
			_select_single_row(row)

func _on_separator_input(event, index, type) -> void:
	
	var changed := false
	
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_LEFT and resizing:
		# Adjust the column width based on mouse movement
		if type == VSeparator:
			_column_widths_temp[index] = max(min_size.x, _column_widths_temp[index] + int(event.relative.x))
			changed = true
		
		if type == HSeparator:
			_rows[index + (max_row_count_per_page * current_page)].row_height_temp = max(min_size.y, _rows[index + (max_row_count_per_page * current_page)].row_height_temp + event.relative.y)
			print("index: " + str(index + (max_row_count_per_page * current_page)))
			changed = true
		
	if event is InputEventMouseButton and event.double_click:
		if type == VSeparator:
			_column_widths_temp[index] = column_widths[index]
			changed = true
			
		if type == HSeparator:
			_rows[index + (max_row_count_per_page * current_page)].row_height_temp = _rows[index + (max_row_count_per_page * current_page)].row_height
			changed = true
	
	if changed:
		update_table()

func _on_header_clicked(column: int) -> void:
	# Toggle sorting direction (ascending/descending)
	var sorting = E_Sorting.ASCENDING
	
	if has_meta("sort_column") and get_meta("sort_column") == column:
		if get_meta("sorting_state") == E_Sorting.ASCENDING:
			sorting = E_Sorting.DESCENDING
		else:
			sorting = E_Sorting.ASCENDING
	
	set_meta("sort_column", column)
	set_meta("sorting_state", sorting)
	
	sort_rows_by_column(column, sorting)

func _on_sorting_complete(sorted_rows: Array) -> void:
	
	#_rows.clear()
	#_rows = sorted_rows.duplicate()
	
	_sort_thread.wait_to_finish()
	_sort_thread = null
	
	_culling_active_rows_old.clear()
	
	_recalc_row_offsets_visibility()
	_refresh_last_visible_row()
	
	_create_h_separators()
	
	update_table()
	
	#last_selected_row = get_current_row()
	emit_signal("column_sort_finished", get_meta("sort_column"), get_meta("sorting_state"))

#-----------------------------------------Subclasses-----------------------------------------------#

class Sorter:
	var column: int
	var ascending: E_Sorting
	
	func _init(column: int, ascending: E_Sorting):
		self.column = column
		self.ascending = ascending
	
	func _sort(a, b):
		var node_a = a.nodes[column]
		var node_b = b.nodes[column]
		
		var text_a: String = node_a.text if node_a.text != null else ""
		var text_b: String = node_b.text if node_b.text != null else ""
		
		if ascending == E_Sorting.ASCENDING:
			return text_a.naturalcasecmp_to(text_b) < 0
			
		elif ascending == E_Sorting.DESCENDING:
			return text_a.naturalcasecmp_to(text_b) > 0
			
		else:
			push_error("sorting invalid: " + str(ascending))
			return

class RowContent:
	var nodes: Array[Control] = []
	var editable: Array[bool] = []
	
	var row_culling_rendered := false
	var row_visible := true
	var selected := false
	var deselect := false
	
	var row_height: int = 0
	var row_height_temp: int = 0
	
	var horizontal_seperator: HSeparator = null 
