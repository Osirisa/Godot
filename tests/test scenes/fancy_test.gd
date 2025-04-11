@tool
extends Control

@export_tool_button("Redraw now") var redraw_action = _on_redraw_pressed

func _on_redraw_pressed():
	$OFancyLineEdit.queue_redraw()
