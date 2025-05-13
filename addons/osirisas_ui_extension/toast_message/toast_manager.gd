extends Node

const TOAST_SCENE := preload("res://addons/osirisas_ui_extension/toast_message/toast.tscn")

var toast: Control

func _ready() -> void:
	toast = TOAST_SCENE.instantiate()
	
	
	print(DisplayServer.get_window_list())


func show(msg: String, toast_settings: OToastSettings, window: Window = null, use_safe_area := false) -> void:
	
	toast.size = toast.get_theme_font("font").get_multiline_string_size(msg, HORIZONTAL_ALIGNMENT_CENTER, toast_settings.max_size.x, toast.get_theme_font_size("font_size"))
	
	if toast_settings.toast_theme:
		toast.theme = toast_settings.toast_theme
		
		if toast_settings.toast_theme.get_stylebox("panel", "Panel").content_margin_left >= 0:
			toast.size.x += toast_settings.toast_theme.get_stylebox("panel", "Panel").content_margin_left
		if toast_settings.toast_theme.get_stylebox("panel", "Panel").content_margin_right >= 0:
			toast.size.x += toast_settings.toast_theme.get_stylebox("panel", "Panel").content_margin_right
		if toast_settings.toast_theme.get_stylebox("panel", "Panel").content_margin_top >= 0:
			toast.size.y += toast_settings.toast_theme.get_stylebox("panel", "Panel").content_margin_top
		if toast_settings.toast_theme.get_stylebox("panel", "Panel").content_margin_bottom >= 0:
			toast.size.y += toast_settings.toast_theme.get_stylebox("panel", "Panel").content_margin_bottom
	
	if toast_settings.size.x >= 0:
		toast.size.x = toast_settings.size.x
	else:
		if toast_settings.max_size.x >= 0:
			toast.size.x = min(toast.size.x, toast_settings.max_size.x) 
		
	if toast_settings.size.y >= 0:
		toast.size.y = toast_settings.size.y
	else:
		if toast_settings.max_size.y >= 0:
			toast.size.y = min(toast.size.y, toast_settings.max_size.y)
	
	var parent = toast.get_parent()
	if parent:
		parent.remove_child(toast)
	
	if window:
		window.add_child(toast)
	else:
		get_tree().root.add_child(toast)
	
	
	if use_safe_area:
		toast.position = toast_settings.resolve_position(DisplayServer.get_display_safe_area().size, toast.size) + Vector2(DisplayServer.get_display_safe_area().position)
	else:
		toast.position = toast_settings.resolve_position(window.size, toast.size)
	
		toast.popup(msg, toast_settings)
