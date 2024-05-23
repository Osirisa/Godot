@tool
extends Control
class_name TableNode

#Signals
##Signal when the user clicks on a cell
##Return:	Row:int, Column:int
signal cell_clicked(row:int, column:int)

##Signal when the user edits a cell
##Return:	Row:int, Column:int
signal cell_edited(row:int,column:int)

##Signal when a column sorting was requested
##Return:	Column:int, Ascending / Descending (true / false)
signal column_sort_finished(column: int, ascending: bool)	#TBD: swap out for enum? instead of bool

##Signal for stopping the thread and applying the sorted_rows to the normal rows - Array
signal sorting_complete(sorted_rows)

##The header Titles
@export var headers: Array = []: 
	set(value): 
		columns = value.size()
		if(value.size() > headers.size()):
			value[headers.size()] = "header"+ str(headers.size())
		
		headers = value
		
		if(headers.size()> cell_widths.size()):
			for i in range(headers.size() - cell_widths.size()):
				cell_widths.append(standard_cell_width)
			
		elif headers.size() < cell_widths.size():
			cell_widths = cell_widths.slice(0,headers.size())
		
		cell_widths = cell_widths
		
		_init_v_separators()
		_update_layout()
		notify_property_list_changed()

##The height of the header cells
@export var header_cell_height: float = 20.0:
	set(value):
		header_cell_height = value
		_update_layout()

##The width of the individual columns
@export var cell_widths: Array = []:
	set(value): 
		cell_widths = value
		
		cell_widths_temp.clear()
		cell_widths_temp = cell_widths.duplicate()
		
		_update_layout()

##The standart width of the individual columns to "spawn" with
@export var standard_cell_width: float = 150:
	set(value):
		standard_cell_width = value
		_update_layout()

##The standart height of the individual rows to "spawn" with
@export var standard_body_cell_height: float = 20:
	set(value):
		standard_body_cell_height = value
		_update_layout()

##Checkbox if resizing is allowed
@export var resizing = false:
	set(value):
		resizing = value
		_update_layout()

##Decides what the minimum size of each cell is (for resizing)
@export var min_size := Vector2(50,20)

##If not defined, it uses the theme applied to the Tablewidget or its parents
@export var header_theme: Theme

##If not defined, it uses the theme applied to the Tablewidget or its parents
@export var body_theme: Theme

##if a row gets selected, it uses a other theme applied. (if not defined...)
@export var selection_theme: Theme

##-------------------------------------------
#@export var debug := true
#
#var do_once:= true
##-------------------------------------------

const table_util = preload("res://addons/osirisas_ui_extension/table_node/table_utility.gd")

var columns: int

var rows :Array[RowContent]= []

var column_visiblity:Array[bool] =[]

var body_cell_heights := []
var body_cell_heights_temp := []

var cell_widths_temp := []

var separator_group : Control = Control.new()
var vertical_separators := []
var horizontal_separators := []

#groups for header and body
var header_group: Control = Control.new()
var body_group: Control = Control.new()

#panels
var panel_header: Panel = Panel.new()
var panel_body: Panel = Panel.new()

var sort_thread: Thread = null

#selections
var selected_rows: Array[RowContent] = []
var current_row	:RowContent = null
var last_selected_row := -1

func _enter_tree():
	pass # Replace with function body.

func _init():
	pass
	
func _ready():
	connect("sorting_complete",Callable(self, "_on_sorting_complete"))
	
	init_Table()
	_init_v_separators()
	_init_h_separators()
	_update_layout()
	queue_redraw()

