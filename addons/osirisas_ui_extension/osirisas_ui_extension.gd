@tool
extends EditorPlugin

func _enter_tree():
	add_custom_type("Table Node", "Control", preload("res://addons/osirisas_ui_extension/table_node/table_node.gd"),preload("res://addons/osirisas_ui_extension/table_node/Icon_tableNode.png"))


func _exit_tree():
	remove_custom_type("Table Node")
	remove_custom_type("table_widget.gd")
