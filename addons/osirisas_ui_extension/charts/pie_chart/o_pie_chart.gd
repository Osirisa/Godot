class_name OPieChart
extends Control

enum HighliteType {
	NONE,
	EXPAND,
	EXPAND_DIM_OTHERS,
	SHRINK,
	RAISE,
	SCALE_UP,
	GLOW,
	DIM_OTHERS,
	BORDER,
	OUTLINE_FADE,
	LABEL_ONLY,
	#PATTERN,
	LIGHTER,
	DARKER,
}

@export var datasets: Array[OChartData]
@export var highlite_type: HighliteType = HighliteType.EXPAND
@export var show_popup := true
@export var popup := preload("uid://conhlhmvmtn7h")

@export var center := size/2
@export var radius: float = min(size.x/2, size.y/2) * 0.9

var hovered_segment := -1
var last_hovered_segment := -1

# TBD: refresh @ resize or new data etc
var segment_angles: Array[Vector2] = []
var segment_polygons: Array[PackedVector2Array] = []

var highlite_states: Array[HighlightState]
var animation_manager: Array[AnimationManager]

var _popup_instance: OChartPopup
var _popup_tween: Tween

func _ready():
	
	focus_mode = Control.FOCUS_ALL
	_popup_instance = popup.instantiate() as OChartPopup
	add_child(_popup_instance)
	
	#if datasets.size() > 0:
	_popup_instance.data_title = datasets[0].data_name
	var test := _popup_instance.OChartPopupData.new()
	
	_popup_instance.unfocusable = true
	_popup_instance.hide()
	
	var values: Array[float]
	for data in datasets[0].data:
		values.append(data)
	
	_update_segment_angles(values)
	_update_segment_polygons()
	
	for i in datasets[0].data:
		var highlite_state := HighlightState.new()
		highlite_state.update_seg.connect(queue_redraw)
		
		var animation_manag = AnimationManager.new(self, highlite_state)
		
		highlite_states.append(highlite_state)
		animation_manager.append(animation_manag)


func _draw() -> void:
	if datasets.is_empty() or datasets[0].data.is_empty():
		return
	
	var colors := datasets[0].colors
	var center := size / 2
	var radius: float = min(center.x, center.y) * 0.9

	var values: Array[float] 
	for data in datasets[0].data:
		values.append(data)

	#var segment_angles := _get_segment_angles(values)
	
	# 1. Alle normalen Segmente zuerst (ohne Hover)
	for i in values.size():
		
		if i == hovered_segment or i == last_hovered_segment and highlite_states[last_hovered_segment].seg_offset > 0.01:
			continue  # wird später separat gezeichnet
		
		var color = colors[i % colors.size()] if (colors.size() > 0) else Color.GRAY
		
		if highlite_type == HighliteType.DIM_OTHERS or highlite_type == HighliteType.EXPAND_DIM_OTHERS and hovered_segment != -1:
			color = color.darkened(0.4)
		
		#draw_pie_segment(center, radius, segment_angles[i].x, segment_angles[i].y, color, i, false)
		draw_pie_segment(i, color, false)
	
	if last_hovered_segment != -1 and highlite_states[last_hovered_segment].seg_offset > 0.01:
			var color = colors[last_hovered_segment] if (last_hovered_segment < colors.size()) else Color.GRAY
			#var start_angle = segment_angles[last_hovered_segment].x
			#var end_angle = segment_angles[last_hovered_segment].y
			
			#draw_pie_segment(center, radius, start_angle, end_angle, color, last_hovered_segment, true)
			draw_pie_segment(last_hovered_segment, color, true)
	
	if hovered_segment >= 0 and hovered_segment < values.size():
		var color = colors[hovered_segment] if (hovered_segment < colors.size()) else Color.GRAY
		#var start_angle = segment_angles[hovered_segment].x
		#var end_angle = segment_angles[hovered_segment].y
		
		#draw_pie_segment(center, radius, start_angle, end_angle, color, hovered_segment, true)
		draw_pie_segment(hovered_segment, color, true)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		var mouse_pos := get_local_mouse_position()
		
		for i in segment_polygons.size():
			var poly = segment_polygons[i]
			if point_in_polygon(mouse_pos, poly):
				_on_segment_hover(i)
				if event is InputEventMouseButton and event.pressed:
					print("Clicked segment", i)
				return
		
		if hovered_segment != -1:
			_on_segment_hover_left(hovered_segment)
			if _popup_tween:
				_popup_tween.kill()
			
			_popup_instance.hide()



