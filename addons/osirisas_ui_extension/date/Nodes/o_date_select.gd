@tool
class_name ODateSelect
extends Control


var date_select_scene: PackedScene = preload("res://addons/osirisas_ui_extension/date/Nodes/date_select.tscn")

func _init():
	var instance = date_select_scene.instantiate()
	add_child(instance)
	instance.position = Vector2i(0,0)
	custom_minimum_size = Vector2i(190,150)

func _init_buttons() -> void:
	pass
