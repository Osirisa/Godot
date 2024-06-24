extends Control

@onready
var table: TableNode = %"Table Node"
@onready
var table2: TableNode_v2 = %"Table2"

@onready
var input: LineEdit = %debug_LE

# Called when the node enters the scene tree for the first time.
func _ready():
	
	var arr := []
	
	for i in 2000:
		
		var label := Label.new()
		var button := Button.new()
		var label2 := Label.new()
		var line_edit := LineEdit.new()
		#var cb = MenuButton.new()
		
		line_edit.clip_contents = true
		
		label.text = "test: " + str(i)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		label2.text = "going strong"
		
		button.text = "press me " + str(randi())
		#cb.text = "combobox?"
		
		#arr.append([label,button,line_edit,label2,cb])
		arr.append([label,button,line_edit,label2])
		
	table2.add_rows_batch(arr)
	#table.add_rows_batch(arr)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func _on_table_widget_cell_clicked(row, column):
	print(str(row) + " " + str(column))
	


func _on_button_pressed():
	print(table.get_selection_positions())


func _on_debug_add_row_pressed():
	table.add_row()

func _on_debug_add_column_pressed():
	table.add_header("test")


func _on_debug_hide_row_pressed():
	if input:
		var row = input.text.to_int()
		if table.get_visibility_row(row):
			table.visibility_row(row,false)
		else:
			table.visibility_row(row,true)


func _on_debug_hide_column_pressed():
	if input:
		var column = input.text.to_int()
		if table.get_visibility_column(column):
			table.visibility_column(column,false)
		else:
			table.visibility_column(column,true)

func _on_debug_remove_row_pressed():
	if input:
		table.remove_row(input.text.to_int())


func _on_debug_get_curr_row_pressed():
	#print(table.get_current_row())
	table2.update_table()
	table2._update_body_size()


func _on_debug_set_row_heigth_pressed():
	if input:
		table.set_row_height(input.text.to_int(),40)
	
	#print(table.get_column_count())
	#print(table.get_row_count())
	#print(table.has_selection())


func _on_debug_set_col_width_pressed():
	if input:
		table.set_column_width(input.text.to_int(),40)


func _on_debug_hide_selection_pressed():
	for i in table.get_selection_positions():
		print(i)
		table.set_visibility_row(i,false)