#---------------------------Public methods-------------------------------------
## Adds a row to the table directly below the previous row can also called with no data, then it fills the row with empty labels
func add_row(data: Array[Control] = [], clip_text:bool = true, height: float = standard_body_cell_height) -> void:
	#print("Adding row with data: ", data)  # <- DEBUG:: Check what data is received
	var new_row := RowContent.new()
	var node: Control
	
	body_cell_heights.append(height)
	body_cell_heights_temp.append(height)
	rows.append(new_row)
	
	new_row.row_visible = true
	
	for i in columns:
		if i < data.size():
			node = data[i]
		else:
			node = Label.new()
			node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		var margin_parent = _create_margin_container(node, rows.size() - 1, i)
		
		if  node is LineEdit:
			#print(child.get_minimum_size())
			pass
		elif node is Label or Button:
			if clip_text:
				node.clip_text = true
		
		node.mouse_filter = Control.MOUSE_FILTER_PASS
		
		if body_theme:
			node.theme = body_theme
			margin_parent.theme = body_theme
		
		body_group.add_child(margin_parent)
		new_row.nodes.append(node)
		new_row.editable.append(true)
	
	_init_h_separators() # Updates the separators for the new row
	_update_layout()

#TBD:: insert_row(title,pos)

func add_header(title:String, cell_width := standard_cell_width):
	
	cell_widths.append(cell_width)
	cell_widths_temp.append(cell_width)
	
	headers.append(title)
	columns = headers.size()
	var margin_parent: MarginContainer
	var standard_label: Label
	
	for i in range(rows.size()):
		standard_label = Label.new()
		standard_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		margin_parent = _create_margin_container(standard_label, i, columns - 1)
		
		rows[i].nodes.append(standard_label)
		
		if body_theme:
			standard_label.theme = body_theme
			margin_parent.theme = body_theme
		
		margin_parent.visible = rows[i].row_visible
		rows[i].editable.append(true)
		
		body_group.add_child(margin_parent)
	
	_init_v_separators() # Updates the separators for the new row
	_update_layout()

#TBD:: insert_header(title,column_pos)
#TBD:: remove_header(column_pos)

func clear() -> void:
	for row in rows:
		for node in row.nodes:
			node.queue_free()
	
	rows.clear()
	
	_init_h_separators()
	_update_layout()

func get_row(row:int) -> Array:
	if not table_util.check_row_input(row, rows.size() - 1):
		return []
	
	var row_contens: Array = []
	for node in rows[row].nodes:
		row_contens.append(node)
	
	return row_contens

func get_cell(row:int, column:int) -> Control:
	#--check if row and column matches size of the arrays--
	if not table_util.check_row_input(row, rows.size() - 1):
		return Label.new()
	
	if not table_util.check_column_input(column, columns - 1):
		return Label.new()
	
	return rows[row].nodes[column]

func set_cell(node:Control,row:int, column:int, remain_clip_setting:bool = true) -> void:
	if not table_util.check_row_input(row, rows.size() - 1):
		return
	
	if not table_util.check_column_input(column, columns - 1):
		return
	
	var margin_parent: MarginContainer = rows[row].nodes[column].get_parent()
	var old_child = margin_parent.get_child(0)
	
	
	if node is LineEdit:
		if old_child is LineEdit:
			node.clip_contents = old_child.clip_contents
		else:
			node.clip_contents = old_child.clip_text
	elif (node is Button or Label) and remain_clip_setting:
		if old_child is LineEdit:
			node.clip_text = old_child.clip_contents
		else:
			node.clip_text = old_child.clip_text
	
	var callable_old = Callable(self,"_on_cell_gui_input").bind(rows[row], old_child)
	var callable_new = Callable(self,"_on_cell_gui_input").bind(rows[row], node)
	
	margin_parent.disconnect("gui_input",callable_old)	
	margin_parent.remove_child(old_child)
	
	margin_parent.connect("gui_input",callable_new)
	
	rows[row].nodes.remove_at(column)
	rows[row].nodes.insert(column,node)
	
	old_child.queue_free()
	margin_parent.add_child(node)
	_update_layout()

func set_row(data:Array[Control],row:int) -> void:
	if not table_util.check_row_input(row, rows.size() - 1):
		return
		
	for i in range(data.size()):
		set_cell(data[i],row,i)

func remove_row(row:int) -> void:
	if not table_util.check_row_input(row, rows.size() - 1):
		return
	
	selected_rows.erase(rows[row])
	
	if last_selected_row == row:
		last_selected_row = -1
	
	if current_row == rows[row]:
		current_row = null
	
	for node: Control in rows[row].nodes:
		node.queue_free()
	
	rows.remove_at(row)
	
	_init_h_separators()
	_update_layout()

