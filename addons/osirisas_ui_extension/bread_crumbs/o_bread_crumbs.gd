@tool
class_name OBreadCrumbs
extends Control

signal breadcrumb_pressed(index: int)

@export var spacing: int = 8

@export var custom_separator: Control = null
@export var separator_text: String = ">"
@export var placeholder_text: String = "..."

@export_group("behaviour")
@export var trim_after_click: bool = false


var _placeholder_width : int = 0
var _separator_width: int = 0

var _button_sizes := []
var _path: Array[OBreadCumbElement] = []


var _popup := OPopup.new()
var _list := ItemList.new()

func _ready():
	clip_contents = true
	resized.connect(_on_resize)
	_update_breadcrumbs()
	
	_popup.hide_on_unfocus = false
	_popup.borderless = true
	
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	#_list.item_selected.connect(_on_path_button_pressed)
	_popup.add_child(_list)
	add_child(_popup)
	#_popup.hide()


func _on_resize():
	_update_breadcrumbs()

#region public

func add_element(element: OBreadCumbElement) -> void:
	_path.append(element)
	_update_breadcrumbs()


func add_element_(element_name: String, callable: Callable) -> void:
	var new_element := OBreadCumbElement.new()
	new_element.element_name = element_name
	new_element.callable = callable
	
	_path.append(new_element)
	_update_breadcrumbs()


func remove_element_at(idx: int) -> void:
	_path.remove_at(idx)
	_update_breadcrumbs()


func remove_last_element() -> void:
	_path.pop_back()
	_update_breadcrumbs()

##Clears the path array
func clear_elements() -> void:
	_path.clear()
	_update_breadcrumbs()

##Trims the path array to the last index (last index will also get deleted)
func trim_path(last_index: int) -> void:
	if _path.size() > last_index:
		_path = _path.slice(0, last_index) 
		_update_breadcrumbs()


func get_path_names() -> Array[String]:
	return _path.map(func(el): return el.element_name)


func get_path_size() -> int:
	return _path.size()


func get_element(index: int) -> OBreadCumbElement:
	return _path[index]


func get_last_element() -> OBreadCumbElement:
	return _path.back()

#endregion


#region private
func _update_breadcrumbs():
	for child in get_children():
		remove_child(child)
		child.queue_free()
	
	if _path.is_empty():
		return
	
	var font := get_theme_font("font")
	
	_button_sizes.clear()
	
	for element in _path:
		var width = font.get_string_size(element.element_name).x + 16
		_button_sizes.append(width)
	
	if custom_separator != null:
		_separator_width = custom_separator.size.y
	else:
		_separator_width = font.get_string_size(separator_text).x + spacing
	
	_placeholder_width = font.get_string_size(placeholder_text).x + 16
	
	var breadcrumbs_vis_idx: Array[int] = []
	
	var fits_all = _does_all_fit()

	if fits_all:
		for i in range(_path.size() - 1, -1, -1):
			breadcrumbs_vis_idx.append(i)
	else:
		var available_width = size.x - _placeholder_width
		for i in range(_path.size() - 1, -1, -1):
			var cost = _button_sizes[i]
			cost += _separator_width
			
			if available_width >= cost:
				breadcrumbs_vis_idx.append(i)
				available_width -= cost
			else:
				break
		
		breadcrumbs_vis_idx.append(-1)
		custom_minimum_size.x = _placeholder_width
	
	var first := true
	
	for idx in range(breadcrumbs_vis_idx.size() -1, -1, -1):
		var label_idx := breadcrumbs_vis_idx[idx]
		
		if label_idx == -1:
			first = false
			add_child(_create_placeholder_btn())
			continue
		
		var position_x = _calc_positon(breadcrumbs_vis_idx, label_idx)
		var label_button = _create_label_btn(_path[label_idx].element_name, _path[label_idx].callable, label_idx)
		add_child(label_button)
		label_button.position.x = position_x
		
		if not first:
			var separator = _create_separtor(separator_text) if custom_separator == null else custom_separator
			add_child(separator)
			separator.position.x = position_x - _separator_width
		
		first = false


func _create_label_btn(label: String, callable: Callable, idx: int) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.pressed.connect(_on_path_button_pressed.bind(idx))
	btn.size = Vector2i(_button_sizes[idx], size.y)
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	return btn

func _create_separtor(separator_txt: String, button: bool = false) -> Control:
	if button:
		var btn := Button.new()
		btn.text = separator_text
		btn.size = Vector2i(_separator_width, size.y)
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
		return btn
	else:
		var label := Label.new()
		label.text = separator_text
		label.size = Vector2i(_separator_width, size.y)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		return label


func _create_placeholder_btn() -> Button:
	var btn := Button.new()
	btn.text = placeholder_text
	btn.pressed.connect(_on_placeholder_pressed)
	btn.size = Vector2i(_placeholder_width, size.y)
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	return btn
	#TBD: add dropdown with hidden breadcrumbs

func _calc_positon(breadcrumbs_vis_idx: Array[int], label_idx) -> int:
	var pos = 0
	for idx in range(breadcrumbs_vis_idx.size() -1, -1 , -1):
		var breadcrumb_index = breadcrumbs_vis_idx[idx]
		if breadcrumb_index == label_idx:
			return pos 
		else:
			if breadcrumb_index == -1:
				pos += _placeholder_width
				pos += _separator_width
			else:
				pos += _button_sizes[breadcrumb_index]
				pos += _separator_width
	
	return 0


func _does_all_fit() -> bool:
	var total_width = 0
	for i in range(_path.size()):
		var separator = 0 if i == 0 else _separator_width
		total_width += _button_sizes[i] + separator
	
	return total_width <= size.x
#endregion


func _on_path_button_pressed(index: int) -> void:
	if _path[index].callable.is_valid():
		_path[index].callable.call()
	
	if trim_after_click:
		trim_path(index + 1)
	
	breadcrumb_pressed.emit(index)


func _on_placeholder_pressed():
	_popup.show()
	_popup.open_popup(Vector2i(global_position.x, global_position.y + size.y))
