extends Control

@onready
var table2: O_TableNode = %"Table2"

@onready
var input: LineEdit = %debug_LE

# Called when the node enters the scene tree for the first time.
func _ready():
	
	var arr := []
	
	for i in 1001:
		
		var label := Label.new()
		var button := Button.new()
		var label2 := Label.new()
		var line_edit := LineEdit.new()
		
		line_edit.clip_contents = true
		
		label.text = "test: " + str(i)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		label2.text = "going strong"
		
		button.text = "press me " + str(randi())
		arr.append([label,button,line_edit,label2])
	
	var date1 = O_Date.new(2024,7,10)
	#print(date1)
	#print(date1.get_week())
	
	date1.set_date(2024,1,1)
	print(date1.get_week())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_debug_next_page_pressed():
	table2.current_page += 1

func _on_debug_previous_page_pressed():
	table2.current_page -= 1

func _on_debug_add_column_pressed():
	table2.add_column("test_column")

func _on_debug_add_row_pressed():
	var label := Label.new()
	var button := Button.new()
	var label2 := Label.new()
	var line_edit := LineEdit.new()
	#var cb = MenuButton.new()
	
	line_edit.clip_contents = true
	
	label.text = "test_debug "
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	label2.text = "going strong"
	
	button.text = "press me " + str(randi())

	table2.add_row([label,button,label2,line_edit])

func _on_debug_hide_column_pressed():
	if input:
		var col = input.text.to_int()
		if table2.get_visibility_column(col):
			table2.set_visibility_column(col, false)
		else: 
			table2.set_visibility_column(col, true)

func _on_debug_get_curr_row_pressed():
	print(table2.get_current_row())

func _on_debug_remove_row_pressed():
	if input:
		var row = input.text.to_int()
		table2.remove_row(row)


func _on_debug_remove_col_pressed():
	if input:
		var col = input.text.to_int()
		table2.remove_column(col)


func _on_debug_hide_row_pressed():
	
	if input:
		var row = input.text.to_int()
		if table2.get_visibility_row(row):
			table2.set_visibility_row(row, false)
		else:
			table2.set_visibility_row(row, true)


func _on_debug_insert_col_pressed():
	if input:
		table2.insert_column("test_column", input.text.to_int())


func _on_debug_insert_row_pressed():
	if input:
		var label := Label.new()
		var button := Button.new()
		var label2 := Label.new()
		var line_edit := LineEdit.new()
		#var cb = MenuButton.new()
		
		line_edit.clip_contents = true
		
		label.text = "test_debug "
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		label2.text = "going strong"
		
		button.text = "press me " + str(randi())

		table2.insert_row([label,button,label2,line_edit], input.text.to_int())
