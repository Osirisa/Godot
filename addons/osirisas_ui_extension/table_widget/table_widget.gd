@tool
extends Control
class_name TableWidget

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
		
		init_v_separators()
		update_layout()
		notify_property_list_changed()

##The height of the header cells
@export var header_cell_height: float = 20.0:
	set(value):
		header_cell_height = value
		update_layout()

##The width of the individual columns
@export var cell_widths: Array = []:
	set(value): 
		cell_widths = value
		update_layout()

##The standart width of the individual columns to "spawn" with
@export var standard_cell_width: float = 150:
	set(value):
		standard_cell_width = value
		update_layout()

##The standart height of the individual rows to "spawn" with
@export var standard_body_cell_height: float = 20:
	set(value):
		standard_body_cell_height = value
		update_layout()

##Checkbox if resizing is allowed
@export var resizing = false:
	set(value):
		resizing = value
		update_layout()



var columns: int
var rows :Array[Array]= []

var body_cell_heights:= []

var separator_group : Control = Control.new()
var vertical_separators := []
var horizontal_separators := []

#groups for header and body
var header_group: Control = Control.new()
var body_group: Control = Control.new()

#panels
var panel_header: Panel = Panel.new()
var panel_body: Panel = Panel.new()

##If not defined, it uses the theme applied to the Tablewidget or its parents
@export var header_theme: Theme
##If not defined, it uses the theme applied to the Tablewidget or its parents
@export var body_theme: Theme

func _enter_tree():
	pass # Replace with function body.

func _init():
	pass
	
func _ready():
	init_Table()
	init_v_separators()
	update_layout()
	queue_redraw()

#---------------------------Public methods-------------------------------------
## Adds a row to the table directly below the previous row can also called with no data, then it fills the row with empty labels
func add_row(data: Array[Control] = [], clip_text:bool = true, height: float = standard_body_cell_height) -> void:
	#print("Adding row with data: ", data)  # <- DEBUG:: Check what data is received
	var row = []
	body_cell_heights.append(height)
	var widget
	for i in columns:
		if i < data.size():
			widget = data[i]
		else:
			widget = Label.new()
			widget.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		var margin_parent = MarginContainer.new()
		
		if  widget is LineEdit:
			#print(child.get_minimum_size())
			pass
		elif widget is Label or Button:
			if clip_text:
				widget.clip_text = true
		
		if body_theme:
			widget.theme = body_theme
			margin_parent.theme = body_theme
		
		margin_parent.add_child(widget)
		
		#print("Label text set to: ", label.text)  # <- DEBUG:: Verify label text
		margin_parent.custom_minimum_size = Vector2(cell_widths[i], body_cell_heights[rows.size()])
		
		body_group.add_child(margin_parent)
		row.append(margin_parent)

	rows.append(row)
	#print("Current rows: ", rows)  # <- DEBUG:: Verify rows content 
	
	init_h_seperators() # Updates the separators for the new row
	update_layout()

func clear() -> void:
	for row in rows:
		for cell in row:
			cell.queue_free()
	rows.clear()
	init_h_seperators()
	update_layout()

func get_row(row:int) -> Array:
	var row_contens: Array = []
	for i in rows[row]:
		row_contens.append(i.get_child(0))
	
	return row_contens

func get_cell(row:int, column:int) -> Control:
	return rows[row][column].get_child(0)

func set_cell(node:Control,row:int, column:int, remain_clip_setting:bool = true) -> void:
	var new_val = MarginContainer.new()
	
	if node is LineEdit:
		pass
	elif node is Button or Label:
		if remain_clip_setting:
			node.clip_text = rows[row][column].get_child(0).clip_text
	#var w:=[]
	
	new_val.theme = body_theme
	new_val.add_child(node)
	new_val.custom_minimum_size = Vector2(cell_widths[column], body_cell_heights[row])
	
	
	rows[row][column].queue_free()
	rows[row].remove_at(column)
	body_group.add_child(new_val)
	rows[row].insert(column,new_val)
	update_layout()

func set_row(data:Array[Control],row:int) -> void:
	for i in range(data.size()):
		set_cell(data[i],row,i)
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


func init_v_separators() -> void:
	for v_sep in vertical_separators:
		v_sep.queue_free()
	vertical_separators.clear()
		
	for i in range(columns - 1):  # No separator after the last column
		var sep = VSeparator.new()
		sep.name = "VSep%d" % i
		sep.mouse_default_cursor_shape = Control.CURSOR_HSIZE
		#print("addchild")
		if is_instance_valid(separator_group):
			separator_group.add_child(sep)
			vertical_separators.append(sep)
			
		var callable = Callable(self, "_on_separator_input").bind(i,VSeparator)
		sep.connect("gui_input", callable)

func init_h_seperators() -> void:
	for sep in horizontal_separators:
		sep.queue_free()
	horizontal_separators.clear()
	
	for i in range(rows.size()):  # No separator after the last column
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
	
	#if event is InputEventMouseMotion:
		#if type == VSeparator:
			#mouse_default_cursor_shape = Control.CURSOR_HSIZE
		#if type == HSeparator:
			#mouse_default_cursor_shape = Control.CURSOR_VSIZE
			
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_LEFT and resizing:
		# Adjust the column width based on mouse movement
		if type == VSeparator:
			cell_widths[index] = max(10,cell_widths[index] + event.relative.x)
			
		if type == HSeparator:
			body_cell_heights[index] = max(10,body_cell_heights[index] + event.relative.y)
		update_layout()  # Redraw layout with new widths

