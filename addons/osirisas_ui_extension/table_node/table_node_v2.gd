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
		column_count = header_titles.size()

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
		
		max_pages = int(row_count / max_row_count_per_page)
		
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

## The current column count (incl. hidden colummns)
var column_count: int = 0
## The current row count (incl. hidden rows)
var row_count: int = 0

## How many pages there are in total (DO NOT SET!)
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
		
		_refresh_y_offsets_arr()
		
		_clr_body.call_deferred()
		_create_h_separators.call_deferred()
		_update_h_separators.call_deferred()
		_update_v_separators.call_deferred()
		_update_visible_rows.call_deferred()

#-----------------------------------------Private Var----------------------------------------------#

# Utility Class
var _table_util := preload("res://addons/osirisas_ui_extension/table_node/table_utility.gd")

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
	
	_scroll_container.get_v_scroll_bar().connect("value_changed", Callable(self,"_update_visible_rows"))
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

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		deselect_all_rows()
	elif event.is_action_pressed("ui_text_select_all"):
		select_all_rows()
#-----------------------------------------Virtual methods------------------------------------------#

#-----------------------------------------Public methods-------------------------------------------#

#region Header Edit -------------

func add_column(title: String, cell_width := standard_cell_dimension.x, column_visiblity := true) -> void:

	column_widths.append(cell_width)
	_column_widths_temp.append(cell_width)
	_column_visiblity.append(column_visiblity)
	
	column_count += 1

	header_titles.append(title)
	
	_refresh_x_offsets_arr()
	
	_create_headers.call_deferred()
	_create_v_separators.call_deferred()
	_update_v_separators.call_deferred()
	_update_visible_rows.call_deferred()

func insert_column(title, column_pos, cell_width := standard_cell_dimension.x, column_visiblity := true):
	if not _table_util.check_column_input(column_pos, column_count-1):
		return

	column_widths.insert(column_pos, cell_width)
	_column_widths_temp.insert(column_pos, cell_width)
	
	_column_visiblity.insert(column_pos, column_visiblity)
	
	column_count += 1
	
	header_titles.insert(column_pos, title)

	for i in row_count:
		var row = _rows[i]
		var standard_label = Label.new()

		standard_label.name = "std_label_%d" % row.nodes.size()
		standard_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		row.nodes.insert(column_pos, standard_label)
		row.editable.insert(column_pos, true)
	
	_refresh_x_offsets_arr()
	
	_create_headers.call_deferred()
	_create_v_separators.call_deferred()
	_update_v_separators.call_deferred()
	_update_visible_rows.call_deferred()

func remove_column(column_pos):
	if not _table_util.check_column_input(column_pos, column_count-1):
		return

	column_widths.remove_at(column_pos)
	_column_widths_temp.remove_at(column_pos)
	
	_column_visiblity.remove_at(column_pos)
	
	column_count = column_count - 1 if column_count > 0 else 0 
	
	header_titles.remove_at(column_pos)

	for i in row_count:
		var row = _rows[i]

		row.nodes.remove_at(column_pos)
		row.editable.remove_at(column_pos)
	
	_refresh_x_offsets_arr()
	
	_create_headers.call_deferred()
	_create_v_separators.call_deferred()
	_update_v_separators.call_deferred()
	_update_visible_rows.call_deferred()

#endregion

#region Row Edit ----------------

## Adds a row to the table directly below the previous row can also called with no data, then it fills the row with empty labels
func add_row(data: Array[Control] = [], clip_text: bool = true, height: float = standard_cell_dimension.y) -> void:

	if data.size() > column_count:
		push_warning("data array input bigger then column count, excess nodes wont be shown!")
	
	var new_row := RowContent.new()
	
	new_row.nodes = data
	new_row.row_visible = true
	new_row.row_height = height
	new_row.row_height_temp = height
	
	_rows.append(new_row)
	
	row_count += 1
	
	#pagniation
	max_pages = int(row_count / (max_row_count_per_page + 1))
	
	_refresh_y_offsets_arr()
	_update_body_size()
	
	_create_h_separators.call_deferred()
	_update_h_separators.call_deferred()
	_update_visible_rows.call_deferred()


#TBD:: insert_row(title,pos)

## Takes in following template: [ [node:Control, node2:Control],[nod...,...]...] as data use this
## for populating the table with data
## Use this for heavy table filling, as it wont update the visible rows until its finished loading the data
func add_rows_batch(data :Array, clip_text: bool = true, height: float = standard_cell_dimension.y) -> void:

	for d in data:
		var new_row := RowContent.new()
		
		new_row.row_visible = true
		
		for node in d:
			new_row.nodes.append(node)
			new_row.editable.append(true)
			new_row.row_height = height
			new_row.row_height_temp = height
			
		_rows.append(new_row)
		row_count += 1
	
	max_pages = int(row_count / (max_row_count_per_page + 1))
	
	_refresh_y_offsets_arr()
	_update_body_size()
	
	_create_h_separators.call_deferred()
	_update_h_separators.call_deferred()
	_update_visible_rows.call_deferred()

