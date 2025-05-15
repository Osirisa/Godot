class_name OPieChart
extends Control

enum HighliteType {
	NONE,
	EXPAND,
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
@export var popup := preload("res://addons/osirisas_ui_extension/charts/chart_popup.tscn")

var hovered_segment := -1
var segment_polygons: Array[PackedVector2Array] = []

var _popup_instance: OChartPopup

func _ready():
	focus_mode = Control.FOCUS_ALL
	_popup_instance = popup.instantiate() as OChartPopup
	
	add_child(_popup_instance)
	_popup_instance.data_title = "test"
	var test := _popup_instance.OChartPopupData.new()
	
	_popup_instance.unfocusable = true
	_popup_instance.hide()
	


func _draw() -> void:
	
	if datasets.is_empty() or datasets[0].data.is_empty():
		return
	
	var values := datasets[0].data
	var colors := datasets[0].colors
	var center := size / 2
	var radius: float = min(center.x, center.y) * 0.9

	# Gesamtsumme berechnen
	var total := 0.0
	for v in values:
		total += float(v)

	var angle_offset := -PI / 2
	var segment_angles := []  # Zum Zwischenspeichern der Winkel

	# 1. Alle normalen Segmente zuerst (ohne Hover)
	for i in values.size():
		var value = float(values[i])
		var angle = value / total * TAU
		var start_angle = angle_offset
		var end_angle = angle_offset + angle
		segment_angles.append([start_angle, end_angle])  # Speichern für später
		angle_offset = end_angle

		if i == hovered_segment:
			continue  # wird später separat gezeichnet

		var color = colors[i % colors.size()] if (colors.size() > 0) else Color.GRAY

		if highlite_type == HighliteType.DIM_OTHERS and hovered_segment != -1:
			color = color.darkened(0.4)

		draw_pie_segment(center, radius, start_angle, end_angle, color, false)

	# 2. Hovered Segment zuletzt zeichnen
	if hovered_segment >= 0 and hovered_segment < values.size():
		var color = colors[hovered_segment] if (hovered_segment < colors.size()) else Color.GRAY
		var start_angle = segment_angles[hovered_segment][0]
		var end_angle = segment_angles[hovered_segment][1]

		draw_pie_segment(center, radius, start_angle, end_angle, color, true)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		var mouse_pos := get_local_mouse_position()

		for i in segment_polygons.size():
			var poly = segment_polygons[i]
			if point_in_polygon(mouse_pos, poly):
				if hovered_segment != i:
					hovered_segment = i
					queue_redraw()
				if event is InputEventMouseButton and event.pressed:
					print("Clicked segment", i)
				return

		if hovered_segment != -1:
			hovered_segment = -1
			queue_redraw()
			_popup_instance.hide()


func draw_pie_segment(center: Vector2, radius: float, start_angle: float, end_angle: float, color: Color, highlited: bool = false) -> void:
	if highlite_type == HighliteType.NONE or not highlited:
		_draw_basic_pie(center, radius, start_angle, end_angle, color)
		return

	match highlite_type:
		HighliteType.EXPAND:
			_draw_expand(center, radius, start_angle, end_angle, color)
		HighliteType.SHRINK:
			_draw_basic_pie(center, radius * 0.92, start_angle, end_angle, color)
		HighliteType.RAISE:
			_draw_raise(center, radius, start_angle, end_angle, color)
		HighliteType.SCALE_UP:
			_draw_basic_pie(center, radius * 1.1, start_angle, end_angle, color)
		HighliteType.GLOW:
			_draw_glow(center, radius, start_angle, end_angle, color)
		HighliteType.DIM_OTHERS:
			_draw_basic_pie(center, radius, start_angle, end_angle, color)
			# handled in _draw by dimming others
		HighliteType.BORDER:
			_draw_basic_pie(center, radius, start_angle, end_angle, color)
			_draw_border(center, radius, start_angle, end_angle)
		HighliteType.OUTLINE_FADE:
			_draw_outline_fade(center, radius, start_angle, end_angle, color)
		HighliteType.LABEL_ONLY:
			_draw_basic_pie(center, radius, start_angle, end_angle, color)
			# Label logic should be outside
		#HighliteType.PATTERN:
			#_draw_pattern(center, radius, start_angle, end_angle)
		HighliteType.LIGHTER:
			_draw_basic_pie(center, radius, start_angle, end_angle, color.lightened(0.2))
		HighliteType.DARKER:
			_draw_basic_pie(center, radius, start_angle, end_angle, color.darkened(0.2))
			_draw_basic_pie(center, radius, start_angle, end_angle, color)
		
