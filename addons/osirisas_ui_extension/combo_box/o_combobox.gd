@tool
class_name OComboBox
extends Control

# TODO:
# Fix Length of items when icons disabled
# Fix not correctly adjusting size when changed


## Gets called everytime an item is selected
signal item_selected(index: int)

@export_range(-1,0xFFFFFFFF) var selected:int = -1:
	set(value):
		selected = value
		if items.size() > selected:
			_selected_item = items[selected]

@export var min_length: float = 100

@export var fit_longest_item: bool = true:
	set(value):
		fit_longest_item = value
		
		if fit_longest_item:
			if column_widths:
				_column_sizes_old = column_widths.duplicate()
				_longest_item = _longest_item
		else:
			if column_widths:
				#print(_column_sizes_old)
				if _is_ready:
					column_widths = _column_sizes_old


@export var allow_reselect: bool = false:
	set(value):
		allow_reselect = value
		# TODO::


@export_group("Size")
@export var item_height: float = 30.0:
	set(value):
		item_height = value
		if _o_popup:
			_o_popup.item_height = item_height

@export var max_visible_items: int = 5:
	set(value):
		max_visible_items = max(1, value) # Mindestens 1 Element sichtbar
		_update_popup_size()

@export var column_widths: Array[int] = [30, 30, 100]:
	set(value):
		for i in range (3):
			if value.size() <= i:
				value.append(0)
				
		column_widths = value.slice(0,3)
		
		var total_length: float = 0.0
		for col_size in column_widths:
			total_length += col_size
			
		custom_minimum_size.x = total_length
		#notify_property_list_changed()
		if _o_popup:
			_o_popup.column_widths = column_widths.duplicate(true)


@export_group("Button")
@export var btn_width: float = 30.0:
	set(value):
		btn_width = value
		_pb_popup.custom_minimum_size = Vector2(btn_width, _pb_popup.custom_minimum_size.y)


@export var btn_icon: Texture2D = preload("res://addons/osirisas_ui_extension/combo_box/arrow_drop_down_48dp.svg"):
	set(value):
		btn_icon = value
		_pb_popup.icon = btn_icon


@export_group("Items")
@export var items: Array[OComboBoxItem]:
	set(value):
		var old_size = items.size()
		items = value
		for i in range(old_size, items.size()):
			if not items[i]:
				items[i] = OComboBoxItem.new()
			items[i].id = i
		
		if _o_popup:
			_o_popup.items.clear()
			
			for item in items:
				var new_pop_item := OPopUpListItem.new()
				new_pop_item.checkable = OPopUpListItem.CHECKABLE_SELECT.AS_RADIO_BUTTON
				new_pop_item.disabled = item.disabled
				new_pop_item.text = item.text
				new_pop_item.icon = item.icon
				new_pop_item.id = item.id
				new_pop_item.separator = item.separator
				new_pop_item.visible = item.visible
				
				if item.has_meta("#combobox_item_meta#"):
					new_pop_item.set_meta("#popuplist_item_meta#", item.get_meta("#combobox_item_meta#"))
				
				_o_popup.items.append(new_pop_item)
			_o_popup.build_body()


#Controls
var _p_background: Panel = Panel.new()
var _hb_body: HBoxContainer = HBoxContainer.new()
var _le_search: LineEdit = LineEdit.new()
var _pb_popup: Button = Button.new()

var _is_ready: bool = false

#private vars
var _o_popup: OPopUpList
var _popup_visible: bool = false
var _selected_item: OComboBoxItem

var _longest_item: int = column_widths[2]:
	set(value):
		_longest_item = max(value, min_length)
		
		column_widths[2] = _longest_item
		column_widths = column_widths

var _column_sizes_old: Array[int]

func _init() -> void:
	_o_popup = OPopUpList.new()
	_o_popup.item_selected.connect(_on_item_selected)
	_o_popup.largest_size.connect(_on_size_changed)
	_o_popup.set_unparent_when_invisible(true)


func _enter_tree() -> void:
	self.custom_minimum_size = Vector2(102, 32)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_p_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_p_background.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_p_background.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	add_child(_p_background)
	
	_hb_body.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hb_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_hb_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	_le_search.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_le_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_le_search.text_changed.connect(_on_searchbar_changed)
	_le_search.select_all_on_focus = true
	
	_pb_popup.pressed.connect(toggle_popup)
	_pb_popup.custom_minimum_size = Vector2(btn_width, _pb_popup.custom_minimum_size.y)
	if btn_icon:
		_pb_popup.icon = btn_icon
		_pb_popup.expand_icon = true
		_pb_popup.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	add_child(_hb_body)
	_hb_body.add_child(_le_search)
	_hb_body.add_child(_pb_popup)
	
	column_widths = column_widths
	
	_update_popup_size()
	
	_is_ready = true

func refresh_list() -> void:
	items = items

func add_icon_item(texture: Texture2D, label: String, id: int = -1) -> void:
	_create_new_item(label, id, texture)
	refresh_list()

func add_item(label: String, id: int = -1) -> void:
	_create_new_item(label, id)
	refresh_list()

