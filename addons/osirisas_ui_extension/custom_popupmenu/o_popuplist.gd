class_name OPopUpList
extends Popup

signal item_selected(index: int)
signal largest_size(lsize: float)

@export var hide_on_item_selection: bool = true
@export var hide_on_checkable_item_selection: bool = true
#@export var hide_on_state_item_selection: bool = true

@export var items: Array[OPopUpListItem]:
	set(value):
		var old_size = items.size()
		items = value
		for i in range(old_size, items.size()):
			if not items[i]:
				items[i] = OPopUpListItem.new()
			items[i].id = i
		if _is_ready:
			build_body.call_deferred()

@export_group("Size")
@export var max_items: int = 10
@export var item_height: float = 30.0
@export var column_widths: Array[int] = [30, 30, 100]:
	set(value):
		column_widths = value
		if _is_ready:
			_change_column_sizes()

# Controls
var _p_background: Panel = Panel.new()
var _sc_body: ScrollContainer = ScrollContainer.new()
var _vb_body: VBoxContainer = VBoxContainer.new()
#var _columns: Array[VBoxContainer]
var _rows: Array[Control]

# private variables
var cb_group: ButtonGroup = ButtonGroup.new()

var _visibility: Array[bool] = [false, false, false]
var _is_ready: bool = false

var _x_offsets: Array[int]

var _l_text_size: float = 0
var _largest_item: OPopUpListItem

enum COLUMNS{
	CHECKABLES,
	ICON,
	TEXT,
}

func _init() -> void:
	_is_ready = true


func _enter_tree() -> void:
	unresizable = true
	borderless = true
	always_on_top = true
	popup_window = true

func _ready() -> void:
	_p_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_p_background.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_p_background.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	add_child(_p_background)
	
	_sc_body.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sc_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_sc_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_sc_body)
	
	_sc_body.add_child(_vb_body)
	
	build_body.call_deferred()
	
	_is_ready = true


## Clears and builds the whole body
func build_body():
	
	#print("Build Body")
	
	_clear_body()
	_change_column_sizes()
	_refresh_x_offsets_arr()
	#print(_x_offsets)
	
	_visibility = [false, false, false] #reset visibility
	
	var call_item_changed = Callable(self, "_on_item_changed")
	
	_l_text_size = 0
	for i in range(items.size()):
		var item: OPopUpListItem = items[i] as OPopUpListItem
		
		if not item:
			continue
		
		for connection: Dictionary in item.otext_changed.get_connections():
			if connection["callable"] == call_item_changed:
				print("disconnect")
				item.otext_changed.disconnect(call_item_changed)
		
		item.otext_changed.connect(call_item_changed)
		var row = _create_row(item, i)
		_rows.append(row)
		_vb_body.add_child(row)
		
	
	_refresh_x_positions.call_deferred()
	largest_size.emit(_l_text_size)
	_update_visibility()

## Clears all the items and the body
func clear():
	_clear_body()
	items.clear()

func add_item(item: OPopUpListItem) -> void:
	if item:
		items.append(item)

func remove_item(item: OPopUpListItem) -> void:
	items.erase(item)

func remove_index(index: int) -> void:
	if index < items.size():
		items.remove_at(index)


func _update_visibility():
	for i in range(COLUMNS.size()):
		#_columns[i].visible = _visibility[i]
		# TODO::
		pass

func _change_column_sizes():
	for i in range(COLUMNS.size()):
		#var col = _columns[i]
		#col.custom_minimum_size = Vector2(column_widths[i], col.custom_minimum_size.y)
		#TODO::
		pass

func _clear_body():
	for child: Control in _vb_body.get_children():
		if child:
			for c_child in child.get_children():
				c_child.queue_free()
			_vb_body.remove_child(child)
			child.queue_free()
	_rows.clear()

func _get_text_width(text: String) -> float:
	var font: Font = get_theme_font("font", "Button")
	var textsize: Vector2 = font.get_string_size(text)
	
	return textsize.x

func _refresh_x_offsets_arr() -> void:
	_x_offsets.clear()
	
	var offsets: Array[int] = [] 
	offsets.resize(column_widths.size())
	offsets.fill(0)
	for i in range(column_widths.size()):
		if _visibility[i]:
			for x in range (i):
				if _visibility[x]:
					offsets[i] += column_widths[x]
		else:
			if i > 0:
				offsets[i] = offsets[i-1]

	_x_offsets = offsets.duplicate()

