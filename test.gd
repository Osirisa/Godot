extends Control

@onready
var table: TableNode = %"Table Node"

# Called when the node enters the scene tree for the first time.
func _ready():
	
	for i in 250:
		var label = Label.new()
		var button = Button.new()
		var label2 = Label.new()
		var line_edit = LineEdit.new()
		var cb = MenuButton.new()
		
		line_edit.clip_contents = true
		
		label.text = "test: " + str(i)
		label2.text = "going strong"
		
		button.text = "press me " + str(i)
		cb.text = "combobox?"
		
		table.add_row([label,button,line_edit,label2,cb])
		
		
		
	table.set_cell(Button.new(),0,0)
	
	table.visibility_column(3,false)
	table.visibility_row(1,false)
	
	var test = table.get_cell(0,0)
	
	table.remove_row(33)
	print(test)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func _on_table_widget_cell_clicked(row, column):
	print(str(row) + " " + str(column))
	


func _on_button_pressed():
	table.visibility_column(3,true)