#func draw_pie_segment(center: Vector2, radius: float, start_angle: float, end_angle: float, color: Color, index: int, highlited: bool = false) -> void:
func draw_pie_segment(index: int, color: Color, highlited: bool = false) -> void:
	if highlite_type == HighliteType.NONE or not highlited:
		_draw_basic_segment_with_border(index, color)
		return
	
	var start_angle = segment_angles[index].x
	var end_angle = segment_angles[index].y
	
	match highlite_type:
		HighliteType.EXPAND:
			#_draw_expand(index: int, start_angle: float, end_angle: float, color: Color, highlite_state: HighlightState):
			_draw_expand(index, start_angle, end_angle, color, highlite_states[index])
		HighliteType.EXPAND_DIM_OTHERS:
			_draw_expand(index, start_angle, end_angle, color, highlite_states[index])
		HighliteType.SHRINK:
			_draw_custom_segment_with_border(index, color, start_angle, end_angle, center, radius * 0.92)
		HighliteType.RAISE:
			_draw_raise(index, color)
		HighliteType.SCALE_UP:
			_draw_custom_segment_with_border(index, color, start_angle, end_angle, center, radius * 1.1)
		HighliteType.GLOW:
			_draw_glow(index, start_angle, end_angle, color)
		HighliteType.DIM_OTHERS:
			_draw_basic_segment_with_border(index, color)
		HighliteType.BORDER:
			_draw_basic_segment_with_border(index, color)
			_draw_border(center, radius, start_angle, end_angle)
		HighliteType.OUTLINE_FADE:
			_draw_outline_fade(index, center, radius, start_angle, end_angle, color)
		HighliteType.LABEL_ONLY:
			_draw_basic_segment_with_border(index, color)
			# Label logic should be outside TBD
		HighliteType.LIGHTER:
			_draw_basic_segment_with_border(index, color.lightened(0.2))
		HighliteType.DARKER:
			_draw_basic_segment_with_border(index , color.darkened(0.2))
			#_draw_basic_pie(center, radius, start_angle, end_angle, color)


func angle_middle(start_angle: float, end_angle: float) -> float:
	var delta = fmod((end_angle - start_angle + TAU), TAU)
	return fmod(start_angle + delta * 0.5, TAU)


func point_in_polygon(point: Vector2, polygon: PackedVector2Array) -> bool:
	var inside := false
	var j := polygon.size() - 1
	
	for i in polygon.size():
		var pi = polygon[i]
		var pj = polygon[j]
		
		if ((pi.y > point.y) != (pj.y > point.y)):
			var x_intersect = (pj.x - pi.x) * (point.y - pi.y) / (pj.y - pi.y + 0.00001) + pi.x
			if point.x < x_intersect:
				inside = !inside
		j = i
	
	return inside


#func _draw_basic_pie(center: Vector2, radius: float, start_angle: float, end_angle: float, color: Color):
	#_draw_segment_with_border(center, radius, start_angle, end_angle, color)


#func _draw_segment_with_border(center: Vector2, radius: float, start_angle: float, end_angle: float, color: Color, inner_radius_factor := 1):
func _draw_custom_segment_with_border(index: int, color: Color, start_angle: float, end_angle: float, custom_center: Vector2 = Vector2(-1,-1), custom_radius: float = -1):
	var points: PackedVector2Array = [custom_center]
	var segments = 24
	
	for i in range(segments + 1):
		var t = lerp(start_angle, end_angle, float(i) / segments)
		points.append(custom_center + Vector2(cos(t), sin(t)) * custom_radius)
	
	draw_colored_polygon(points, color)
	
	var current_center: Vector2 
	current_center.x = custom_center.x if custom_center.x >= 0 else center.x
	current_center.y = custom_center.y if custom_center.y >= 0 else center.y 
	
	var current_radius: float = custom_radius if custom_radius > 0 else radius
	
	# Optional: Bogen & Linien für Rand zeichnen
	var outline_color := Color.LIGHT_GRAY
	var line_width := 0.5
	var segment_count = 24
	# Äußerer Bogen
	draw_arc(current_center, current_radius, start_angle, end_angle, segment_count, outline_color, line_width, true)
	
	var offset_amount = 0.8
	
	var start_dir = Vector2(cos(start_angle), sin(start_angle))
	var end_dir = Vector2(cos(end_angle), sin(end_angle))
	
	var start_pos = current_center + start_dir * current_radius
	var end_pos = current_center + end_dir * current_radius 
	
	var start_from = current_center + start_dir * offset_amount
	var end_from = current_center + end_dir * offset_amount
	
	draw_line(start_from, start_pos, outline_color, line_width, true)
	draw_line(end_from, end_pos, outline_color, line_width, true)
	
