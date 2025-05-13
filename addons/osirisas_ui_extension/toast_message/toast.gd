extends Control

var _tween: Tween

var org_pivot_offset: Vector2 = Vector2()

func _ready() -> void:
	
	visible = false
	modulate.a = 0


func popup(msg: String, toast_settings: OToastSettings) -> void:
	%L_Toast_Message.text = msg
	visible = true
	modulate.a = 0
	
	if _tween and _tween.is_running():
		_tween.kill()
		
	_tween = create_tween()
	
	match toast_settings.toast_animation:
		OToastSettings.Toast_Animation.FADE:
			_play_fade(toast_settings)
		OToastSettings.Toast_Animation.FADE_SLIDE:
			_play_fade_slide(toast_settings)
		OToastSettings.Toast_Animation.FLY_IN:
			_play_fly_in(toast_settings)
		OToastSettings.Toast_Animation.SHAKE:
			_play_shake(toast_settings)
		OToastSettings.Toast_Animation.SCALE:
			_play_scale(toast_settings)
		OToastSettings.Toast_Animation.SHADOW_FLASH:
			_play_shadow_flash(toast_settings)
	

func _play_fade(settings: OToastSettings) -> void:
	modulate.a = 0
	_tween.tween_property(self, "modulate:a", 1.0, settings.animation_time.x)\
		.set_trans(settings.anim_transition_type).set_ease(settings.anim_ease_type)
	_tween.tween_interval(settings.hold_time)
	_tween.tween_property(self, "modulate:a", 0.0, settings.animation_time.y)\
		.finished.connect(hide)


func _play_fade_slide(settings: OToastSettings) -> void:
	var from = settings.resolve_position(get_window().size, size) - settings.toast_animation_settings.get("slide_starting_point", Vector2(60, 60))
	var to = settings.resolve_position(get_window().size, size)
	
	position = from
	modulate.a = 0
	
	_tween.parallel().tween_property(self, "position", to, settings.animation_time.x)\
		.set_trans(settings.anim_transition_type).set_ease(settings.anim_ease_type)
	_tween.parallel().tween_property(self, "modulate:a", 1.0, settings.animation_time.x)\
		.set_trans(settings.anim_transition_type).set_ease(settings.anim_ease_type)
	
	_tween.tween_interval(settings.hold_time)
	
	_tween.tween_property(self, "modulate:a", 0.0, settings.animation_time.y)\
		.finished.connect(hide)


func _play_fly_in(settings: OToastSettings) -> void:
	var screen_size := DisplayServer.window_get_size()
	
	var from: Vector2
	var direction: String = settings.toast_animation_settings.get("fly_from_direction", "right")
	match direction:
		"top_left":
			from = Vector2(-size.x, -size.y)
		"top":
			from = Vector2(position.x, size.y)
		"top_right":
			from = Vector2(screen_size.x + size.x, -size.y)
		"right":
			from = Vector2(screen_size.x + size.x, position.y)
		"left":
			from = Vector2(-size.x, position.y)
		"bottom_right":
			from = Vector2(screen_size.x + size.x, screen_size.y + size.y)
		"bottom":
			from = Vector2(position.x, screen_size.y + size.y)
		"bottom_left":
			from = Vector2( -size.x, screen_size.y + size.y)
	
	var to = position
	position = from
	modulate.a = 1.0

	_tween.tween_property(self, "position", to, settings.animation_time.x)\
		.set_trans(settings.anim_transition_type).set_ease(settings.anim_ease_type)
	_tween.tween_interval(settings.hold_time)
	_tween.tween_property(self, "modulate:a", 0.0, settings.animation_time.y)\
		.finished.connect(hide)


func _play_shake(settings: OToastSettings) -> void:
	var original = position
	modulate.a = 1.0
	
	const ITERATIONS := 5
	
	var intensity: Vector4 = settings.toast_animation_settings.get("shake_strength", Vector4(8, -8, 4, -4))
	
	for i in range(ITERATIONS):
		var offset = Vector2(randi_range(intensity.x, intensity.y), randi_range(intensity.z, intensity.w))
		_tween.tween_property(self, "position", original + offset, settings.animation_time.x / ITERATIONS)\
		.set_trans(settings.anim_transition_type).set_ease(settings.anim_ease_type)
		_tween.tween_property(self, "position", original, settings.animation_time.x / ITERATIONS)\
		.set_trans(settings.anim_transition_type).set_ease(settings.anim_ease_type)
	
	_tween.tween_interval(settings.hold_time)
	_tween.tween_property(self, "modulate:a", 0.0, settings.animation_time.y)\
		.finished.connect(hide)


func _play_scale(settings: OToastSettings) -> void:
	modulate.a = 1.0
	scale = Vector2(0.8, 0.8)
	
	var scale_center: String = settings.toast_animation_settings.get("scale_from_position", "center")
	
	org_pivot_offset = pivot_offset
	
	match scale_center:
		"center":
			pivot_offset = size / 2
		"top_left":
			pivot_offset = Vector2(0, 0)
		"top":
			pivot_offset = Vector2(size.x / 2, 0)
		"top_right":
			pivot_offset = Vector2(size.x, 0)
		"left":
			pivot_offset = Vector2(0, size.y / 2)
		"bottom_right":
			pivot_offset = Vector2(size.x, size.y)
		"bottom":
			pivot_offset = Vector2(size.x / 2, size.y)
		"bottom_left":
			pivot_offset = Vector2(0, size.y)
		"right":
			pivot_offset = Vector2(size.x, size.y / 2)
	
	_tween.tween_property(self, "scale", Vector2.ONE, settings.animation_time.x)\
		.set_trans(settings.anim_transition_type).set_ease(settings.anim_ease_type)
	_tween.tween_interval(settings.hold_time)
	_tween.tween_property(self, "modulate:a", 0.0, settings.animation_time.y)\
		.finished.connect(_on_scale_finished)


func _on_scale_finished() -> void:
	pivot_offset = org_pivot_offset
	hide()


func _play_shadow_flash(settings: OToastSettings) -> void:
	# Beispiel: Label mit DropShadow
	var label: Label = %L_Toast_Message
	var style_box: StyleBox = label.get_theme_stylebox("normal")
	
	
	var original_color = style_box.shadow_color
	style_box.shadow_color.a = 0.0
	label.add_theme_stylebox_override("normal", style_box)
	
	modulate.a = 1.0
	
	_tween.tween_method(func(a): 
		style_box.shadow_color.a = a,
		0.0,
		0.8,
		settings.animation_time.x
	).set_trans(settings.anim_transition_type).set_ease(settings.anim_ease_type)
	
	_tween.tween_interval(settings.hold_time)
	_tween.tween_property(self, "modulate:a", 0.0, settings.animation_time.y)\
		.finished.connect(hide)
