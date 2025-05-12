@tool
extends Control

@export_tool_button("fill") var btn_action = action


var strings: Array[String] = [
	"Test",
	"blala",
	"aefkj",
	"fasef",
]

var toast_settings: ToastSettings = preload("res://addons/osirisas_ui_extension/toast_message/standard_toast.tres")

func _ready() -> void:
	%OBreadCrumbs.breadcrumb_pressed.connect(_on_breadcrumb_pressed)
	
	%OBreadCrumbs.clear_elements()
	var f = func(string): print(string)
	for string in strings:
		%OBreadCrumbs.add_element_(string, f.bind(string))


func action() -> void:
	%OBreadCrumbs.clear_elements()
	var f = func(string): print(string)
	for string in strings:
		%OBreadCrumbs.add_element_(string, f.bind(string))


func _on_breadcrumb_pressed(index) -> void:
	pass


func _on_button_pressed() -> void:
	ToastManager.show("this is a toast", toast_settings, get_window(), false)
