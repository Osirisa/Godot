@tool
class_name OAdvancedOptionButton
extends Control

signal item_selected(index: int, item: OAdvancedOptionBtnItem)

enum PopupSpawnDirection {
	TOP,
	BOTTOM,
	LEFT,
	RIGHT,
}

const ITEM_SIZE_HEIGHT: int = 35

@export_group("Search")
@export var enable_search: bool = true:
	set(value):
		enable_search = value
		if is_node_ready():
			if enable_search:
				_input_le.editable = true
				_input_le.placeholder_text = placeholder_text
			else:
				_input_le.editable = false
				_input_le.placeholder_text = "" 
			
@export var placeholder_text: String = "Search..."  # Platzhalter für die Suche
@export var enable_fuzzy_search: bool = false  # Fuzzy-Suche aktivieren

@export_group("Items")
@export var items: Array[OAdvancedOptionBtnItem] = []  # Alle möglichen Items.
@export var max_visible_items: int = 10  # Maximale Anzahl sichtbarer Elemente

@export_group("Behaviour")
@export var popup_direction: PopupSpawnDirection = PopupSpawnDirection.BOTTOM:
	set(value):
		popup_direction = value
		if is_node_ready():
			_tr_button_icon.texture = get_popup_icon()

@export var auto_open_popup: bool = true  # Popup automatisch öffnen, wenn gefiltert wird
@export var close_on_select: bool = true  # Popup schließen, wenn Item ausgewählt wird
@export var disable_auto_complete: bool = false  # Automatisches Übernehmen der Auswahl verhindern
@export var scroll_sensitivity: int = 1  # Wie viele Elemente beim Scrollen gesprungen wird
@export var behaviour_type: bool = true

@export_category("Textures")
@export var button_icon_up: Texture2D = load("res://addons/osirisas_ui_extension/shared_ressources/arrow_drop_up.svg")
@export var button_icon_down: Texture2D = load("res://addons/osirisas_ui_extension/shared_ressources/arrow_drop_down.svg")
@export var button_icon_right: Texture2D = load("res://addons/osirisas_ui_extension/shared_ressources/arrow_right.svg")
@export var button_icon_left: Texture2D = load("res://addons/osirisas_ui_extension/shared_ressources/arrow_left.svg")

var current_index: int = -1

var _filtered_items: Array[OAdvancedOptionBtnItem] = []

#var _popup: OPopup
var _popup: Control
var _popup_rect := Rect2i()

var _scroll_container := ScrollContainer.new()
var _list := ItemList.new()
var _input_le := LineEdit.new()

var _hbox := HBoxContainer.new()
var _tr_button_icon := TextureRect.new()


func _init() -> void:
	connect("resized", Callable(self, "_on_resized"))
	custom_minimum_size = custom_minimum_size if Vector2i(92, 31) < Vector2i(custom_minimum_size) else Vector2i(92, 31) 


func _ready() -> void:
	_hbox.anchors_preset = Control.PRESET_FULL_RECT
	_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_hbox.add_theme_constant_override("separation", 0)
	_hbox.size = size
	add_child(_hbox)
	
	# Suchfeld (oben)
	_input_le 
	_input_le.placeholder_text = placeholder_text
	_input_le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input_le.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_input_le.size_flags_stretch_ratio = 1.0
	_input_le.text_changed.connect(_on_filter_changed)
	_input_le.select_all_on_focus = true
	
	_input_le.focus_entered.connect(func(): 
		if auto_open_popup: _show_popup_if_needed()
	)
	
	
	if not enable_search:
		_input_le.editable = false
		_input_le.placeholder_text = ""
	
	_hbox.add_child(_input_le)
	
	# Dropdown-Button
	var button = Button.new()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	button.size_flags_stretch_ratio = 0.15
	button.pressed.connect(_on_dropdown_btn_pressed)
	
	_tr_button_icon.layout_mode = 1
	_tr_button_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tr_button_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED 
	_tr_button_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tr_button_icon.texture = get_popup_icon()
	
	button.add_child(_tr_button_icon)
	_hbox.add_child(button)
	
	# Popup (Dropdown-Menu)
	#_popup = OPopup.new()
	#_popup.borderless = true
	#_popup.hide_on_unfocus = true
	#_popup.hide()
	#_popup.focused.connect(_on_popup_focused)
	
	_popup = Control.new()
	get_window().add_child.call_deferred(_popup)
	
	_popup.hide()
	_popup_rect = get_popup_position_and_size()
	
	#add_child(_popup)
	
	# ScrollContainer für die Liste
	_scroll_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll_container.custom_minimum_size.y = min(max_visible_items, items.size()) * ITEM_SIZE_HEIGHT  # Größe begrenzen
	_popup.add_child(_scroll_container)

	# Liste mit Items
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.item_selected.connect(_on_item_selected)
	_scroll_container.add_child(_list)
	
	_filtered_items = items
	_update_list()