## Overrides the row from the Table 
func set_row(data: Array[Control], row: int, clip_text: bool = true, height: float = standard_cell_dimension.y) -> void:
	if not _table_util.check_row_input(row, row_count - 1):
		return

	if data.size() > column_count:
		push_warning("data array input bigger then column count, excess nodes wont be shown!")
	
	var edited_row := _rows[row]
	
	edited_row.nodes = data
	edited_row.row_visible = true
	edited_row.row_height = height
	edited_row.row_height_temp = height
	
	_refresh_y_offsets_arr()
	_update_body_size()
	
	_create_h_separators.call_deferred()
	_update_h_separators.call_deferred()
	_update_visible_rows.call_deferred()

## Removes the row from the Table
func remove_row(row: int) -> void:
	if not _table_util.check_row_input(row, row_count - 1):
		return

	_rows.remove_at(row)

	row_count = row_count - 1 if row_count > 0 else 0
	max_pages = int(row_count / (max_row_count_per_page + 1))

	if (current_page > max_pages) and pagination:
		current_page = current_page
	else:
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
		_rows.remove_at(rows_to_remove[index])
		row_count = row_count - 1 if row_count > 0 else 0
	
	max_pages = int(row_count / (max_row_count_per_page + 1))

	if (current_page > max_pages) and pagination:
		current_page = current_page
	else:
		_refresh_y_offsets_arr()

		_create_h_separators.call_deferred()
		_update_h_separators.call_deferred()
		_update_v_separators.call_deferred()
		_update_visible_rows.call_deferred()	

	_update_body_size()

#endregion

#region Table Edit --------------

## Clears the whole Table
func clear() -> void:
	_rows.clear()
	header_titles.clear()

	row_count = 0
	column_count = 0

	max_pages = 0
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

func sort_rows_by_column(column: int, sort: E_Sorting) -> void:
	if not _table_util.check_column_input(column, column_count - 1):
		return
	
	_sort_thread = Thread.new()
	var callable = Callable(self, "_sort_thread_function").bind([column, sort])
	_sort_thread.start(callable)

#endregion

#region Selection ---------------

#TBD:: select row
#TBD:: select rows

## Selects all rows
func select_all_rows() -> void:
	for row in _rows:

		if _selected_rows.find(row) == -1:
			_selected_rows.append(row)
			_update_row_selection_visuals(row)

func deselect_all_rows() -> void:

	if _selected_rows.is_empty():
		return

	_selected_rows.clear()
	for row in _rows:
		_update_row_selection_visuals(row)

func has_selection() -> bool:
	if _selected_rows.size() > 0:
		return true
	else:
		return false

func get_current_row() -> int:
	return _rows.find(_current_row)

## Returns the positions of the Rows that got selected
func get_selection_positions() -> Array[int]:
	var positions :Array[int]= []
	for row in _selected_rows:
		positions.append(_rows.find(row))
	positions.sort()
	return positions

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
		var header_btn := Button.new()
		var header_margin_container := MarginContainer.new()
		
		header_btn.text = header_titles[i]
		header_btn.clip_text = true
		header_btn.clip_contents = true
		
		var callable = Callable(self, "_on_header_clicked").bind(header_margin_container)
		header_btn.connect("pressed", callable)

		header_margin_container.add_child(header_btn)
		header_margin_container.position = Vector2i(_x_offsets[i], 0)
		header_margin_container.size = Vector2i(column_widths[i], header_cell_height)
		header_margin_container.custom_minimum_size = Vector2i(column_widths[i], header_cell_height)
		
		_header_cell_group.add_child(header_margin_container)

func _update_headers() -> void:
	var children = _header_cell_group.get_children()

	for idx in children.size():
		children[idx].position = Vector2i(_x_offsets[idx], 0)
		children[idx].size = Vector2i(_column_widths_temp[idx], header_cell_height)
		children[idx].custom_minimum_size = Vector2i(_column_widths_temp[idx], header_cell_height)

func _scroll_header_horizontally(value):
	print(value)
	_header_group.position.x = -value

