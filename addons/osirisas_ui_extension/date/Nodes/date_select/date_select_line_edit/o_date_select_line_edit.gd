@tool
class_name ODateSelectLineEdit
extends Control

signal date_selected(date: ODate)
signal date_entered(date: ODate)

enum PopupSpawnDirection {
	TOP,
	BOTTOM,
	LEFT,
	RIGHT,
}

@export_group("Transform")
@export var use_custom_size := false:
	set(value):
		use_custom_size = value
		_date_select_instance.set_position(global_position)

@export var date_select_size := Vector2i(size.x, 240):
	set(value):
		date_select_size = value
		_date_select_instance.set_size(date_select_size)

@export var date_select_pos := Vector2i(0, 0):
	set(value):
		date_select_pos = value
		_date_select_instance.set_position(date_select_pos)

@export var use_custom_pos := false:
	set(value):
		use_custom_pos = value
		_date_select_instance.set_position(global_position)

@export var offset_pos := Vector2i(0, 0):
	set(value):
		offset_pos = value
		_date_select_instance.set_position(Vector2i(global_position.x + offset_pos.x, 
														global_position.y + offset_pos.y))

@export var popup_direction : PopupSpawnDirection = PopupSpawnDirection.BOTTOM:
	set(value):
		popup_direction = value
		if is_node_ready():
			_date_select_line_edit_instance.switch_btn_icon_direction(popup_direction)

@export_group("Date")
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

@export var date_select_theme: Theme = load("res://addons/osirisas_ui_extension/date/Nodes/date_select/date_select_theme.tres")
@export var today_sb: StyleBoxFlat = null:
	set(value):
		today_sb = value
		
		if today_sb:
			_date_select_instance.today_sb = today_sb

var current_date: ODate

var _date_select_scene: PackedScene = preload("res://addons/osirisas_ui_extension/date/Nodes/date_select/date_select.tscn")
var _date_select_line_edit_scene: PackedScene = preload("res://addons/osirisas_ui_extension/date/Nodes/date_select/date_select_line_edit/date_select_line_edit.tscn")

var _date_select_instance: Popup = _date_select_scene.instantiate()
var _date_select_line_edit_instance: Control = _date_select_line_edit_scene.instantiate()

func _init() -> void:
	custom_minimum_size = custom_minimum_size if Vector2i(80, 31) < Vector2i(custom_minimum_size) else Vector2i(92, 31) 

# Called when the node enters the scene tree for the first time.
func _ready():
	add_child(_date_select_instance)
	_date_select_instance.hide()
	add_child(_date_select_line_edit_instance)
	
	starting_date = ODate.current_date()
	
	_date_select_line_edit_instance.position = Vector2i(0,0)
	_date_select_instance.theme = date_select_theme
	_date_select_instance.connect("date_selected", Callable(self, "_on_date_selected"))
	_date_select_line_edit_instance.connect("date_btn_pressed" ,Callable(self,"_on_date_select_btn_pressed"))
	_date_select_line_edit_instance.switch_btn_icon_direction(popup_direction)


func _on_date_select_btn_pressed()-> void:
	var date_pos: Vector2i
	var date_size: Vector2i = Vector2i(size.x, 200)
	
	if use_custom_size:
		date_size = date_select_size
	
	if use_custom_pos:
		date_pos = date_select_pos
	else:
		match popup_direction:
			PopupSpawnDirection.TOP:
				date_pos = Vector2i(get_screen_position().x, get_screen_position().y - date_size.y - 2)
			PopupSpawnDirection.BOTTOM:
				date_pos = Vector2i(get_screen_position().x, get_screen_position().y + size.y + 2)
			PopupSpawnDirection.RIGHT:
				date_pos = Vector2i(get_screen_position().x + size.x + 2, get_screen_position().y)
			PopupSpawnDirection.LEFT:
				date_pos = Vector2i(get_screen_position().x - size.x - 2, get_screen_position().y)
			_:
				printerr("Unknown orientation")
	
	
	_date_select_instance.popup(Rect2i(date_pos, date_size))

func _on_date_selected(date: ODate) -> void:
	_date_select_line_edit_instance.set_date_le_text(date.to_string_formatted(format))
	current_date = date
	
	if close_on_select:
		_date_select_instance.hide()
