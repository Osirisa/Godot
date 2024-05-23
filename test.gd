extends Control

@onready
var table: TableNode = %"Table Node"
@onready
var input: LineEdit = %debug_LE

# Called when the node enters the scene tree for the first time.
func _ready():
	
	for i in 30:
		var label = Label.new()
		var button = Button.new()
		var label2 = Label.new()
		var line_edit = LineEdit.new()
		var cb = MenuButton.new()
		
		line_edit.clip_contents = true
		
		label.text = "test: " + str(i)
		label2.text = "going strong"
		
		button.text = "press me " + str(randi())
		cb.text = "combobox?"
		
		table.add_row([label,button,line_edit,label2,cb])


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
	print(table.get_current_row())