func update_layout() -> void:
	create_headers()  # Function to create header labels
	update_headers()
	layout_rows()     # Lays out the rows
	
	# Lay out the seperators
	update_v_separators()
	update_h_separators()
	
	update_panels()
	
	# For all Containers as parents to update
	custom_minimum_size = Vector2(getSizeVecOfHeader().x, getSizeVecOfHeader().y + getSizeVecOfBody().y)
	minimum_size_changed.emit()
	
	# Redraws the whole widget for all changes to take immediate effect
	queue_redraw()

func layout_rows() -> void:
	var yOffset = header_cell_height
	for j in range(rows.size()):
		for i in range(rows[j].size()):
			var margin_parent:MarginContainer = rows[j][i]
			#var child = margin_parent.get_child(0)
			
			#var child = LineEdit.new()
			margin_parent.position = Vector2(get_x_offset(i), yOffset)
			margin_parent.custom_minimum_size = Vector2(cell_widths[i],body_cell_heights[j])
			margin_parent.minimum_size_changed.emit()
			margin_parent.set_size(Vector2(cell_widths[i],body_cell_heights[j]))
			
			#add_child(child)
		yOffset += body_cell_heights[j]
func update_panels() -> void:
	panel_header.set_size(getSizeVecOfHeader())
	
	panel_body.set_position(Vector2(0,getSizeVecOfHeader().y))
	panel_body.set_size(getSizeVecOfBody())

func get_x_offset(col_index:int) -> float:
	var offset = 0.0
	for i in range (col_index):
		offset += cell_widths[i]
	return offset

func update_v_separators() -> void:
	var pos = -2.5
	
	#TBD:: ???
	#var x_offset = -margin.x
	#x_offset = 0.0 #<- debug
	
	for i in range(vertical_separators.size()):
		pos+=cell_widths[i]
		vertical_separators[i].position = Vector2(pos,0)
		vertical_separators[i].set_size(Vector2(1,get_total_height()))

func update_h_separators() -> void:
	var pos = 0.0
	var y_offset = getSizeVecOfHeader().y - 2
	
	for i in range (horizontal_separators.size()):
		pos += body_cell_heights[i]
		horizontal_separators[i].position = Vector2(0, y_offset + pos)
		horizontal_separators[i].set_size(Vector2(getSizeVecOfHeader().x, 1))

func get_total_height() -> float:
	var total_body_height = getSizeVecOfBody().y
	return total_body_height + header_cell_height

# Optionally, you might want to trigger layout updates manually or under specific conditions
func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		update_layout()  # Update layout when the widget's visibility changes

#func _draw():
	#draw_rect(Rect2(Vector2(), getSizeVecOfHeader()), background_color_header, true)
	#draw_rect(Rect2(Vector2(0,getSizeVecOfHeader().y), getSizeVecOfBody()), background_color_body, true)

func getSizeVecOfHeader() -> Vector2:
	var sizeVec: Vector2 = Vector2(0,0)
	for i in range(cell_widths.size()):
		sizeVec.x += cell_widths[i]
	
	sizeVec.y = header_cell_height
	return sizeVec

func getSizeVecOfBody() -> Vector2:
	var sizeVec: Vector2 = Vector2(0,0)
	for i in range(cell_widths.size()):
		sizeVec.x += cell_widths[i]
	for i in range(rows.size()):
		sizeVec.y += body_cell_heights[i]
		
	return sizeVec

func clear_children() -> void:
	for child in get_children():
		if child.name.begins_with("Separator"):
			continue
		remove_child(child)
		#child.queue_free()

func create_headers() -> void:
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
				
			margin_container.name = "Header_" + str(i)
			header.text = headers[i]
			margin_container.custom_minimum_size = Vector2(cell_widths[i], header_cell_height)
			margin_container.position = Vector2(get_x_offset(i), 0)
			header.clip_text = true
			margin_container.add_child(header)			
			header_group.add_child(margin_container)

func update_headers() -> void:
	if !header_group:
		return
	var children = header_group.get_children()
	for child in children:
		if(child.name.begins_with("Header_")):
			var index = int(child.name.substr(child.name.length() -1,1))
			if(headers.size() > index):
				child.get_child(0).text = headers[index]
				child.custom_minimum_size = Vector2(cell_widths[index], header_cell_height)
				child.minimum_size_changed
				child.set_size(Vector2(cell_widths[index], header_cell_height))
				child.position = Vector2(get_x_offset(index), 0)
				
			else :
				child.queue_free()

func _get_minimum_size() -> Vector2:
	# Calculate the minimum width based on the number of columns and cell size
	var min_size = Vector2(0,0)
	
	min_size = getSizeVecOfHeader()
	min_size.y += getSizeVecOfBody().y

	return min_size
