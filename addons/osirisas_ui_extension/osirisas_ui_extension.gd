@tool
extends EditorPlugin

func _enter_tree():
	add_custom_type("O Table Node", "Control", preload("res://addons/osirisas_ui_extension/table_node/o_table_node.gd"),preload("res://addons/osirisas_ui_extension/table_node/Icon_tableNode.png"))

func _exit_tree():
	remove_custom_type("O Table Node")
