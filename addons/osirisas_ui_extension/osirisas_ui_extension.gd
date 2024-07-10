@tool
extends EditorPlugin

func _enter_tree():
	add_custom_type("O Table Node", "Control",
					preload("res://addons/osirisas_ui_extension/table_node/o_table_node.gd"),
					preload("res://addons/osirisas_ui_extension/table_node/Icon_tableNode.png"))
	add_custom_type("O Date Line Edit", "LineEdit",
					preload("res://addons/osirisas_ui_extension/date_node/o_date_le_node.gd"),
					preload("res://icon.svg"))
func _exit_tree():
	remove_custom_type("O Table Node")
	remove_custom_type("O Date Line Edit")
