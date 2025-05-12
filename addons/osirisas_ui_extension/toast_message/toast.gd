extends Control

var _tween: Tween

func _ready() -> void:
	
	visible = false
	modulate.a = 0


func popup(msg: String, toast_settings: ToastSettings) -> void:
	%L_Toast_Message.text = msg
	visible = true
	modulate.a = 0
	
	if _tween and _tween.is_running():
		_tween.kill()
		
	_tween = create_tween()
	
	_tween.tween_property(self, "modulate:a", 1.0, toast_settings.animation_time.x)
	_tween.tween_interval(toast_settings.hold_time)
	_tween.tween_property(self, "modulate:a", 0.0, toast_settings.animation_time.y).finished.connect(hide)
