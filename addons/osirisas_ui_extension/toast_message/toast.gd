extends Control


var _tween: Tween

func _ready() -> void:
	
	visible = false
	modulate.a = 0


func popup(msg: String, hold_duration:= 1.8, animation_time := 0.35, toast_theme: Theme = null) -> void:
	%L_Toast_Message.text = msg
	visible = true
	modulate.a = 0
	
	
	
	if _tween and _tween.is_running():
		_tween.kill()
		
	_tween = create_tween()
	
	_tween.tween_property(self, "modulate:a", 1.0, animation_time)
	_tween.tween_interval(hold_duration)
	_tween.tween_property(self, "modulate:a", 0.0, animation_time).finished.connect(hide)