func _draw_basic_segment_with_border(index: int, color: Color):
	#_draw_custom_segment_with_border(index, color, segment_angles[index].x, segment_angles[index].y)
	draw_colored_polygon(segment_polygons[index], color)
	
	var start_angle = segment_angles[index].x
	var end_angle = segment_angles[index].y
	
	# Optional: Bogen & Linien für Rand zeichnen
	var outline_color := Color.LIGHT_GRAY
	var line_width := 0.5
	var segment_count = 24
	# Äußerer Bogen
	draw_arc(center, radius, start_angle, end_angle, segment_count, outline_color, line_width, true)
	
	var offset_amount = 0.8
	
	var start_dir = Vector2(cos(start_angle), sin(start_angle))
	var end_dir = Vector2(cos(end_angle), sin(end_angle))
	
	var start_pos = center + start_dir * radius
	var end_pos = center + end_dir * radius 
	
	var start_from = center + start_dir * offset_amount
	var end_from = center + end_dir * offset_amount
	
	draw_line(start_from, start_pos, outline_color, line_width, true)
	draw_line(end_from, end_pos, outline_color, line_width, true)


func _draw_expand(index: int, start_angle: float, end_angle: float, color: Color, highlite_state: HighlightState):
	var mid_angle = (start_angle + end_angle) * 0.5
	var offset = Vector2(cos(mid_angle), sin(mid_angle)) * radius * 0.05 * highlite_state.seg_offset
	_draw_custom_segment_with_border(index, color, start_angle, end_angle, center + offset, radius)


func _draw_raise(index: int, color: Color):
	var shadow_offset := Vector2(0, -2)
	_draw_custom_segment_with_border(index, color.darkened(0.3), segment_angles[index].x, segment_angles[index].y, center + shadow_offset, radius)
	_draw_basic_segment_with_border(index, color)


func _draw_glow(index: int, start_angle: float, end_angle: float, color: Color):
	for i in range(3):
		var alpha = 0.2 - i * 0.05
		var scale = 1.05 + i * 0.05
		color.a = alpha
		_draw_custom_segment_with_border(index, color, start_angle, end_angle, center, radius * scale)
	_draw_basic_segment_with_border(index, color)


func _draw_border(center: Vector2, radius: float, start_angle: float, end_angle: float):
	var start_point = center + Vector2(cos(start_angle), sin(start_angle)) * radius
	var end_point = center + Vector2(cos(end_angle), sin(end_angle)) * radius
	draw_line(center, start_point, Color.BLACK, 1.0, true)
	draw_line(center, end_point, Color.BLACK, 1.0, true)


func _draw_outline_fade(index: int, center: Vector2, radius: float, start_angle: float, end_angle: float, color: Color):
	_draw_basic_segment_with_border(index, color)
	draw_arc(center, radius, start_angle, end_angle, 64, Color(1, 1, 1, 0.3), 2.0, true)


func _draw_scale_up(center: Vector2, radius: float, start_angle: float, end_angle: float, color: Color):
	var scale := 1.08  # z. B. 8 % größer
	var points: PackedVector2Array = [center]
	var segments := 24
	for i in range(segments + 1):
		var t := lerp(start_angle, end_angle, float(i) / segments)
		var dir := Vector2(cos(t), sin(t))
		points.append(center + dir * radius * scale)
	draw_colored_polygon(points, color)


