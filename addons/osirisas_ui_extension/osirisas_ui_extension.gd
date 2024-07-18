@tool
extends EditorPlugin

func _enter_tree():
	add_custom_type("OTableNode", "Control",
					preload("res://addons/osirisas_ui_extension/table_node/o_table_node.gd"),
					preload("res://addons/osirisas_ui_extension/table_node/Icon_tableNode.png"))
					
	add_custom_type("ORegexLineEdit", "LineEdit",
					preload("res://addons/osirisas_ui_extension/regex_line_edit_node/o_regex_line_edit.gd"),
					preload("res://icon.svg"))
					
	add_custom_type("ODateLineEdit", "ORegexLineEdit",
					preload("res://addons/osirisas_ui_extension/regex_line_edit_node/date_time_nodes/o_date_le_node.gd"),
					preload("res://icon.svg"))
	
	add_custom_type("ODateSelect", "Control",
					preload("res://addons/osirisas_ui_extension/date/Nodes/date_select/o_date_select.gd"),
					preload("res://icon.svg"))

func _exit_tree():
	remove_custom_type("OTableNode")
	remove_custom_type("ODateLineEdit")
	remove_custom_type("ORegexLineEdit")
	remove_custom_type("ODateSelect")
