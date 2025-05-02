@tool
class_name ODateSelect
extends Control

signal date_selected(date: ODate)

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
var _date_select_instance = date_select_scene.instantiate()

var selected_month: int = 1:
	set(value):
		print(value)
		selected_month = value % 13
		
		if value < 1:
			selected_month = 13 - selected_month
			selected_year += ((value - 1) / 12) - 1
		else:
			selected_year += (value - 1) / 12
		
		selected_month = clampi(selected_month, 1, 12)
		_date_select_instance.selected_month = selected_month

var selected_year: int = 1:
	set(value):
		selected_year = value if value > 0 else 1
		selected_year = clampi(selected_year, min_date.year, max_date.year)
		
		_date_select_instance.selected_year = selected_year

func _init():
	add_child(_date_select_instance)
	_date_select_instance.position = Vector2i(0,0)
	custom_minimum_size = Vector2i(190,150)
	_date_select_instance.connect("date_selected", Callable(self,"_on_date_selected"))
	#print(starting_date)

func _init_buttons() -> void:
	pass

func _on_date_selected(date: ODate) -> void:
	date_selected.emit(date)