func visibility_row(row:int,visible:bool) -> void:
	if not table_util.check_row_input(row, rows.size() - 1):
		return
	
	for node: Control in rows[row].nodes:
		node.visible = visible
	
	rows[row].row_visible = visible
	_update_layout()

func visibility_column(column:int, visible:bool) -> void:
	if not table_util.check_column_input(column, columns - 1):
		return
	
	var children = header_group.get_children()
	for child: MarginContainer in children:
		if(child.name.begins_with("Header_")):
			var index = int(child.name.substr(child.name.length() -1,1))
			if(column == index):
				if child.visible != visible:
					for row in rows:
						row.nodes[column].visible = visible
					child.visible = visible
		
	column_visiblity[column] = visible
	_update_layout()

func get_visibility_row(row:int) -> bool:
	return rows[row].row_visible

func get_visibility_column(column:int) -> bool:
	return column_visiblity[column]

#TBD:: set_editable_status_cell -> void:
#TBD:: get_editable_status_cell -> bool:

func sort_rows_by_column(column: int, ascending: bool) -> void:
	if not table_util.check_column_input(column, columns - 1):
		return
	
	sort_thread = Thread.new()
	var callable = Callable(self, "_sort_thread_function").bind([column, ascending])
	sort_thread.start(callable)

#TBD:: select row
#TBD:: select rows

func deselect_all_rows() -> void:
	selected_rows.clear()
	for row in rows:
		_update_row_selection_visuals(row)

func select_all_rows() -> void:
	for i in range(rows.size()):
		if selected_rows.find(rows[i]) == -1:
			selected_rows.append(rows[i])
			_update_row_selection_visuals(rows[i])

func get_current_row() -> int:
	return rows.find(current_row)

func get_selection_positions() -> Array[int]:
	var positions :Array[int]= []
	for row in selected_rows:
		positions.append(rows.find(row))
	positions.sort()
	return positions

func getSizeVecOfHeader() -> Vector2:
	var sizeVec: Vector2 = Vector2(0,0)
	for i in range(cell_widths_temp.size()):
		if header_group.get_child(i).visible:
			sizeVec.x += cell_widths_temp[i]
	
	sizeVec.y = header_cell_height
	return sizeVec

func getSizeVecOfBody() -> Vector2:
	var sizeVec: Vector2 = Vector2(0,0)
	for i in range(cell_widths_temp.size()):
		if header_group.get_child(i).visible:
			sizeVec.x += cell_widths_temp[i]
	for i in range(rows.size()):
		if rows[i].row_visible:
			sizeVec.y += body_cell_heights_temp[i]
		
	return sizeVec


#---------------------------Private methods-------------------------------------
func init_Table() -> void:
	
	panel_header.name = "HeaderPanel"
	if header_theme:
		panel_header.theme = header_theme
	add_child(panel_header)
	
	panel_body.name = "BodyPanel"
	if body_theme:
		panel_body.theme = body_theme
	add_child(panel_body)
	
	header_group.name = "HeaderGroup"
	if header_theme:
		header_group.theme = header_theme
	add_child(header_group)	
	
	body_group.name = "BodyGroup"
	if body_theme:
		body_group.theme = body_theme
	add_child(body_group)
	
	separator_group.name = "SeparatorGroup"
	add_child(separator_group)	


func _init_v_separators() -> void:
	for v_sep in vertical_separators:
		v_sep.queue_free()
	vertical_separators.clear()
		
	for i in range(columns):  # No separator after the last column
		var sep = VSeparator.new()
		sep.name = "VSep%d" % i
		sep.mouse_default_cursor_shape = Control.CURSOR_HSIZE
		#print("addchild")
		if is_instance_valid(separator_group):
			separator_group.add_child(sep)
			vertical_separators.append(sep)
			
		var callable = Callable(self, "_on_separator_input").bind(i,VSeparator)
		sep.connect("gui_input", callable)

