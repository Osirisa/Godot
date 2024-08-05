@tool
class_name ODateSelectLineEdit
extends Control

@export var date_select_height: int = 240:
	set(value):
		date_select_height = value
		if _date_select_active:
			_date_select_instance.position = Vector2i(0, date_select_height)
			_date_select_instance.set_size(Vector2i(size.x, date_select_height))

@export var starting_date: ODate = ODate.current_date():
	set(value):
		starting_date = value
		_date_select_instance.starting_date = starting_date

@export var max_date: ODate = ODate.new(2099,12,1):
	set(value):
		max_date = value
		_date_select_instance.max_date = max_date

@export var min_date: ODate = ODate.new(2000,1,1):
	set(value):
		min_date = value
		_date_select_instance.min_date = min_date

var date_select_scene: PackedScene = preload("res://addons/osirisas_ui_extension/date/Nodes/date_select/date_select.tscn")
var date_select_line_edit_scene: PackedScene = preload("res://addons/osirisas_ui_extension/date/Nodes/date_select/date_select_line_edit/date_select_line_edit.tscn")

var _date_select_instance: Control = date_select_scene.instantiate()
var _date_select_line_edit_instance: Control = date_select_line_edit_scene.instantiate()

var _date_select_active := false

# Called when the node enters the scene tree for the first time.
func _ready():
	add_child(_date_select_line_edit_instance)
	_date_select_line_edit_instance.position = Vector2i(0,0)
	custom_minimum_size = Vector2i(80,31)
	
	_date_select_line_edit_instance.connect("date_btn_pressed" ,Callable(self,"_on_date_select_btn_pressed"))

func _on_date_select_btn_pressed():
	if _date_select_active:
		remove_child(_date_select_instance)
		_date_select_active = false
	else:
		add_child(_date_select_instance)
		_date_select_instance.position = Vector2i(0, -date_select_height)
		_date_select_instance.set_size(Vector2i(size.x, date_select_height))
		_date_select_active = true
