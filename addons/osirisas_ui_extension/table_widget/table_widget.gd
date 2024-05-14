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

#Background colors for the header and the body
@export var background_color_header: Color = Color(0.7,0.5,0.9,1):
	set(value): 
		background_color_header = value
		queue_redraw()

@export var background_color_body: Color = Color(0.2,1,0.6,1):
	set(value): 
		background_color_body = value
		queue_redraw()

## x = Left, y = Top, z = Right, w = Bottom
@export var margin: Vector4 = Vector4(5,5,5,5):
	set(value): 
		margin = value
		update_layout()

##Checkbox if resizing is allowed
@export var resizing = false:
	set(value):
		resizing = value
		update_layout()



var columns: int
var rows := []

var body_cell_heights:= []

var separator_group : Control = Control.new()
var vertical_separators := []
var horizontal_separators := []

func _enter_tree():
	pass # Replace with function body.

func _init():
	pass
	
func _ready():
	init_Table()
	init_v_separators()
	update_layout()
	queue_redraw()

func init_Table() -> void:
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

# Adds a row to the table
func add_row(data: Array, height: float = standard_body_cell_height) -> void:
	#print("Adding row with data: ", data)  # <- DEBUG:: Check what data is received
	var row = []
	body_cell_heights.append(height)
	
	for i in range(data.size()):
		var widget = data[i]
		var margin_parent = MarginContainer.new()
		
		if  widget is LineEdit:
			#print(child.get_minimum_size())
			pass
		elif widget is Label or Button:
			widget.clip_text = true
				
		margin_parent.add_child(widget)
		
		#print("Label text set to: ", label.text)  # <- DEBUG:: Verify label text
		#widget.custom_minimum_size = Vector2(cell_widths[i], body_cell_heights[rows.size()])
		
		margin_parent.custom_minimum_size = Vector2(cell_widths[i], body_cell_heights[rows.size()])
		
		add_child(margin_parent)
		row.append(margin_parent)

	rows.append(row)
	#print("Current rows: ", rows)  # <- DEBUG:: Verify rows content 
	
	init_h_seperators() # Updates the separators for the new row
	update_layout()

func update_layout() -> void:
	#clear_children()  # Clear existing children first, confirm this is intended to remove all
	create_headers()  # Function to create header labels
	update_headers()
	layout_rows()     # Lays out the rows
	
	# Lay out the seperators
	update_v_separators()
	update_h_separators()
	
	# For all Containers as parents to update
	minimum_size_changed.emit()
	
	# Redraws the whole widget for all changes to take immediate effect
	queue_redraw()

func layout_rows() -> void:
	var yOffset = header_cell_height + margin.y + margin.w
	for j in range(rows.size()):
		for i in range(rows[j].size()):
			var margin_parent:MarginContainer = rows[j][i]
			var child = margin_parent.get_child(0)
			
			#var child = LineEdit.new()
			margin_parent.position = Vector2(get_x_offset(i), yOffset)
			margin_parent.custom_minimum_size = Vector2(cell_widths[i],body_cell_heights[j])
			margin_parent.minimum_size_changed.emit()
			margin_parent.set_size(Vector2(cell_widths[i],body_cell_heights[j]))
			
			margin_parent.add_theme_constant_override("margin_top",int(margin.y))
			margin_parent.add_theme_constant_override("margin_bottomn",int(margin.w))
			margin_parent.add_theme_constant_override("margin_left",int(margin.x))
			margin_parent.add_theme_constant_override("margin_right",int(margin.z))
			#add_child(child)
		yOffset += body_cell_heights[j] + margin.y + margin.w

func get_x_offset(col_index:int) -> float:
	var offset = 0.0
	for i in range (col_index):
		offset += cell_widths[i] + margin.x + margin.z
	return offset

func update_v_separators() -> void:
	var pos = 0.0
	
	#TBD:: ???
	var x_offset = -margin.x
	#x_offset = 0.0 #<- debug
	
	for i in range(vertical_separators.size()):
		pos+=cell_widths[i] + margin.x + margin.z
		vertical_separators[i].position = Vector2(x_offset + pos,0)
		vertical_separators[i].set_size(Vector2(1,get_total_height()))

func update_h_separators() -> void:
	var pos = 0.0
	var y_offset = getSizeVecOfHeader().y - 2
	
	for i in range (horizontal_separators.size()):
		pos += body_cell_heights[i] + margin.y + margin.w
		horizontal_separators[i].position = Vector2(0, y_offset + pos)
		horizontal_separators[i].set_size(Vector2(getSizeVecOfHeader().x, 1))

func get_total_height() -> float:
	var total_body_height = getSizeVecOfBody().y
	return total_body_height + header_cell_height + margin.y + margin.w

# Optionally, you might want to trigger layout updates manually or under specific conditions
func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		update_layout()  # Update layout when the widget's visibility changes

func _draw():
	draw_rect(Rect2(Vector2(), getSizeVecOfHeader()), background_color_header, true)
	draw_rect(Rect2(Vector2(0,getSizeVecOfHeader().y), getSizeVecOfBody()), background_color_body, true)

func getSizeVecOfHeader() -> Vector2:
	var sizeVec: Vector2 = Vector2(0,0)
	for i in range(cell_widths.size()):
		sizeVec.x += cell_widths[i] + margin.x + margin.z
	
	sizeVec.y = header_cell_height + margin.y + margin.w
	return sizeVec

func getSizeVecOfBody() -> Vector2:
	var sizeVec: Vector2 = Vector2(0,0)
	for i in range(cell_widths.size()):
		sizeVec.x += cell_widths[i] + margin.x + margin.z
	for i in range(rows.size()):
		sizeVec.y += body_cell_heights[i] + margin.y + margin.w
		
	return sizeVec

func clear_children() -> void:
	for child in get_children():
		if child.name.begins_with("Separator"):
			continue
		remove_child(child)
		#child.queue_free()

func create_headers() -> void:
	var children = get_children()
	var createdIndexes := []
	for child in children:
		if(child.name.begins_with("Header_")):
			createdIndexes.append(int(child.name.substr(child.name.length() -1,1)))
	for i in range(headers.size()):
		if createdIndexes.has(i):
			continue
		if headers[i]:
			var header = Label.new()
			header.name = "Header_" + str(i)
			header.text = headers[i]
			header.custom_minimum_size = Vector2(cell_widths[i], header_cell_height)
			header.position = Vector2(get_x_offset(i), 0)
			header.clip_text = true
			add_child(header)

func update_headers() -> void:
	var children = get_children()
	for child in children:
		if(child.name.begins_with("Header_")):
			var index = int(child.name.substr(child.name.length() -1,1))
			if(headers.size() > index):
				child.text = headers[index]
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
