@tool
class_name OComboBox
extends Control

## Gets called everytime an item is selected
signal item_selected(index: int)

@export_range(-1,0xFFFFFFFF) var selected:int = -1:
	set(value):
		selected = value
		# TODO::

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
				
		# TODO::

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

@export var column_widths: Array[int] = [30, 30, 100]:
	set(value):
		for i in range (3):
			if value.size() <= i:
				value.append(0)
				
		column_widths = value.slice(0,3)
		
		var total_length: float
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
			print("cleard")
			for item in items:
				var new_pop_item := OPopUpListItem.new()
				
				new_pop_item.checkable = OPopUpListItem.CHECKABLE_SELECT.AS_RADIO_BUTTON
				new_pop_item.disabled = item.disabled
				new_pop_item.text = item.text
				new_pop_item.icon = item.icon
				new_pop_item.id = item.id
				new_pop_item.separator = item.separator
				print("append")
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
var _longest_item: int = column_widths[2]:
	set(value):
		_longest_item = max(value, min_length)
		
		column_widths[2] = _longest_item
		column_widths = column_widths

var _column_sizes_old: Array[int]

func _init() -> void:
	_o_popup = OPopUpList.new()
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
	
	_pb_popup.pressed.connect(show_popup)
	_pb_popup.custom_minimum_size = Vector2(btn_width, _pb_popup.custom_minimum_size.y)
	if btn_icon:
		_pb_popup.icon = btn_icon
		_pb_popup.expand_icon = true
		_pb_popup.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	add_child(_hb_body)
	_hb_body.add_child(_le_search)
	_hb_body.add_child(_pb_popup)
	
	column_widths = column_widths
	_is_ready = true

func add_icon_item(texture: Texture2D, label: String, id: int = -1) -> void:
	# TODO:
	return

func add_item(label: String, id: int = -1) -> void:
	# TODO:
	return

func add_separator(text: String = "") -> void:
	# TODO:
	return

func clear() -> void:
	# TODO:
	return

func get_item_icon(idx: int) -> Texture2D:
	# TODO:
	return null

func get_item_id(idx: int) -> int:
	# TODO:
	return 0

func get_item_index(id: int):
	# TODO:
	return 0

func get_item_metadata(idx: int) -> Variant:
	# TODO:
	return null

func get_item_text(idx: int) -> String:
	# TODO:
	return ""
 
func get_item_tooltip(idx: int) -> String:
	# TODO:
	return ""

func get_popup() -> OPopUpList:
	return _o_popup

func get_selectable_item(from_last: bool = false) -> int:
	# TODO:
	return 0

func get_selected_id() -> int:
	# TODO:
	return 0

func get_selected_metadata() -> Variant:
	# TODO:
	return null

func has_selectable_items() -> bool:
	# TODO:
	return false

func is_item_disabled(idx: int) -> bool:
	# TODO:
	return false

func is_item_separator(idx: int) -> bool:
	# TODO:
	return false

func remove_item(idx: int) -> void:
	# TODO:
	return

func select(idx: int) -> void:
	# TODO:
	return 

func set_disable_shortcuts(disabled: bool) -> void:
	# TODO:
	return

func set_item_disabled(idx: int, disabled: bool) -> void:
	# TODO:
	return

func set_item_icon(idx: int, texture: Texture2D)-> void:
	# TODO:
	return

func set_item_id(idx: int, id: int)-> void:
	# TODO:
	return

func set_item_metadata(idx: int, metadata: Variant)-> void:
	# TODO:
	return

func set_item_text(idx: int, text: String)-> void:
	# TODO:
	return

func set_item_tooltip(idx: int, tooltip: String)-> void:
	# TODO:
	return

func show_popup() -> void:
	if _o_popup.get_parent():
		_o_popup.notify_property_list_changed()
		_o_popup.popup()
	else:
		_o_popup.popup_exclusive(self, Rect2i(Vector2i(self.global_position.x, self.global_position.y + self.size.y + 1),Vector2i(self.size.x, _o_popup.size.y)))

#func _create_popup() -> void:
	#if not _o_popup:
		#print("newnw")
		#_o_popup = OPopUpListMenu.new()
	#_o_popup.largest_size.connect(_on_size_changed)
	#item_height = item_height
	#column_widths = column_widths
	#items = items
	#
	#print(items)
	#print(_o_popup.items)

func _on_size_changed(new_size: float) -> void:
	if fit_longest_item:
		_longest_item = new_size