func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_scroll_select(-scroll_sensitivity)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_scroll_select(scroll_sensitivity)
			accept_event()


func _input(event: InputEvent) -> void:
	#if event is InputEventMouseMotion and (event.relative.x + event.relative.y) > 0 and _popup.visible and _popup_rect.has_point(event.global_position):
		#_popup.grab_focus()
	if event is InputEventKey and event.pressed:
		if event.key_label == KEY_ESCAPE:
			_popup.hide()
		elif event.key_label == KEY_UP and _input_le.has_focus():
			close_on_select = false
			_scroll_select(-1)
			_list.get_v_scroll_bar().ratio = float(current_index) / max(_filtered_items.size(), 1)
			close_on_select = true
		elif event.key_label == KEY_DOWN and _input_le.has_focus():
			close_on_select = false
			_scroll_select(1)
			_list.get_v_scroll_bar().ratio = float(max(current_index - (max_visible_items - 1), 0.0)) / max(_filtered_items.size(), 1)
			close_on_select = true
		elif  event.key_label == KEY_ENTER and _popup.visible:
			_toggle_popup()


#region interface

func set_items(new_items: Array[String]) -> void:
	for item_text: String in new_items:
		items.append(OAdvancedOptionBtnItem.new(item_text, items.size()))
	
	_filtered_items = items.duplicate(true)
	_update_list()


func add_icon_item(texture: Texture2D, label: String, id: int = -1) -> void:
	if id < 0:
		id = items.size()
	
	items.append(OAdvancedOptionBtnItem.new(label, id, texture))
	_filtered_items = items.duplicate(true)
	_update_list()


func add_item(label: String, id: int = -1, meta: Variant = null) -> void:
	if id < 0:
		id = items.size()
	
	items.append(OAdvancedOptionBtnItem.new(label, id, null, meta))
	_filtered_items = items.duplicate(true)
	_update_list()


func add_separator(text: String = "") -> void:
	var id = items.size()
	items.append(OAdvancedOptionBtnItem.new(text, id, null, null, true, true))
	_update_list()


func clear():
	_list.clear()
	items.clear()
	_filtered_items.clear()


func get_item_icon(idx: int, get_unfiltered: bool = false) -> Texture2D:
	if get_unfiltered:
		return items[idx].icon
	
	else:
		return _filtered_items[idx].icon


func get_item_id(idx: int, get_unfiltered: bool = false) -> int:
	if get_unfiltered:
		if items.size() > idx:
			return items[idx].id
		
	else:
		if _filtered_items.size() > idx:
			return _filtered_items[idx].id
	
	return -1


func get_item_index(id: int, get_unfiltered: bool = false) -> int:
	if get_unfiltered:
		for idx in range(items.size()):
			if items[idx].id == id:
				return idx
		
	else:
		for idx in range(_filtered_items.size()):
			if _filtered_items[idx].id == id:
				return idx
	
	return -1


func get_item_metadata(idx: int, get_unfiltered: bool = false) -> Variant:
	if get_unfiltered:
		if items.size() > idx:
			return items[idx].metadata
	
	else:
		if _filtered_items.size() > idx:
			return _filtered_items[idx].metadata
	
	return null


func get_item_text(idx: int, get_unfiltered: bool = false) -> String:
	if get_unfiltered:
		if items.size() > idx:
			return items[idx].label
	
	else:
		if _filtered_items.size() > idx:
			return _filtered_items[idx].label
	
	return ""


