extends Control


@export_group("Appearance")
@export var toast_size := Vector2i(200,100)
@export var toast_theme: Theme = null:
	set(value):
		toast_theme = value
		if toast_theme:
			%P_Background.theme = toast_theme
			%L_Toast_Message.theme = toast_theme

@export_group("Behaviour")
@export var hold_time: float = 1.8
@export var animation_time: float = 0.35


var _tween: Tween

func _ready() -> void:
	
	visible = false
	modulate.a = 0


func popup(msg: String, duration:= hold_time) -> void:
	%L_Toast_Message.text = msg
	hold_time = duration
	visible = true
	modulate.a = 0
	
	
	if _tween and _tween.is_running():
		_tween.kill()
		
	_tween = create_tween()
	
	
	
	_tween.tween_property(self, "modulate:a", 1.0, animation_time)
	_tween.tween_interval(hold_time)
	_tween.tween_property(self, "modulate:a", 0.0, animation_time).finished.connect(hide)
