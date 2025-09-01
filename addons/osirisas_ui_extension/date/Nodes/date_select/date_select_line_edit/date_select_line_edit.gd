@tool
extends Control

signal date_btn_pressed

enum PopupSpawnDirection {
	TOP,
	BOTTOM,
	LEFT,
	RIGHT,
}

## The maximum date in which the entered date can be
@export var max_date: ODate = ODate.new(2099,12,1):
	set(value):
		max_date = value
		if date_le:
			date_le.max_date= max_date

## The minimum date in which the entered date can be
@export var min_date: ODate = ODate.new(2000,1,1):
	set(value):
		min_date = value
		if date_le:
			date_le.min_date = min_date

## The format in which the date will be displayed and accepted
@export var format: String = "DD.MM.YYYY":
	set(value):
		format = value
		if date_le:
			date_le.format = format

## If the font should change if the date is not valid
@export var change_color := true:
	set(value):
		change_color = value
		if date_le:
			date_le.change_color = change_color

## The color the font changes to, if the date is not valid
@export_color_no_alpha var color_not_valid := Color(1, 0, 0):
	set(value):
		color_not_valid = value
		if date_le:
			date_le.color_not_valid = color_not_valid

@export var button_icon_up: Texture2D = load("res://addons/osirisas_ui_extension/shared_ressources/arrow_drop_up.svg")
@export var button_icon_down: Texture2D = load("res://addons/osirisas_ui_extension/shared_ressources/arrow_drop_down.svg")
@export var button_icon_right: Texture2D = load("res://addons/osirisas_ui_extension/shared_ressources/arrow_right.svg")
@export var button_icon_left: Texture2D = load("res://addons/osirisas_ui_extension/shared_ressources/arrow_left.svg")


@onready
var date_le := %ODateLineEdit
@onready
var date_select_btn := %Date_select_Button
@onready
var date_select_icon := %TR_date_select

var _direction: PopupSpawnDirection

# Called when the node enters the scene tree for the first time.
func _ready():
	switch_btn_icon_direction(_direction)

func set_date_le_text(date_text: String) -> void:
	date_le.text = date_text

func _on_date_select_button_pressed():
	date_btn_pressed.emit()

func switch_btn_icon_direction(direction: PopupSpawnDirection) -> void:
	_direction = direction
	
	match direction:
		PopupSpawnDirection.TOP:
			date_select_icon.texture = button_icon_up
		PopupSpawnDirection.BOTTOM:
			date_select_icon.texture = button_icon_down
		PopupSpawnDirection.RIGHT:
			date_select_icon.texture = button_icon_right
		PopupSpawnDirection.LEFT:
			date_select_icon.texture = button_icon_left
		_:
			printerr("unknown direction")


#func _on_o_date_line_edit_valid_text_changed(new_text: String) -> void:
	#if Odate.new_text
