@tool
extends EditorPlugin

func _enter_tree():
	
	add_custom_type("Table Widget", "Control", preload("res://addons/osirisas_ui_extension/table_widget/table_widget.gd"),preload("res://addons/osirisas_ui_extension/table_widget/Icon_tableWidget.png"))
	
	#var editor_interface = get_editor_interface()
	#editor_interface.connect("scene_changed",Callable(self,"_on_scene_changed"))

func _exit_tree():
	remove_custom_type("Table Widget")
	
	#var editor_interface = get_editor_interface()
	#editor_interface.disconnect("scene_changed", Callable(self, "_on_scene_changed"))


#func _on_scene_changed(scene_root):
	#if scene_root and scene_root.get_class() == "Table Widget":
		#scene_root.update_layout()