func _show_popup(center: Vector2, radius: float, angle: float) -> void:
	var offset := Vector2(cos(angle), sin(angle)) * (radius * 0.5)
	var popup_position := center + offset
	
	#_popup_instance.modulate.a = 1.0
	
	if not _popup_instance.visible:
		_popup_instance.position = popup_position + global_position
		_popup_instance.show()
		
	else:
		_popup_tween = create_tween()
		_popup_tween.tween_property(_popup_instance, "position", Vector2i(popup_position + global_position), 0.35)


func _update_segment_polygons():
	segment_polygons.clear()
	
	if datasets.is_empty() or datasets[0].data.is_empty():
		return
	
	var values: Array[float]
	for data in datasets[0].data:
		values.append(data)
	
	#var segment_angles := _get_segment_angles(values)
	
	for index in range(values.size()):
		var points: PackedVector2Array = [center]
		var segments = 24
		
		for i in range(segments + 1):
			var t = lerp(segment_angles[index].x, segment_angles[index].y, float(i) / segments)
			points.append(center + Vector2(cos(t), sin(t)) * radius)
		
		segment_polygons.append(points)

func _update_segment_angles(values: Array[float]) -> void:
	segment_angles.clear()
	segment_angles = _get_segment_angles(values)

func _get_segment_angles(values: Array[float]) -> Array[Vector2]:
	var angles: Array[Vector2]
	var total := values.reduce( func(a, b): return a + b, 0.0)
	var angle_offset := -PI / 2
	for v in values:
		var angle: float = float(v) / total * TAU
		angles.append(Vector2(angle_offset, angle_offset + angle))
		angle_offset += angle
	return angles

func _on_segment_hover(index: int) -> void:
	if hovered_segment != index:
		last_hovered_segment = hovered_segment
		hovered_segment = index

		if last_hovered_segment != -1 and last_hovered_segment < animation_manager.size():
			match highlite_type:
				HighliteType.EXPAND:
					animation_manager[last_hovered_segment].animate_expand_reverse()
		
		if hovered_segment != -1 and hovered_segment < animation_manager.size():
			match highlite_type:
				HighliteType.EXPAND:
					animation_manager[hovered_segment].animate_expand()
			
			var values: Array[float]
			for data in datasets[0].data:
				values.append(data)
			
			var mid = angle_middle(segment_angles[index].x, segment_angles[index].y)
			
			_popup_instance.clear_popup()
			
			var data: OChartPopup.OChartPopupData = OChartPopup.OChartPopupData.new()
			data.data_color = datasets[0].colors[hovered_segment]
			data.data_value = datasets[0].data[hovered_segment]
			data.data_name = datasets[0].labels[hovered_segment]
			
			_popup_instance.add_data(data)
			
			_show_popup(center, radius, mid)


func _on_segment_hover_left(index: int) -> void:
	last_hovered_segment = hovered_segment
	
	match highlite_type:
		HighliteType.EXPAND:
			animation_manager[index].animate_expand_reverse()
	
	hovered_segment = -1
	queue_redraw()


class HighlightState:
	
	signal update_seg()
	
	var seg_offset: float = 0.0:
		set(value):
			if seg_offset != value:
				seg_offset = value
				update_seg.emit()
	var seg_scale: float = 1.0:
		set(value):
			seg_scale = value
			update_seg.emit()
	var glow_alpha: float = 0.0:
		set(value):
			glow_alpha = value
			update_seg.emit()
	var glow_strength: float = 0.0:
		set(value):
			glow_strength = value
			update_seg.emit()

class AnimationManager:
	var tween: Tween
	#var tween_reverse: Tween
	var chart: OPieChart
	var state: HighlightState
	
	func _init(_chart: OPieChart, _state: HighlightState) -> void:
		chart = _chart
		state = _state
	
	func animate_expand() -> void:
		if tween:
			tween.kill()
		tween = chart.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
		tween.tween_property(state, "seg_offset", 1.0, 0.5)
	
	func animate_expand_reverse() -> void:
		if tween:
			tween.kill()
		tween = chart.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
		tween.tween_property(state, "seg_offset", 0.0, 0.5)

	
	func animate_glow() -> void:
		tween.kill()
		tween = chart.create_tween()
		
		tween.tween_property(state, "glow_alpha", 0.2, 0.35)
		tween.set_parallel()
		tween.tween_property(state, "glow_strength", 1.2, 0.35)
