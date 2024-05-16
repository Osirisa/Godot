extends Control

@onready
var table: TableWidget = %"Table Widget"

# Called when the node enters the scene tree for the first time.
func _ready():
	var label = Label.new()
	label.text = "test"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	#label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var button = Button.new()
	button.text = "test2"
	
	var lineEdit = LineEdit.new()
	lineEdit.text = "Test3"
		
	table.add_row([label,button,lineEdit])
	table.add_row([Label.new(),Label.new(),Button.new()])
	
	table.clear()


	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
