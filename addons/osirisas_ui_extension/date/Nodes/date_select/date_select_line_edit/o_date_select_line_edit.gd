@tool
class_name ODateSelectLineEdit
extends Control

signal date_selected(date: ODate)
signal date_entered(date: ODate)

@export var date_select_size := Vector2i(size.x, 240):
	set(value):
		date_select_size = value
		if _date_select_active:
			_date_select_instance.set_size(date_select_size)

@export var date_select_pos := Vector2i(0, 0):
	set(value):
		date_select_pos = value
		if _date_select_active:
			_date_select_instance.set_position(date_select_pos)

@export var use_custom_pos := false:
	set(value):
		use_custom_pos = value
		if _date_select_active:
			_date_select_instance.set_position(global_position)

@export var offset_pos := Vector2i(0, 0):
	set(value):
		offset_pos = value
		if _date_select_active:
			_date_select_instance.set_position(Vector2i(global_position.x + offset_pos.x, 
														global_position.y + offset_pos.y))

@export var starting_date: ODate = ODate.current_date():
	set(value):
		starting_date = value
		_date_select_instance.starting_date = starting_date
## The maximum date in which the entered date can be

@export var max_date: ODate = ODate.new(2099,12,1):
	set(value):
		max_date = value
		_date_select_instance.max_date = max_date
		_date_select_line_edit_instance.max_date = max_date

## The minimum date in which the entered date can be
@export var min_date: ODate = ODate.new(2000,1,1):
	set(value):
		min_date = value
		_date_select_instance.min_date = min_date
		_date_select_line_edit_instance.min_date = min_date

## The format in which the date will be displayed and accepted
@export var format: String = "DD.MM.YYYY":
	set(value):
		format = value
		_date_select_line_edit_instance.format = format

## If the font should change if the date is not valid
@export var change_color := true:
	set(value):
		change_color = value
		_date_select_line_edit_instance.change_color = change_color

## The color the font changes to, if the date is not valid
@export_color_no_alpha var color_not_valid := Color(1, 0, 0):
	set(value):
		color_not_valid = value
		_date_select_line_edit_instance.color_not_valid = color_not_valid

@export var close_on_select := true

@export var different_parent: Control
@export var z_idx: int = 0

var _date_select_scene: PackedScene = preload("res://addons/osirisas_ui_extension/date/Nodes/date_select/date_select.tscn")
var _date_select_line_edit_scene: PackedScene = preload("res://addons/osirisas_ui_extension/date/Nodes/date_select/date_select_line_edit/date_select_line_edit.tscn")

var _date_select_instance: Control = _date_select_scene.instantiate()
var _date_select_line_edit_instance: Control = _date_select_line_edit_scene.instantiate()

var _date_select_active := false

# Called when the node enters the scene tree for the first time.
func _ready():
	add_child(_date_select_line_edit_instance)
	
	_date_select_line_edit_instance.position = Vector2i(0,0)
	custom_minimum_size = Vector2i(80,31)
	
	_date_select_instance.connect("date_selected", Callable(self, "_on_date_selected"))
	_date_select_line_edit_instance.connect("date_btn_pressed" ,Callable(self,"_on_date_select_btn_pressed"))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _date_select_active:
			if different_parent:
				different_parent.remove_child(_date_select_instance)
			else:
				remove_child(_date_select_instance)
			_date_select_active = false

func _on_date_select_btn_pressed()-> void:
	if _date_select_active:
		if different_parent:
			different_parent.remove_child(_date_select_instance)
		else:
			remove_child(_date_select_instance)
		_date_select_active = false
		
	else:
		if different_parent:
			different_parent.add_child(_date_select_instance)
		else:
			add_child(_date_select_instance)
		
		if use_custom_pos:
			_date_select_instance.position = date_select_pos
		else:
			_date_select_instance.position = Vector2i(global_position.x + offset_pos.x, 
														global_position.y + offset_pos.y)
		
		_date_select_instance.set_size(date_select_size)
		
		_date_select_instance.z_index = z_idx
		_date_select_active = true

func _on_date_selected(date: ODate) -> void:
	_date_select_line_edit_instance.set_date_le_text(date.to_string_formatted(format))
	
	if close_on_select:
		if different_parent:
			different_parent.remove_child(_date_select_instance)
		else:
			remove_child(_date_select_instance)
		_date_select_active = false