func add_separator(text: String = "") -> void:
	_create_new_item(text,-1, null, true)
	refresh_list()

func clear() -> void:
	items.clear()
	refresh_list()

func get_item_icon(idx: int) -> Texture2D:
	if items.size() <= idx:
		return null
	return items[idx].icon

func get_item_id(idx: int) -> int:
	if items.size() <= idx:
		return -1
	return items[idx].id

func get_item_index(id: int):
	for i in range(items.size()):
		if items[i].id == id:
			return i
	
	return -1

func get_item_metadata(idx: int) -> Variant:
	if items.size() <= idx:
		return null
	
	return items[idx].get_meta_list()

func get_item_text(idx: int) -> String:
	if items.size() <= idx:
		return ""
	
	return items[idx].text
 
# MAYBE LATER:
#func get_item_tooltip(idx: int) -> String:
	#if items.size() <= idx:
		#return ""

func get_popup() -> OPopUpList:
	return _o_popup

func get_selectable_item(from_last: bool = false) -> int:
	if from_last:
		for i in range(items.size(),-1, -1):
			if not items[i].disabled and not items[i].separator:
				return i
	else:
		for i in range(items.size()):
			if not items[i].disabled and not items[i].separator:
				return i
	
	return -1

func get_selected_id() -> int:
	if _selected_item:
		return _selected_item.id
	
	return -1

func get_selected_metadata() -> Variant:
	if _selected_item and _selected_item.has_meta("#combobox_item_meta#"):
		return _selected_item.get_meta("#combobox_item_meta#")
	return null

func has_selectable_items() -> bool:
	for i in range(items.size()):
		if not items[i].separator and not items[i].disabled:
			return true
	return false

func is_item_disabled(idx: int) -> bool:
	if items.size() <= idx:
		return false
	
	return items[idx].disabled

func is_item_separator(idx: int) -> bool:
	if items.size() <= idx:
		return false
	
	return items[idx].separator

func is_item_visible(idx: int) -> bool:
	if items.size() <= idx:
		return false
	
	return items[idx].visible

func remove_item(idx: int) -> void:
	if items.size() <= idx:
		return
	
	items.remove_at(idx)

func select(idx: int) -> void:
	selected = idx

#func set_disable_shortcuts(disabled: bool) -> void:
	## TODO:
	#return

func set_item_disabled(idx: int, disabled: bool) -> void:
	if items.size() <= idx:
		return
	
	items[idx].disabled = true
	
	refresh_list()

func set_item_icon(idx: int, texture: Texture2D)-> void:
	if items.size() <= idx:
		return
	
	items[idx].icon = texture
	refresh_list()

func set_item_id(idx: int, id: int)-> void:
	if items.size() <= idx:
		return
	
	items[idx].id = id
	refresh_list()

func set_item_metadata(idx: int, metadata: Variant)-> void:
	if items.size() <= idx:
		return
	
	items[idx].set_meta("#combobox_item_meta#", metadata)
	refresh_list()

func set_item_text(idx: int, text: String)-> void:
	if items.size() <= idx:
		return
	items[idx].text = text
	refresh_list()

func set_item_visible(idx: int, visibility: bool) -> void:
	if items.size() <= idx:
		return
	
	items[idx].visible = visibility
	
	refresh_list()

#TODO: Later
#func set_item_tooltip(idx: int, tooltip: String)-> void: 
	## TODO:
	#return

func toggle_popup() -> void:
	if not _popup_visible:
		if _o_popup.get_parent():
			_o_popup.notify_property_list_changed()
			_o_popup.popup()
		else:
			_o_popup.popup_exclusive(self, Rect2i(Vector2i(self.global_position.x, self.global_position.y + self.size.y + 1),Vector2i(self.size.x, _o_popup.size.y)))
		_popup_visible = true
	else:
		_o_popup.hide()
		_popup_visible = false

#func _create_popup() -> void:
	#if not _o_popup:
		#print("newnw")
		#_o_popup = OPopUpListMenu.new()
	
	#item_height = item_height
	#column_widths = column_widths
	#items = items
	#
	#print(items)
	#print(_o_popup.items)


func _update_popup_size():
	if _o_popup:
		var new_height = (item_height * (max_visible_items + 1))
		_o_popup.size.y = new_height

func _create_new_item(text: String,id: int, icon: Texture2D = null, separator: bool = false, disabled: bool = false):
	var new_item := OComboBoxItem.new()
	new_item.icon = icon
	new_item.text = text
	new_item.separator = separator
	new_item.disabled = disabled
	new_item.id = id if id > 0 else items.size()
	items.append(new_item)

func _on_size_changed(new_size: float) -> void:
	if fit_longest_item:
		_longest_item = new_size

func _on_searchbar_changed(new_text: String) -> void:
	for item in items:
		item.visible = new_text.is_empty() or item.text.contains(new_text)
	
	refresh_list()
	
	if not _popup_visible:
		_o_popup.unfocusable = true
		toggle_popup()
		_o_popup.unfocusable = false

func _on_item_selected(index: int) -> void:
	item_selected.emit(index)
	if items.size() > index:
		_selected_item = items[index]
	_le_search.text = _selected_item.text
	toggle_popup()
