extends Node

const TOAST_SCENE := preload("res://addons/osirisas_ui_extension/toast_message/toast.tscn")

var toast: Control

func _ready() -> void:
	toast = TOAST_SCENE.instantiate()
	get_tree().root.add_child.call_deferred(toast)
	
	var safe := DisplayServer.get_display_safe_area()
	toast.anchor_left = 0.5
	toast.anchor_right = 0.5
	toast.anchor_top = 0
	toast.anchor_bottom = 0
	
	toast.position = Vector2(0, safe.position.y + 20)


func show(msg: String, duration := 1.8) -> void:
	toast.popup(msg, duration)