## Main function for inserting and visualizing the nodes
func _update_visible_rows(value = 0) -> void:
	var start_index: int = 0
	var end_index: int = row_count
	
	if value == 0:
		value = _scroll_container.get_v_scroll_bar().value
		
	for i in range(_y_offsets.size()):
		if _y_offsets[i] >= value:
			start_index = i - 1 if i > 0 else 0
			break 
	
	if pagination:
		var page_start: int = current_page * max_row_count_per_page
		var page_end: int = page_start + max_row_count_per_page
		
		if row_culling:
			start_index = max(start_index, page_start)
			end_index = min(start_index + max_row_count_active_culling, page_end)
			
		else :
			start_index = page_start
			end_index = page_end
		
	elif row_culling:
		end_index = min(start_index + max_row_count_active_culling, row_count)
	
	start_index = clampi(start_index, 0, row_count)
	end_index = clampi(end_index, 0, row_count)
	
	if row_culling:
		_clr_body()
	
	for i in range(start_index, end_index):
		if _rows[i].row_visible:
			for x in range(column_count):
				var nodes = _rows[i].nodes
				var node

				if nodes.size() > x:
					node = nodes[x]
				else:
					node = Label.new()
					node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

				if !(node.get_parent() is MarginContainer):
					_set_properties(node)
					var margin_parent = _create_margin_container(node, i, x)
					_body_cell_group.add_child(margin_parent)
				
				
		else:
			end_index = clampi(end_index + 1, 0, row_count)

func _set_properties(node: Control) -> void:
	if node is LineEdit:
		node.clip_contents = true
	elif node is Button or Label:
		node.clip_text = true
		node.clip_contents = true

func _clr_body() -> void:
	for child in _body_cell_group.get_children():
			child.remove_child(child.get_child(0))
			_body_cell_group.remove_child(child)
			child.queue_free()

func _table_size() -> Vector2i:
	
	var table_size := Vector2i(0,0)

	if not _x_offsets.size() > 0:
		return table_size 

	table_size.x = _x_offsets.back() + _column_widths_temp.back()

	if not _y_offsets.size() > 0:
		return table_size 

	if pagination:
		var last_pos = clampi((max_row_count_per_page * (current_page + 1)) - 1, 0, row_count - 1)
		table_size.y = _y_offsets[last_pos] + _rows[last_pos].row_height_temp + 8
	else:
		table_size.y = _y_offsets.back() + _rows.back().row_height_temp + 8

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
	
	var start_index: int = 0
	var end_index: int = row_count
	
	if pagination:
		end_index = max_row_count_per_page
		
		if max_row_count_per_page * (current_page + 1) > row_count:
			end_index = row_count - (max_row_count_per_page * current_page)
	
	clampi(start_index, 0, row_count)
	clampi(end_index, 0, row_count)
	
	for i in range(start_index, end_index):  # No separator after the last row
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
	for v_sep in _vertical_separators:
		v_sep.queue_free()
	_vertical_separators.clear()

	for head_sep in _header_separators:
		head_sep.queue_free()
	_header_separators.clear()

		
	for i in range(column_count):  # No separator after the last column
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
	
	if not _rows.size() > 0:
		return
	
	for i in range (_horizontal_separators.size()):
		index = i
		
		if pagination:
			index += (max_row_count_per_page * current_page)
			index = clampi(index, 0, row_count - 1)
		
		if _rows[index].row_visible:
			pos += _rows[index].row_height_temp
			
			_horizontal_separators[i].position = Vector2(0, pos)
			_horizontal_separators[i].visible = true
			_horizontal_separators[i].set_size(Vector2(_x_offsets.back() + _column_widths_temp.back(), 1))
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

				if row_count > 0:
					if pagination:
						var index: int = (max_row_count_per_page * (current_page + 1)) - 1
						var rows_index := index

						if index > row_count:
							index = row_count - (max_row_count_per_page * current_page) - 1
							rows_index = row_count - 1
						
						#print(row_count)
						#print(index)

						_vertical_separators[i].set_size(Vector2(1, _y_offsets[index] + _rows[rows_index].row_height_temp))
					else:
						_vertical_separators[i].set_size(Vector2(1, _y_offsets.back() + _rows.back().row_height_temp))
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

	for i in range (column_count):
		offsets.append(0)
		
		for x in range (i):
			if _column_visiblity[x]:
				offsets[i] += _column_widths_temp[x]
	
	_x_offsets = offsets.duplicate()

func _refresh_y_offsets_arr() -> void:
	_y_offsets.clear()
	
	var offsets := []
	var start: int
	var end: int
	
	offsets.resize(row_count)
	offsets.fill(0)
	
	if pagination:
		start = clampi(max_row_count_per_page * current_page, 0, row_count)
		end = clampi(max_row_count_per_page * (current_page + 1), 0, row_count)
	else:
		start = 0
		end = row_count
	
	for i in range(start, end):
		
		for x in range (start, i):
			if _rows[i].row_visible:
				offsets[i] += _rows[x].row_height_temp
	
	_y_offsets = offsets.duplicate()


