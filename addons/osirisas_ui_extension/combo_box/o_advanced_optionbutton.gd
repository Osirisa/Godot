@tool
class_name OAdvancedOptionButton
extends Control

signal item_selected(index: int, text: String)

enum PopupSpawnDirection {
	TOP,
	BOTTOM,
	LEFT,
	RIGHT,
}

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
@export var items: Array[String] = []  # Alle möglichen Items.
@export var max_visible_items: int = 10  # Maximale Anzahl sichtbarer Elemente

@export_group("Behaviour")
@export var popup_direction: PopupSpawnDirection = PopupSpawnDirection.BOTTOM:
	set(value):
		popup_direction = value
		if is_node_ready():
			match popup_direction:
				PopupSpawnDirection.TOP:
					_tr_button_icon.texture = button_icon_up
				PopupSpawnDirection.BOTTOM:
					_tr_button_icon.texture = button_icon_down
				PopupSpawnDirection.RIGHT:
					_tr_button_icon.texture = button_icon_right
				PopupSpawnDirection.LEFT:
					_tr_button_icon.texture = button_icon_left
				_:
					printerr("unknown direction")
			
@export var auto_open_popup: bool = true  # Popup automatisch öffnen, wenn gefiltert wird
@export var close_on_select: bool = true  # Popup schließen, wenn Item ausgewählt wird
@export var disable_auto_complete: bool = false  # Automatisches Übernehmen der Auswahl verhindern
@export var scroll_sensitivity: int = 1  # Wie viele Elemente beim Scrollen gesprungen wird

@export_category("Textures")
@export var button_icon_up: Texture2D = load("res://addons/osirisas_ui_extension/shared_ressources/arrow_drop_up.svg")
@export var button_icon_down: Texture2D = load("res://addons/osirisas_ui_extension/shared_ressources/arrow_drop_down.svg")
@export var button_icon_right: Texture2D = load("res://addons/osirisas_ui_extension/shared_ressources/arrow_right.svg")
@export var button_icon_left: Texture2D = load("res://addons/osirisas_ui_extension/shared_ressources/arrow_left.svg")

var _filtered_items: Array[String] = []
var _popup: PopupPanel
var _list: ItemList
var _input_le := LineEdit.new()

var _hbox := HBoxContainer.new()
var _tr_button_icon := TextureRect.new()

func _init() -> void:
	connect("resized", Callable(self, "_on_resized"))
	custom_minimum_size = Vector2i(92, 31)

func _ready():
	# Hauptlayout
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
	_input_le.text_changed.connect(_on_text_changed)
	
	if not enable_search:
		_input_le.editable = false
		_input_le.placeholder_text = ""
	
	_hbox.add_child(_input_le)
	
	# Dropdown-Button
	var button = Button.new()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	button.size_flags_stretch_ratio = 0.15
	button.pressed.connect(_toggle_popup)
	
	_tr_button_icon.layout_mode = 1
	_tr_button_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tr_button_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED 
	_tr_button_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	match popup_direction:
		PopupSpawnDirection.TOP:
			_tr_button_icon.texture = button_icon_up
		PopupSpawnDirection.BOTTOM:
			_tr_button_icon.texture = button_icon_down
		PopupSpawnDirection.RIGHT:
			_tr_button_icon.texture = button_icon_right
		PopupSpawnDirection.LEFT:
			_tr_button_icon.texture = button_icon_left
		_:
			printerr("unknown direction")
					
	button.add_child(_tr_button_icon)
	
	_hbox.add_child(button)

	# Popup (Dropdown-Menu)
	_popup = PopupPanel.new()
	_popup.hide()
	add_child(_popup)
	
	# VBox für Liste
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL  # Popup so breit wie Control
	_popup.add_child(vbox)

	# ScrollContainer für die Liste
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size.y = min(max_visible_items, items.size()) * 30  # Größe begrenzen
	vbox.add_child(scroll)

	# Liste mit Items
	_list = ItemList.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.item_selected.connect(_on_item_selected)
	scroll.add_child(_list)

	# Initiale Item-Liste laden
	set_items(items)

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_scroll_select(-scroll_sensitivity)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_scroll_select(scroll_sensitivity)
			accept_event()

func set_items(new_items: Array[String]) -> void:
	items = new_items.duplicate()
	_filtered_items = items
	_update_list()


func add_icon_item(texture: Texture2D, label: String, id: int = -1):
	_list.add_item(label, texture)
	if id == -1:
		id = _list.get_item_count() - 1
	_list.set_item_metadata(_list.get_item_count() - 1, id)
	items.append(label)

func add_item(label: String, id: int = -1):
	_list.add_item(label)
	if id == -1:
		id = _list.get_item_count() - 1
	_list.set_item_metadata(_list.get_item_count() - 1, id)
	items.append(label)

func add_separator(text: String = ""):
	_list.add_item("--- " + text + " ---")
	_list.set_item_disabled(_list.get_item_count() - 1, true)

