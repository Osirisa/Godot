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
	
	add_custom_type("ODateSelectLineEdit", "Control",
					preload("res://addons/osirisas_ui_extension/date/Nodes/date_select/date_select_line_edit/o_date_select_line_edit.gd"),
					preload("res://icon.svg"))
	
	add_custom_type("ODragContainer", "Container",
					preload("res://addons/osirisas_ui_extension/container/Draggable_Container/o_drag_grid_container.gd"),
					preload("res://icon.svg"))
	
	add_custom_type("ODragComponent", "Control",
					preload("res://addons/osirisas_ui_extension/container/Draggable_Container/o_dragable_component.gd"),
					preload("res://icon.svg"))
	
	add_autoload_singleton("ToastManager", "res://addons/osirisas_ui_extension/toast_message/toast_manager.gd")
	
	__OProjectSettings__.create_settings()

func _exit_tree():
	remove_custom_type("OTableNode")
	remove_custom_type("ODateLineEdit")
	remove_custom_type("ORegexLineEdit")
	remove_custom_type("ODateSelect")
	remove_custom_type("ODateSelectLineEdit")
	remove_custom_type("ODragContainer")
	remove_custom_type("ODragComponent")
	remove_autoload_singleton("ToastManager")