func _init_h_separators() -> void:
	for sep in horizontal_separators:
		sep.queue_free()
	horizontal_separators.clear()
	
	for i in range(rows.size()):  # No separator after the last row
		var sep = HSeparator.new()
		sep.name = "HSep%d" % i
		sep.mouse_default_cursor_shape = Control.CURSOR_VSIZE
		#print("addchild")
		if is_instance_valid(separator_group):
			separator_group.add_child(sep)
			horizontal_separators.append(sep)
		var callable = Callable(self, "_on_separator_input").bind(i,HSeparator)
		sep.connect("gui_input", callable)

func _on_separator_input(event, index, type) -> void:
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_LEFT and resizing:
		# Adjust the column width based on mouse movement
		if type == VSeparator:
			cell_widths_temp[index] = max(min_size.x,cell_widths_temp[index] + event.relative.x)
			
		if type == HSeparator:
			body_cell_heights_temp[index] = max(min_size.y,body_cell_heights_temp[index] + event.relative.y)
		
		_update_layout() 
	
	if event is InputEventMouseButton and event.double_click:
		if type == VSeparator:
			cell_widths_temp[index] = cell_widths[index]
			
		if type == HSeparator:
			body_cell_heights_temp[index] = body_cell_heights[index]
		
		_update_layout() 

func _update_layout() -> void:
	_create_headers()  # Function to create header labels
	_update_headers()
	_layout_rows()     # Lays out the rows
	
	# Lay out the seperators
	_update_v_separators()
	_update_h_separators()
	
	_update_panels()
	
	# For all Containers as parents to update
	custom_minimum_size = Vector2(getSizeVecOfHeader().x, getSizeVecOfHeader().y + getSizeVecOfBody().y)
	minimum_size_changed.emit()
	
	# Redraws the whole widget for all changes to take immediate effect
	queue_redraw()

func _layout_rows() -> void:
	var yOffset = header_cell_height
	for j in range(rows.size()):
		if rows[j].row_visible:
			for i in range(rows[j].nodes.size()):
				
				var margin_parent:MarginContainer = rows[j].nodes[i].get_parent()
				if margin_parent:
					if margin_parent.visible:
						margin_parent.position = Vector2(get_x_offset(i), yOffset)
						margin_parent.custom_minimum_size = Vector2(cell_widths_temp[i],body_cell_heights_temp[j])
						margin_parent.minimum_size_changed.emit()
						margin_parent.set_size(Vector2(cell_widths_temp[i],body_cell_heights_temp[j]))
			
			yOffset += body_cell_heights_temp[j]

func _update_panels() -> void:
	panel_header.set_size(getSizeVecOfHeader())
	
	panel_body.set_position(Vector2(0,getSizeVecOfHeader().y))
	panel_body.set_size(getSizeVecOfBody())

func get_x_offset(col_index:int) -> float:
	var offset = 0.0
	
	for i in range (col_index):
		if header_group.get_child(i).visible:
			offset += cell_widths_temp[i]
	
	return offset

func _update_v_separators() -> void:
	#needs a litle offset for it to look good here: -2.5px
	var pos = -2.5
	
	for i in range(vertical_separators.size()):
		if header_group.get_child(i).visible:
			pos += cell_widths_temp[i]
			vertical_separators[i].position = Vector2(pos, 0)
			vertical_separators[i].set_size(Vector2(1, get_total_height()))
			vertical_separators[i].visible = true
		else:
			vertical_separators[i].visible = false

func _update_h_separators() -> void:	
	var pos = 0.0
	
	#needs a litle offset for it to look good here: -2px
	var y_offset = getSizeVecOfHeader().y - 2
	
	for i in range (horizontal_separators.size()):
		if rows[i].row_visible:
			pos += body_cell_heights_temp[i]
			horizontal_separators[i].position = Vector2(0, y_offset + pos)
			horizontal_separators[i].set_size(Vector2(getSizeVecOfHeader().x, 1))
			horizontal_separators[i].visible = true
		else:
			horizontal_separators[i].visible = false

func get_total_height() -> float:
	var total_body_height = getSizeVecOfBody().y
	return total_body_height + header_cell_height

# Optionally, you might want to trigger layout updates manually or under specific conditions
func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		_update_layout()  # Update layout when the widget's visibility changes