func _refresh_x_positions() -> void:
	_refresh_x_offsets_arr()
	#print(_x_offsets)
	
	for row: Control in _rows:
		for i in range(row.get_children().size()):
			var child = row.get_child(i)
			child.custom_minimum_size.x = column_widths[i]
			child.position.x = _x_offsets[i]

func _create_row(item: OPopUpListItem, index: int) -> Control:
	if item.separator:
			return _create_separator_row(item)
	
	var parent := Control.new()
	parent.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.custom_minimum_size.y = item_height
	
	if column_widths[COLUMNS.CHECKABLES] > 0:
		match item.checkable:
			OPopUpListItem.CHECKABLE_SELECT.NO:
				_visibility[COLUMNS.CHECKABLES] = _visibility[COLUMNS.CHECKABLES] or false
				
			OPopUpListItem.CHECKABLE_SELECT.AS_CHECK_BOX:
				_visibility[COLUMNS.CHECKABLES] = true
				
				var check_box := CheckBox.new()
				# Size / Position
				check_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
				check_box.custom_minimum_size.x = column_widths[COLUMNS.CHECKABLES]
				check_box.position.x = _x_offsets[COLUMNS.CHECKABLES]
				parent.add_child(check_box)
				
			OPopUpListItem.CHECKABLE_SELECT.AS_RADIO_BUTTON:
				# Same as "CHECKABLE_SELECT.AS_CHECK_BOX" but with a button group
				_visibility[COLUMNS.CHECKABLES] = true
				
				var check_box := CheckBox.new()
				# Size / Position
				check_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
				check_box.custom_minimum_size.x = column_widths[COLUMNS.CHECKABLES]
				check_box.position.x = _x_offsets[COLUMNS.CHECKABLES]
				
				check_box.button_group = cb_group
				
				parent.add_child(check_box)
			_:
				printerr("UNDEFINED")
	else:
		_visibility[COLUMNS.CHECKABLES] = false
	
	if item.text and column_widths[COLUMNS.TEXT] > 0:
		_visibility[COLUMNS.TEXT] = true
		
		var button := Button.new()
		var call := Callable(self, "_on_btn_pressed").bind(index)
		
		button.pressed.connect(call)
		
		# Size / Position
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.x = column_widths[COLUMNS.TEXT]
		button.position.x = _x_offsets[COLUMNS.TEXT]
		# Text
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.clip_text = true
		button.text = item.text
		
		parent.add_child(button)
		
		var text_width = _get_text_width(item.text)
		if _l_text_size < text_width:
			_l_text_size = text_width
			_largest_item = item
		
	else:
		_visibility[COLUMNS.TEXT] = _visibility[COLUMNS.TEXT] or false
	
	if item.icon and column_widths[COLUMNS.ICON] > 0:
		_visibility[COLUMNS.ICON] = true
		var texture_rect := TextureRect.new()
		texture_rect.texture = item.icon
		texture_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
		texture_rect.custom_minimum_size.x = column_widths[COLUMNS.ICON]
		texture_rect.position.x = _x_offsets[COLUMNS.ICON]
		
		parent.add_child(texture_rect)
	else:
		_visibility[COLUMNS.ICON] = _visibility[COLUMNS.ICON] or false
	
	return parent

func _create_separator_row(item: OPopUpListItem) -> HBoxContainer:
	return HBoxContainer.new()

func _on_btn_pressed(index: int) -> void:
	print(index)
	item_selected.emit(index)

func _on_item_changed(item: OPopUpListItem) -> void:
	print("item changed")
	var new_size = _get_text_width(item.text)
	if _largest_item == item:
		if _l_text_size > new_size:
			_l_text_size = 0
			for item_i:OPopUpListItem in items:
				var new_i_size = _get_text_width(item_i.text)
				if _l_text_size < new_i_size:
					_l_text_size = new_i_size
					_largest_item = item_i
	
	if _l_text_size < new_size:
		_l_text_size = new_size
		_largest_item = item
	
	largest_size.emit(_l_text_size)
