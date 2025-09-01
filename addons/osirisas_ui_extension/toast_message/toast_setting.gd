class_name OToastSettings
extends Resource

enum Toast_Position {
	TOP_LEFT,
	TOP_CENTER,
	TOP_RIGHT,
	RIGHT_CENTER,
	CENTER_CENTER,
	BOTTOM_LEFT,
	BOTTOM_CENTER,
	BOTTOM_RIGHT,
	LEFT_CENTER,
}


enum Toast_Animation {
	FADE,
	FADE_SLIDE,
	FLY_IN,
	SHAKE,
	SCALE,
	SHADOW_FLASH,
}


@export_group("Appearance")
## -1 = Automatic | < 0 = "Manual" Size
@export var size: Vector2i = Vector2i(-1,-1)
## The Toasts Maximum Displayed Size
@export var max_size: Vector2i = Vector2i(350, 200)
@export var toast_position: Toast_Position = Toast_Position.BOTTOM_CENTER 
@export var position_offset: Vector2i = Vector2i(0,0)
@export var toast_theme: Theme = null

@export_group("Behaviour")
@export var toast_animation: Toast_Animation = Toast_Animation.FADE_SLIDE
@export var toast_animation_settings := {}
@export var anim_transition_type: Tween.TransitionType = Tween.TransitionType.TRANS_SINE
@export var anim_ease_type: Tween.EaseType = Tween.EaseType.EASE_OUT
@export var animation_time: Vector2 = Vector2(0.35, 0.35)
@export var hold_time: float = 1.8


func resolve_position(screen_size: Vector2, toast_size: Vector2) -> Vector2:
	var pos := Vector2()
	match toast_position:
		Toast_Position.TOP_LEFT:
			pos = Vector2(0, 0)
		Toast_Position.TOP_CENTER:
			pos = Vector2((screen_size.x - toast_size.x)/2, 0)
		Toast_Position.TOP_RIGHT:
			pos = Vector2(screen_size.x - toast_size.x, 0)
		Toast_Position.RIGHT_CENTER:
			pos = Vector2(screen_size.x - toast_size.x, (screen_size.y - toast_size.y)/2)
		Toast_Position.CENTER_CENTER:
			pos = Vector2((screen_size.x - toast_size.x) / 2, (screen_size.y - toast_size.y) / 2)
		Toast_Position.BOTTOM_RIGHT:
			pos = Vector2(screen_size.x - toast_size.x, screen_size.y - toast_size.y)
		Toast_Position.BOTTOM_CENTER:
			pos = Vector2((screen_size.x - toast_size.x) / 2, screen_size.y - toast_size.y)
		Toast_Position.BOTTOM_LEFT:
			pos = Vector2(0, screen_size.y - toast_size.y)
		Toast_Position.LEFT_CENTER:
			pos = Vector2(0, (screen_size.y - toast_size.y) / 2)

	return pos + Vector2(position_offset)