func _create_headers() -> void:
	if !header_group:
		return
	var children = header_group.get_children()
	var createdIndexes := []
	for child in children:
		if(child.name.begins_with("Header_")):
			createdIndexes.append(int(child.name.substr(child.name.length() -1,1)))
	for i in range(headers.size()):
		if createdIndexes.has(i):
			continue
		if headers[i]:
			var margin_container = MarginContainer.new()
			var header = Button.new()
			
			column_visiblity.append(true)
			
			margin_container.name = "Header_" + str(i)
			header.text = headers[i]
			margin_container.custom_minimum_size = Vector2(cell_widths_temp[i], header_cell_height)
			margin_container.position = Vector2(get_x_offset(i), 0)
			header.clip_text = true
			
			var callable = Callable(self, "_on_header_clicked").bind(i)
			header.connect("pressed", callable)
			
			margin_container.add_child(header)
			header_group.add_child(margin_container)

func _update_headers() -> void:
	if !header_group:
		return
	var children = header_group.get_children()
	for child in children:
		if(child.name.begins_with("Header_")):
			var index = int(child.name.substr(child.name.length() -1, 1))
			if(headers.size() > index):
				child.get_child(0).text = headers[index]
				child.custom_minimum_size = Vector2(cell_widths_temp[index], header_cell_height)
				child.minimum_size_changed
				child.set_size(Vector2(cell_widths_temp[index], header_cell_height))
				child.position = Vector2(get_x_offset(index), 0)
				
			else :
				child.queue_free()

func _get_minimum_size() -> Vector2:
	# Calculate the minimum width based on the number of columns and cell size
	var min_size = Vector2(0,0)
	
	min_size = getSizeVecOfHeader()
	min_size.y += getSizeVecOfBody().y

	return min_size

#------------------------------------SLOTS------------------------------------#
func _on_header_clicked(column: int) -> void:
	# Toggle sorting direction (ascending/descending)
	var ascending = true
	if has_meta("sort_column") and get_meta("sort_column") == column:
		ascending = not get_meta("sort_ascending")
	
	set_meta("sort_column", column)
	set_meta("sort_ascending", ascending)
	
	sort_rows_by_column(column, ascending)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		deselect_all_rows()
	elif event.is_action_pressed("ui_text_select_all"):
		select_all_rows()

func _on_cell_gui_input(event: InputEvent,row_c: RowContent, node: Control) -> void:
	var row = rows.find(row_c)
	var column = row_c.nodes.find(node)
	
	if event is InputEventMouseButton and event.double_click:
		_edit_cell(row,column)
		#print("doubleclick")
	if event is InputEventMouseButton and event.pressed and event.button_mask & MOUSE_BUTTON_LEFT:
		emit_signal("cell_clicked",row,column)
		
	if event is InputEventMouseButton and event.pressed and event.button_mask & MOUSE_BUTTON_LEFT:
		if Input.is_key_pressed(KEY_SHIFT):
			_select_multiple_rows(row)
		elif Input.is_key_pressed(KEY_CTRL):
			_toggle_row_selection(row)
		else:
			_select_single_row(row)

func _select_single_row(row: int) -> void:
	deselect_all_rows()
	selected_rows.append(rows[row])
	current_row = rows[row]
	last_selected_row = row
	_update_row_selection_visuals(rows[row])

func _toggle_row_selection(row: int) -> void:
	var array_pos = selected_rows.find(rows[row])
	if array_pos == -1:
		selected_rows.append(rows[row])
		last_selected_row = row
	else:
		selected_rows.remove_at(array_pos)
	
	current_row = rows[row]
	_update_row_selection_visuals(rows[row])

func _select_multiple_rows(row: int) -> void:
	if last_selected_row == -1:
		_select_single_row(row)
		return
	
	var start = min(last_selected_row, row)
	var end = max(last_selected_row, row)
	
	for i in range(start, end + 1):
		if selected_rows.find(rows[i]) == -1:
			selected_rows.append(rows[i])
			_update_row_selection_visuals(rows[i])
	
	current_row = rows[row]

