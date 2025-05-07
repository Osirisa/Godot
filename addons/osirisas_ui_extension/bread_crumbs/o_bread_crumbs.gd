@tool
class_name OBreadCrumbs
extends Control

@export var path: Array[String] = []
@export var spacing: int = 8

@export var custom_separator: Control = null
@export var separator_text: String = ">"


var placeholder_width : int = 0
var separator_width: int = 0
var button_sizes := []

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
	
	button_sizes.clear()
	
	for label in path:
		var width = font.get_string_size(label).x + 16
		button_sizes.append(width)
	
	separator_width = font.get_string_size(separator_text).x + spacing
	placeholder_width = font.get_string_size("...").x + 16
	
	var available_width := size.x
	var used_width := 0
	
	var breadcrumbs_vis_idx: Array[int] = []
	
	var first := true
	
	for label_idx in range(path.size() - 1, -1, -1):
		
		
		if available_width >= button_sizes[label_idx] + separator_width:
			breadcrumbs_vis_idx.append(label_idx)
			available_width -= button_sizes[label_idx] + separator_width
			
		elif available_width >= placeholder_width:
			breadcrumbs_vis_idx.append(-1)
			break
			
		else:
			breadcrumbs_vis_idx.pop_back()
			breadcrumbs_vis_idx.append(-1)
			custom_minimum_size.x = placeholder_width
			break
	
	
	
	for label_idx_idx in range(breadcrumbs_vis_idx.size() -1, -1, -1):
		if breadcrumbs_vis_idx[label_idx_idx] == -1:
			first = false
			add_child(create_placeholder_btn())
		else:
			var position_x = calc_positon(breadcrumbs_vis_idx, breadcrumbs_vis_idx[label_idx_idx])
			var label_button = create_label_btn(path[breadcrumbs_vis_idx[label_idx_idx]], breadcrumbs_vis_idx[label_idx_idx])
			add_child(label_button)
			label_button.position.x = position_x
			
			if not first:
				var separator = create_separtor(separator_text) if custom_separator == null else custom_separator
				add_child(separator)
				separator.position.x = position_x - separator_width
			
			first = false


func create_label_btn(label: String, idx: int) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.pressed.connect(_on_breadcrumb_pressed)
	btn.size = Vector2i(button_sizes[idx], size.y)
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	return btn

func create_separtor(separator_txt: String, button: bool = false) -> Control:
	if button:
		var btn := Button.new()
		btn.text = separator_text
		btn.size = Vector2i(separator_width, size.y)
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
		return btn
	else:
		var label := Label.new()
		label.text = separator_text
		label.size = Vector2i(separator_width, size.y)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		return label


func create_placeholder_btn() -> Button:
	var btn := Button.new()
	btn.text = "..."
	btn.pressed.connect(_on_placeholder_pressed)
	btn.size = Vector2i(placeholder_width, size.y)
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	return btn
	#TBD: add dropdown with hidden breadcrumbs

func calc_positon(breadcrumbs_vis_idx: Array[int], label_idx) -> int:
	var pos = 0
	for idx_idx in range(breadcrumbs_vis_idx.size() -1, -1 , -1):
		if breadcrumbs_vis_idx[idx_idx] == label_idx:
			return pos
		else:
			if breadcrumbs_vis_idx[idx_idx] == -1:
				pos += placeholder_width
				pos += separator_width
			else:
				pos += button_sizes[breadcrumbs_vis_idx[idx_idx]]
				pos += separator_width
	
	return 0


func _on_breadcrumb_pressed(index: int) -> void:
	print("Breadcrumb pressed:", index)

func _on_placeholder_pressed():
	print("Ellipsis pressed → optional: Dropdown mit versteckten Breadcrumbs")