func clear():
	_list.clear()
	items.clear()

func get_item_icon(idx: int) -> Texture2D:
	return _list.get_item_icon(idx)

func get_item_id(idx: int) -> int:
	return _list.get_item_metadata(idx)

func get_item_index(id: int):
	for i in range(_list.get_item_count()):
		if _list.get_item_metadata(i) == id:
			return i
	return -1

func get_item_metadata(idx: int) -> Variant:
	return _list.get_item_metadata(idx)

func get_item_text(idx: int) -> String:
	return _list.get_item_text(idx)

func get_popup() -> PopupPanel:
	return _popup

func get_selectable_item(from_last: bool = false) -> int:
	for i in range(_list.get_item_count()):
		if not _list.is_item_disabled(i):
			return i
	return -1

func get_selected_id() -> int:
	var selected = _list.get_selected_items()
	if selected.size() > 0:
		return _list.get_item_metadata(selected[0])
	return -1

func has_selectable_items() -> bool:
	return _list.get_item_count() > 0

func is_item_disabled(idx: int) -> bool:
	return _list.is_item_disabled(idx)

func is_item_separator(idx: int) -> bool:
	return _list.get_item_text(idx).begins_with("---")

func remove_item(idx: int):
	_list.remove_item(idx)

func select(idx: int):
	_list.select(idx)
	item_selected.emit(idx, _list.get_item_text(idx))

func set_item_disabled(idx: int, disabled: bool):
	_list.set_item_disabled(idx, disabled)

func set_item_icon(idx: int, texture: Texture2D):
	_list.set_item_icon(idx, texture)

func set_item_id(idx: int, id: int):
	_list.set_item_metadata(idx, id)

func set_item_metadata(idx: int, metadata: Variant):
	_list.set_item_metadata(idx, metadata)

func set_item_text(idx: int, text: String):
	_list.set_item_text(idx, text)

func show_popup():
	_toggle_popup()



func _scroll_select(direction: int):
	var selected = _list.get_selected_items()
	if selected.is_empty():  # Falls noch nie etwas ausgewählt wurde
		var first_valid = get_selectable_item()
		if first_valid != -1:
			_list.select(first_valid)
			_on_item_selected(first_valid)
	else:
		var new_index = clamp(selected[0] + direction, 0, _list.get_item_count() - 1)
		_list.select(new_index)
		_on_item_selected(new_index)

func _update_list():
	_list.clear()
	for item in _filtered_items:
		_list.add_item(item)

func _toggle_popup():
	if _popup.visible:
		_popup.hide()
	else:
		var window = get_window()

		# Falls das Popup einen falschen Parent hat, zuerst entfernen
		if _popup.get_parent() and _popup.get_parent() != window:
			_popup.get_parent().remove_child(_popup)

		# Falls es noch kein Kind des Fensters ist, hinzufügen
		if _popup.get_parent() != window:
			window.add_child(_popup)
		
		var pop_size: Vector2i = Vector2i(size.x, _popup.size.y)
		var pop_pos: Vector2i = Vector2i.ZERO
		
		match popup_direction:
			PopupSpawnDirection.TOP:
				pop_pos = Vector2i(global_position.x, global_position.y - pop_size.y - 2)
			PopupSpawnDirection.BOTTOM:
				pop_pos = Vector2i(global_position.x, global_position.y + size.y + 2)
			PopupSpawnDirection.RIGHT:
				pop_pos = Vector2i(global_position.x + size.x + 2, global_position.y)
			PopupSpawnDirection.LEFT:
				pop_pos = Vector2i(global_position.x - size.x - 2, global_position.y)
			_:
				printerr("unknown direction")
		_popup.popup(Rect2i(pop_pos, pop_size))
		_popup.grab_focus()



func _on_text_changed(new_text: String):
	_input_le.text = new_text
	_input_le.caret_column = _input_le.text.length()
	_on_filter_changed(new_text)
	if auto_open_popup:
		_show_popup_if_needed()

func _on_filter_changed(new_text: String):
	if new_text.is_empty():
		_filtered_items = items.duplicate()
	else:
		_filtered_items = _filter_items(new_text)

	_update_list()
	if auto_open_popup:
		_show_popup_if_needed()

func _filter_items(query: String) -> Array[String]:
	if enable_fuzzy_search:
		return items.filter(func(item): return _fuzzy_match(query, item))
	else:
		return items.filter(func(item): return query.to_lower() in item.to_lower())

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

func _show_popup_if_needed():
	if not _popup.visible and _filtered_items.size() > 0:
		_popup.unfocusable = true
		_toggle_popup()
		_popup.unfocusable = false

func _on_item_selected(index: int):
	var selected_text = _filtered_items[index]
	if not disable_auto_complete:
		_input_le.text = selected_text
	item_selected.emit(index, selected_text)
	if close_on_select:
		_popup.hide()


func _on_resized():
	if _hbox:
		_hbox.size = size
