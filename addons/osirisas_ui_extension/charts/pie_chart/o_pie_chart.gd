class_name OPieChart
extends Control

@export var data: Array[float] = []
@export var colors: Array[Color] = []
@export var animation_time := 1.0  # Dauer in Sekunden

var current_angles: Array[float] = []
var total := 0.0
var timer := 0.0
var animating := true

func _ready():
	total = data.reduce(func(a, b): return a + b, 0.0)
	current_angles.resize(data.size())
	for i in range(current_angles.size()):
		current_angles[i] = 0.0
	set_process(true)

func _process(delta):
	if animating:
		timer += delta
		var t := clamp(timer / animation_time, 0, 1)
		var sum := 0.0
		for i in range(data.size()):
			var target = data[i] / total * TAU
			current_angles[i] = target * ease_out(t)
			sum += current_angles[i]
		queue_redraw()
		if t >= 1.0:
			animating = false

func ease_out(t):
	return 1.0 - pow(1.0 - t, 3)

func _draw():
	var center := size / 2
	var radius: float = min(center.x, center.y) * 0.9
	var angle_offset := -PI / 2
	var separator_angles := []  # <- Speichere Winkel

	# Erst alle Segmente zeichnen und Winkel sammeln
	for i in range(current_angles.size()):
		var angle = current_angles[i]
		var start_angle = angle_offset
		var end_angle = angle_offset + angle

		draw_pie_segment(center, radius, start_angle, end_angle, colors[i % colors.size()])
		separator_angles.append(start_angle)
		angle_offset = end_angle

	# Danach Separatoren zeichnen (alle außer letzter, optional)
	#var separator_color := Color("92adca")
	#for angle in separator_angles:
		#var start_point = center
		#var end_point = center + Vector2(cos(angle), sin(angle)) * radius
		#draw_line(start_point, end_point, separator_color, 1, true)
	
	## Rahmen um den Pie-Chart
	#var outline_color := Color("92adca")
	#var outline_radius := radius
	#var outline_width := 1
	#var outline_segments := 64  # mehr = glatter
	#draw_arc(center, outline_radius, 0, TAU, outline_segments, outline_color, outline_width, true)



func draw_pie_segment(center: Vector2, radius: float, start_angle: float, end_angle: float, color: Color):
	var points: PackedVector2Array = [center]
	var segments = 24
	for i in range(segments + 1):
		var t = lerp(start_angle, end_angle, float(i) / segments)
		points.append(center + Vector2(cos(t), sin(t)) * radius)
	draw_colored_polygon(points, color)