func _update_row_selection_visuals(row: RowContent) -> void:
	if selected_rows.find(row) >= 0:
		for node in row.nodes:
			if selection_theme:
				node.get_parent().theme = selection_theme
				node.theme = selection_theme
	else:
		for node in row.nodes:
			if body_theme:
				node.get_parent().theme = body_theme
				node.theme = body_theme
			else:
				node.theme.clear()
				node.get_parent().theme = body_theme

func _edit_cell(row:int, column:int) -> void:
	var cell = get_cell(row,column)
	if cell is Label:
		var line_edit = LineEdit.new()
		
		line_edit.clip_contents = cell.clip_text
		line_edit.alignment = cell.horizontal_alignment
		
		var original_text = cell.text
		line_edit.text = cell.text
		line_edit.select_all()
		
		var callable_enter = Callable(self,"_on_edit_text_entered").bind(row, column, line_edit)
		line_edit.connect("text_submitted", callable_enter)
		
		var callable_cancel = Callable(self,"_on_edit_input_event").bind(row, column, original_text, line_edit)
		line_edit.connect("gui_input", callable_cancel)
		
		var callable_move_on = Callable(self,"_on_edit_text_focus_lost").bind(row, column, line_edit)
		line_edit.connect("focus_exited", callable_move_on)
		
		set_cell(line_edit,row,column)
		line_edit.grab_focus()

func _on_edit_text_entered(new_text:String, row:int, column:int, line_edit:LineEdit) -> void:
	line_edit.set_block_signals(true)
	_commit_text(line_edit,line_edit.text, row, column)

func _on_edit_text_focus_lost(row:int, column:int, line_edit:LineEdit) -> void:
	line_edit.set_block_signals(true)
	_commit_text(line_edit,line_edit.text, row, column)

func _on_edit_input_event(event:InputEvent, row:int, column:int, original_text:String, line_edit:LineEdit) -> void:
	if event.is_action_pressed("ui_cancel"):
		line_edit.set_block_signals(true)
		_commit_text(line_edit, original_text, row, column)

func _commit_text(line_edit:LineEdit, new_text:String, row:int, column:int) -> void:	
	var label := Label.new()
	label.text = new_text
	label.clip_text = line_edit.clip_contents
	label.horizontal_alignment = line_edit.alignment
	
	set_cell(label, row, column)
	emit_signal("cell_edited")

func _create_margin_container(node: Control, row_index: int, col_index:int) -> MarginContainer:
	
	
	
	var margin_parent = MarginContainer.new()
	margin_parent.add_child(node)
	margin_parent.custom_minimum_size = Vector2(cell_widths_temp[col_index], body_cell_heights_temp[row_index])
	
	var callable = Callable(self, "_on_cell_gui_input").bind(rows[row_index], node)
	margin_parent.connect("gui_input", callable)
	
	if body_theme:
		margin_parent.theme = body_theme
		
	return margin_parent

func _sort_thread_function(args: Array) -> void:
	var column = args[0]
	var ascending = args[1]
	
	var sorted_rows = rows.duplicate()
	
	var sorter = Sorter.new(column, ascending)
	sorted_rows.sort_custom(sorter._sort)
	
	#var callable = Callable(self, "sorting_complete").bind(sorted_rows)
	call_deferred("emit_signal", "sorting_complete",sorted_rows)

func _on_sorting_complete(sorted_rows: Array) -> void:
	rows.clear()
	rows = sorted_rows
	
	sort_thread.wait_to_finish()
	sort_thread = null
	
	_update_layout()
	last_selected_row = get_current_row()
	emit_signal("column_sort_finished", get_meta("sort_column"), get_meta("sort_ascending"))

class Sorter:
	var column: int
	var ascending: bool
	
	func _init(column: int, ascending: bool):
		self.column = column
		self.ascending = ascending
	
	func _sort(a, b):
		var node_a = a.nodes[column]
		var node_b = b.nodes[column]
		
		var text_a:String = node_a.text if node_a.text != null else ""
		var text_b:String = node_b.text if node_b.text != null else ""
		
		if ascending:
			return text_a.naturalcasecmp_to(text_b) < 0
		else:
			return text_a.naturalcasecmp_to(text_b) > 0

class RowContent:
	var nodes :Array[Control] = []
	var row_visible := true
	var editable: Array[bool] = []
