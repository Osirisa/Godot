@tool
class_name OBreadCrumbs
extends Control

@export var path: Array[String] = []
@export var spacing: int = 8
@export var separator_text: String = ">"

var _ellipsis_button: Button

func _ready():
	clip_contents = true
	resized.connect(_on_resize)
	_update_breadcrumbs()

func _on_resize():
	_update_breadcrumbs()

func _update_breadcrumbs():
	for child in get_children():
		remove_child(child)
		child.queue_free()

	if path.is_empty():
		return

	var font := get_theme_font("font")

	# Pre-calculate all sizes
	var button_sizes := []
	for label in path:
		var width = font.get_string_size(label).x + 16
		button_sizes.append(width)

	var ellipsis_width := font.get_string_size("...").x + 16
	var separator_width := font.get_string_size(separator_text).x + spacing

	var available_width := size.x
	var used_width := 0
	var visible_indices := []

	# Always show the last breadcrumb
	used_width += button_sizes.back()
	visible_indices.append(path.size() - 1)

	# From end backwards
	for i in range(path.size() - 2, 0, -1):
		var width = button_sizes[i] + separator_width
		if used_width + width + ellipsis_width <= available_width:
			used_width += width
			visible_indices.append(i)
		else:
			break

	# Check if first fits
	var first_width = button_sizes[0] + separator_width
	var show_first = used_width + first_width <= available_width
	if show_first:
		visible_indices.append(0)
	else:
		used_width += ellipsis_width  # space for ellipsis

	visible_indices.sort()

	# Rendering
	var cursor_x = 0
	for i in range(path.size()):
		if visible_indices.has(i):
			# Button
			var btn = Button.new()
			btn.text = path[i]
			btn.pressed.connect(Callable(self, "_on_breadcrumb_pressed").bind(i))
			btn.clip_text = true
			btn.size = Vector2i(button_sizes[i], size.y)
			btn.position = Vector2(cursor_x, 0)
			add_child(btn)
			cursor_x += btn.size.x

			# Separator (except last)
			if i != path.size() - 1:
				var sep = Label.new()
				sep.text = separator_text
				sep.size = Vector2(separator_width, size.y)
				sep.position = Vector2(cursor_x, 0)
				sep.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				add_child(sep)
				cursor_x += separator_width
		elif i == 1 and not show_first:
			# Ellipsis with separators
			var sep_left = Label.new()
			sep_left.text = separator_text
			sep_left.size = Vector2(separator_width, size.y)
			sep_left.position = Vector2(cursor_x, 0)
			sep_left.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			add_child(sep_left)
			cursor_x += separator_width

			_ellipsis_button = Button.new()
			_ellipsis_button.text = "..."
			_ellipsis_button.pressed.connect(_on_ellipsis_pressed)
			_ellipsis_button.size = Vector2(ellipsis_width, size.y)
			_ellipsis_button.position = Vector2(cursor_x, 0)
			add_child(_ellipsis_button)
			cursor_x += ellipsis_width

			var sep_right = Label.new()
			sep_right.text = separator_text
			sep_right.size = Vector2(separator_width, size.y)
			sep_right.position = Vector2(cursor_x, 0)
			sep_right.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			add_child(sep_right)
			cursor_x += separator_width
			break

func _on_breadcrumb_pressed(index: int) -> void:
	print("Breadcrumb pressed:", index)

func _on_ellipsis_pressed():
	print("Ellipsis pressed → optional: Dropdown mit versteckten Breadcrumbs")