func _sort_thread_function(args: Array) -> void:
	var column = args[0]
	var ascending: E_Sorting = args[1]
	
	var sorted_rows = _rows.duplicate()
	
	var sorter = Sorter.new(column, ascending)
	sorted_rows.sort_custom(sorter._sort)

	call_deferred("emit_signal", "_c_sort_finished", sorted_rows)

func _select_single_row(row: int) -> void:
	deselect_all_rows()

	var curr_row = _rows[row]

	_selected_rows.append(curr_row)
	_current_row = curr_row
	_last_selected_row = row
	_update_row_selection_visuals(curr_row)

func _toggle_row_selection(row: int) -> void:

	var curr_row = _rows[row]
	var array_pos = _selected_rows.find(curr_row)

	if array_pos == -1:
		_selected_rows.append(curr_row)
		_last_selected_row = row
	else:
		_selected_rows.remove_at(array_pos)
	
	_current_row = curr_row
	_update_row_selection_visuals(curr_row)

func _select_multiple_rows(row: int) -> void:

	if _last_selected_row == -1:
		_select_single_row(row)
		return
	
	var curr_row = _rows[row]
	var start = min(_last_selected_row, row)
	var end = max(_last_selected_row, row)
	
	for i in range(start, end + 1):
		if _selected_rows.find(curr_row) == -1:
			_selected_rows.append(curr_row)
			_update_row_selection_visuals(curr_row)
	
	_current_row = curr_row

#<--------------------------|Slots|------------------------------>#

func _on_cell_gui_input(event: InputEvent,row_c: RowContent, node: Control) -> void:
	var row = _rows.find(row_c)
	var column = row_c.nodes.find(node)
	
	if event is InputEventMouseButton and event.double_click:
		#_edit_cell(row,column)
		#print("doubleclick")
		pass
	if event is InputEventMouseButton and event.pressed and event.button_mask & MOUSE_BUTTON_LEFT:
		emit_signal("cell_clicked",row,column)
		
	if event is InputEventMouseButton and event.pressed and event.button_mask & MOUSE_BUTTON_LEFT:
		if Input.is_key_pressed(KEY_SHIFT):
			_select_multiple_rows(row)
		elif Input.is_key_pressed(KEY_CTRL):
			_toggle_row_selection(row)
		else:
			_select_single_row(row)

func _on_separator_input(event, index, type) -> void:
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_LEFT and resizing:
		# Adjust the column width based on mouse movement
		if type == VSeparator:
			_column_widths_temp[index] = max(min_size.x, _column_widths_temp[index] + int(event.relative.x))
			
		if type == HSeparator:
			_rows[index + (max_row_count_per_page * current_page)].row_height_temp = max(min_size.y, _rows[index + (max_row_count_per_page * current_page)].row_height_temp + event.relative.y)
		
	if event is InputEventMouseButton and event.double_click:
		if type == VSeparator:
			_column_widths_temp[index] = column_widths[index]
			
		if type == HSeparator:
			_rows[index].row_height_temp = _rows[index].row_height
		
	update_table()

func _on_header_clicked(column_btn: Control) -> void:
	# Toggle sorting direction (ascending/descending)
	var column: int = _header_cell_group.get_children().find(column_btn)
	var ascending = E_Sorting.ASCENDING

	if has_meta("sort_column") and get_meta("sort_column") == column:
		ascending = not get_meta("sort_ascending")
	
	set_meta("sort_column", column)
	set_meta("sort_ascending", ascending)
	
	sort_rows_by_column(column, ascending)

func _on_sorting_complete(sorted_rows: Array) -> void:
	
	_rows.clear()
	_rows = sorted_rows.duplicate()

	_sort_thread.wait_to_finish()
	_sort_thread = null

	update_table()

	#last_selected_row = get_current_row()
	emit_signal("column_sort_finished", get_meta("sort_column"), get_meta("sort_ascending"))

func _update_row_selection_visuals(row: RowContent) -> void:

	if _selected_rows.find(row) >= 0:
		for node in row.nodes:
			if selection_theme:
				node.get_parent().theme = selection_theme
				node.theme = selection_theme
	else:
		for node in row.nodes:
			var parent = node.get_parent()
			
			print(node)
			print(parent)

			if body_theme:
				parent.theme = body_theme
				node.theme = body_theme
			else:
				if node.theme:
					node.theme.clear()

				if parent.theme:
					parent.theme.clear()

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
	var row_visible := true
	var editable: Array[bool] = []
	
	var row_height: int = 0
	var row_height_temp: int = 0