	if highlited and show_popup:
		_show_popup(center, radius, angle_middle(start_angle, end_angle))


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


func _draw_basic_pie(center: Vector2, radius: float, start_angle: float, end_angle: float, color: Color):
	_draw_segment_with_border(center, radius, start_angle, end_angle, color)


func _draw_segment_with_border(center: Vector2, radius: float, start_angle: float, end_angle: float, color: Color, inner_radius_factor := 1):
	# Füllung kleiner zeichnen
	var fill_radius = radius * inner_radius_factor
	var points: PackedVector2Array = [center]
	var segments = 24
	for i in range(segments + 1):
		var t = lerp(start_angle, end_angle, float(i) / segments)
		points.append(center + Vector2(cos(t), sin(t)) * fill_radius)
	
	segment_polygons.append(points)
	draw_colored_polygon(points, color)

	# Optional: Bogen & Linien für Rand zeichnen
	var outline_color := Color.LIGHT_GRAY
	var line_width := 0.5

	# Äußerer Bogen
	draw_arc(center, radius, start_angle, end_angle, segments, outline_color, line_width, true)

	var offset_amount = 0.8

	var start_dir = Vector2(cos(start_angle), sin(start_angle))
	var end_dir = Vector2(cos(end_angle), sin(end_angle))

	var start_pos = center + start_dir * radius
	var end_pos = center + end_dir * radius 

	var start_from = center + start_dir * offset_amount
	var end_from = center + end_dir * offset_amount

	draw_line(start_from, start_pos, outline_color, line_width, true)
	draw_line(end_from, end_pos, outline_color, line_width, true)


func _draw_expand(center: Vector2, radius: float, start_angle: float, end_angle: float, color: Color):
	var mid_angle = (start_angle + end_angle) * 0.5
	var offset = Vector2(cos(mid_angle), sin(mid_angle)) * radius * 0.05
	_draw_basic_pie(center + offset, radius, start_angle, end_angle, color)


func _draw_raise(center: Vector2, radius: float, start_angle: float, end_angle: float, color: Color):
	var shadow_offset := Vector2(0, -2)
	_draw_basic_pie(center + shadow_offset, radius, start_angle, end_angle, color.darkened(0.3))
	_draw_basic_pie(center, radius, start_angle, end_angle, color)


#func _draw_glow(center: Vector2, radius: float, start_angle: float, end_angle: float, color: Color):
	## Erst normales Segment zeichnen
	#_draw_basic_pie(center, radius, start_angle, end_angle, color)
#
	## Dann Glow auf dem Rand
	#var glow_color := Color(1, 1, 1, 0.2)  # Weiß mit Alpha, alternativ z. B. `color.lightened(0.4)`
	#var glow_width := 2.0                 # Breite der "Leuchtkante"
	#var glow_steps := 8                  # Weiche Kanten durch mehrere Layer
#
	#for i in range(glow_steps):
		#var alpha := glow_color.a * (1.0 - float(i) / glow_steps)
		#var width := glow_width - i * 2.0
		#glow_color.a = alpha
		#draw_arc(center, radius, start_angle, end_angle, 64, glow_color, width, true)


func _draw_glow(center: Vector2, radius: float, start_angle: float, end_angle: float, color: Color):
	for i in range(3):
		var alpha = 0.2 - i * 0.05
		var scale = 1.05 + i * 0.05
		color.a = alpha
		_draw_basic_pie(center, radius * scale, start_angle, end_angle, color)
	_draw_basic_pie(center, radius, start_angle, end_angle, color)


func _draw_border(center: Vector2, radius: float, start_angle: float, end_angle: float):
	var start_point = center + Vector2(cos(start_angle), sin(start_angle)) * radius
	var end_point = center + Vector2(cos(end_angle), sin(end_angle)) * radius
	draw_line(center, start_point, Color.BLACK, 1.0, true)
	draw_line(center, end_point, Color.BLACK, 1.0, true)


func _draw_outline_fade(center: Vector2, radius: float, start_angle: float, end_angle: float, color: Color):
	_draw_basic_pie(center, radius, start_angle, end_angle, color)
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
	
	if not _popup_instance.visible:
		_popup_instance.position = popup_position + global_position
		_popup_instance.show()
		
	else:
		var tween = create_tween()
		tween.tween_property(_popup_instance, "position", Vector2i(popup_position + global_position), 0.35)
	
