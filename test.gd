extends Control

@onready
var table = %"Table Widget"

# Called when the node enters the scene tree for the first time.
func _ready():
	var label = Label.new()
	label.text = "test"
	
	var button = Button.new()
	button.text = "test2"
	
	var lineEdit = LineEdit.new()
	lineEdit.text = "Test3"
	
	table.add_row([label,button,lineEdit])

	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