#HACK:
#func get_popup() -> OPopup:
	#return _popup


func get_selectable_item(from_last: bool = false, get_unfiltered: bool = false) -> int:
	if get_unfiltered:
		for idx in range(items.size()):
			if not items[idx].disabled:
				return idx
	
	else:
		for idx in range(_filtered_items.size()):
			if not _filtered_items[idx].disabled:
				return idx
	
	return -1


func get_selected_id(get_unfiltered: bool = false) -> int:
	var selected_indexes: PackedInt32Array = _list.get_selected_items()
	
	if selected_indexes.size() > 0:
		return _filtered_items[selected_indexes[0]].id
	
	return -1


func has_selectable_items(get_unfiltered: bool = false) -> bool:
	if get_unfiltered:
		for idx in range(items.size()):
			if not items[idx].disabled:
				return true
	
	else:
		for idx in range(_filtered_items.size()):
			if not _filtered_items[idx].disabled:
				return true
	
	return false


func is_item_disabled(idx: int, get_unfiltered: bool = false) -> bool:
	if get_unfiltered:
		if items.size() > idx:
			return items[idx].disabled
	
	else:
		if _filtered_items.size() > idx:
			return _filtered_items[idx].disabled
	
	return false


func is_item_separator(idx: int, get_unfiltered: bool = false) -> bool:
	if get_unfiltered:
		if items.size() > idx:
			return items[idx].is_separator
	
	else:
		if _filtered_items.size() > idx:
			return _filtered_items[idx].is_separator
	
	return false


func remove_item(idx: int, unfiltered: bool = false) -> void:
	if unfiltered:
		if items.size() > idx:
			items.remove_at(idx)
	
	else:
		if _filtered_items.size() > idx:
			_filtered_items.remove_at(idx)
	
	_update_list()


func select(idx: int) -> void:
	if idx < 0:
		_input_le.text = ""
	
	elif _filtered_items.size() > idx:
		_list.select(idx)
		current_index = idx
		item_selected.emit(idx, _filtered_items[idx])
		_input_le.text = _filtered_items[idx].label
		#_window_timer.stop()
		#_window_timer2.stop()


func set_item_disabled(idx: int, disabled: bool, unfiltered: bool = false) -> void:
	if unfiltered:
		if items.size() > idx:
			items[idx].disabled = disabled
	
	else:
		if _filtered_items.size() > idx:
			_filtered_items[idx].disabled = disabled
	
	_update_list()


func set_item_icon(idx: int, texture: Texture2D, unfiltered: bool = false) -> void:
	if unfiltered:
		if items.size() > idx:
			items[idx].icon = texture
	
	else:
		if _filtered_items.size() > idx:
			_filtered_items[idx].icon = texture
	
	_update_list()


func set_item_id(idx: int, id: int, unfiltered: bool = false) -> void:
	if unfiltered:
		if items.size() > idx:
			items[idx].id = id
	
	else:
		if _filtered_items.size() > idx:
			_filtered_items[idx].id = id


func set_item_metadata(idx: int, metadata: Variant, unfiltered: bool = false) -> void:
	if unfiltered:
		if items.size() > idx:
			items[idx].metadata = metadata
	
	else:
		if _filtered_items.size() > idx:
			_filtered_items[idx].metadata = metadata


func set_item_text(idx: int, text: String, unfiltered: bool = false) -> void:
	if unfiltered:
		if items.size() > idx:
			items[idx].label = text
	
	else:
		if _filtered_items.size() > idx:
			_filtered_items[idx].label = text
	
	_update_list()
#endregion


func show_popup() -> void:
	if not _popup.visible:
		_toggle_popup()


func get_popup_icon() -> Texture2D:
	match popup_direction:
		PopupSpawnDirection.TOP: return button_icon_up
		PopupSpawnDirection.BOTTOM: return button_icon_down
		PopupSpawnDirection.RIGHT: return button_icon_right
		PopupSpawnDirection.LEFT: return button_icon_left
		_: return null


