extends Control

signal date_btn_pressed

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

@onready
var date_le := %ODateLineEdit
@onready
var date_select_btn := %Date_select_Button

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func set_date_le_text(date_text: String) -> void:
	date_le.text = date_text

func _on_date_select_button_pressed():
	date_btn_pressed.emit()