func get_popup_position_and_size() -> Rect2i:
	var pop_size = Vector2i(size.x, _popup.size.y)
	var pop_pos = global_position
	match popup_direction:
		PopupSpawnDirection.TOP: pop_pos.y -= pop_size.y + 2
		PopupSpawnDirection.BOTTOM: pop_pos.y += size.y + 2
		PopupSpawnDirection.RIGHT: pop_pos.x += size.x + 2
		PopupSpawnDirection.LEFT: pop_pos.x -= size.x + 2
	return Rect2i(pop_pos, pop_size)


func _scroll_select(direction: int) -> void:
	var selected = _list.get_selected_items()
	if selected.is_empty():  # Falls noch nie etwas ausgewählt wurde
		var first_valid = get_selectable_item()
		if first_valid != -1:
			_list.select(first_valid)
			_on_item_selected(first_valid)
			
	else:
		var old_index = selected[0]
		var new_index: int = clamp(selected[0] + direction, 0, _list.get_item_count() - 1)
		var offset: int = 0
		
		while is_item_disabled(new_index):
			offset += 1
			new_index = selected[0] + (offset * direction)
			
			if new_index < 0 or new_index > _list.get_item_count() - 1: 
				new_index = old_index
				break
		
		_list.select(new_index)
		_on_item_selected(new_index)


func _update_list() -> void:
	_list.clear()
	for item_idx in range(_filtered_items.size()):
		var item = _filtered_items[item_idx]
	
		if item.is_separator:
			_list.add_item("---" + item.label + "---", item.icon)
			_list.set_item_disabled(item_idx, true)
		else:
			_list.add_item(item.label, item.icon)
		
		_list.set_item_disabled(item_idx, item.disabled)
	
	_popup.size.y = min(max_visible_items, _filtered_items.size()) * ITEM_SIZE_HEIGHT - 8 * max (0 ,min(max_visible_items, _filtered_items.size()) - 1)


func _toggle_popup() -> void:
	if _popup.visible:
		_popup.hide()
	elif _filtered_items.size() > 0:
		_popup_rect = get_popup_position_and_size()
		_popup_rect.size.y = min(max_visible_items, _filtered_items.size()) * ITEM_SIZE_HEIGHT - 8 * max (0 ,min(max_visible_items, _filtered_items.size()) - 1)
		#_popup.open_popup(_popup_rect.position, _popup_rect.size)
		
		_popup.position = _popup_rect.position
		_popup.size = _popup_rect.size
		_popup.show()
		
		#_popup.unfocusable = false

func _on_filter_changed(new_text: String) -> void:
	#if not _popup.unfocusable and behaviour_type:
		#_popup.unfocusable = true
	
	if new_text.is_empty():
		_filtered_items = items.duplicate(true)
	else:
		_filtered_items = _filter_items(new_text)
	current_index = -1
	
	_list.deselect_all()
	_update_list()
	
	if auto_open_popup:
		_show_popup_if_needed()


func _filter_items(query: String) -> Array[OAdvancedOptionBtnItem]:
	if enable_fuzzy_search:
		return items.filter(func(item: OAdvancedOptionBtnItem): return _fuzzy_match(query, item.label))
	else:
		return items.filter(func(item: OAdvancedOptionBtnItem): return query.to_lower() in item.label.to_lower())


func _fuzzy_match(query: String, text: String) -> bool:
	query = query.to_lower()
	text = text.to_lower()
	var qi = 0
	for ti in text.length():
		if query[qi] == text[ti]:
			qi += 1
			if qi == query.length():
				return true
	return false


func _show_popup_if_needed() -> void:
	if not _popup.visible and _filtered_items.size() > 0:
		#if not behaviour_type:
			#_popup.unfocusable = true
		
		_toggle_popup()
		
		#if not behaviour_type:
			#_popup.unfocusable = false

func _on_dropdown_btn_pressed() -> void:
	_show_popup_if_needed()
	_input_le.grab_focus()

func _on_item_selected(index: int) -> void:
	var selected_item: OAdvancedOptionBtnItem = _filtered_items[index]
	
	if not disable_auto_complete:
		_input_le.text = selected_item.label
	
	current_index = index
	item_selected.emit(index, selected_item)
	
	if close_on_select:
		_popup.hide()


func _on_resized() -> void:
	if _hbox:
		_hbox.size = size
