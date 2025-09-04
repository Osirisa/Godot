@tool
class_name OCodeInput
extends Control

## Gets emitted when the user filled out all the positions with the code as a string
## Note: the code won't contain the seperating char / custom seperating control!
signal code_input_finished(code: String)

## format of the Code-Input: 
## use "X" as input and "-" as the position for the seperating_char / custom seperating control
## E.g.: XXX-XX-XX-X
@export var format: String = "":
	set(value):
		format = value
		_generate_code_input()

## The regEx for the Single Input Fields (not the whole Code)
@export var char_regex: String = "^[A-KM-Z0-9]$":
	set(value):
		char_regex = value
		_refresh_regex()

## Converts all input lower case Letters in Uppercase
@export var convert_lower_case: bool = true

## Example: "-": 9X7-85F-65Q | Leave Empty if you use custom Seperating control
@export var seperating_char: String = "":
	set(value):
		seperating_char = value
		_generate_code_input()

@export var custom_control: PackedScene = null:
	set(value):
		custom_control = value
		_generate_code_input()


@export var auto_check: bool = true


var _line_edits: Array[LineEdit] = []
var _hb_input_container: HBoxContainer = null

var _char_regex: RegEx
var _code: String = ""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	_hb_input_container = HBoxContainer.new()
	_hb_input_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hb_input_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hb_input_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_hb_input_container)
	
	_generate_code_input()
	_refresh_regex()


#func code_valid(is_valid: bool) -> void:
	#if is_valid:
		## TBD: Animation
		#pass
	#else:
		#
		## TBD: Animation
		#for i in range(_line_edits.size()):
			#_line_edits[i].text = ""
			#if i > 0:
				#_line_edits[i].editable = false
		#pass

func clear_code_input() -> void:
	for i in range(_line_edits.size()):
		var line_edit = _line_edits[i]
		line_edit.text = false
		if i == 0:
			line_edit.editable = true
		else:
			line_edit.editable = false

func _generate_code_input() -> void:
	if not _hb_input_container:
		return
	
	_clear_hb()
	
	var positions: int = format.length()
	var code_position: int = 0
	
	for i in positions:
		if format[i] == "X":
			
			var pos_le := LineEdit.new()
			
			pos_le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			pos_le.size_flags_vertical = Control.SIZE_EXPAND_FILL
			pos_le.select_all_on_focus = true
			pos_le.alignment = HORIZONTAL_ALIGNMENT_CENTER
			
			if code_position > 0:
				pos_le.editable = false
				pos_le.max_length = 1
			
			_line_edits.append(pos_le)
			
			_hb_input_container.add_child(pos_le)
			
			pos_le.gui_input.connect(_on_le_gui_input.bind(code_position))
			pos_le.text_changed.connect(_on_le_text_changed.bind(code_position))
			code_position += 1
			
		elif format[i] == "-":
			var _sep_char := "-"
			if not seperating_char.is_empty():
				_sep_char = seperating_char
			elif custom_control:
				_sep_char = ""
			
			if not _sep_char.is_empty():
				var sep_label := Label.new()
				sep_label.text = _sep_char
				sep_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				sep_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				
				_hb_input_container.add_child(sep_label)
				
				sep_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				sep_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
				sep_label.size_flags_stretch_ratio = 0.5
			else:
				var cust_control = custom_control.instantiate()
				_hb_input_container.add_child(cust_control)
				cust_control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				cust_control.size_flags_vertical = Control.SIZE_EXPAND_FILL
				pass
		else:
			push_error("Wrong Char in Format only use \"X\" and \"-\" !")
			format = format.replace(format[i],"")
			i -= 1

func _clear_hb() -> void:
	for child in _hb_input_container.get_children():
		_hb_input_container.remove_child(child)
		child.queue_free()

func _refresh_regex() -> void:
	_char_regex = RegEx.new()
	_char_regex.compile(char_regex)


func _check_code_complete() -> bool:
	var code: String = ""
	for code_le in _line_edits:
		if code_le.text.is_empty():
			_code = ""
			return false
		else:
			_code += code_le.text.strip_edges()
	return true

func _on_code_pasted(code: String) -> void:
	for i in range(code.length()):
		_line_edits[i].text = code[i]
		_line_edits[i].editable = true
	
	_line_edits.back().grab_focus()
	_line_edits.back().caret_column = 1
	
	if auto_check:
		code_input_finished.emit(code)

func _on_le_gui_input(event: InputEvent, pos) -> void:
	if event is InputEventKey and event.pressed:
		#if event.keycode == KEY_V and (event.ctrl_pressed or event.meta_pressed):
			#print("Paste via shortcut")
		if event.keycode == KEY_BACKSPACE:
			if _line_edits[pos].text.is_empty():
				if pos > 0:
					_line_edits[pos].editable = false
					_line_edits[pos-1].editable = true
					_line_edits[pos-1].text = ""
					_line_edits[pos-1].grab_focus()

func _on_le_text_changed(new_text: String, pos: int) -> void:
	
	if new_text.length() == format.count("X"):
		_on_code_pasted(new_text)
		return
		
	elif new_text.length() > 1:
		_line_edits[0].text = ""
	
	if convert_lower_case:
		new_text = new_text.to_upper()
		_line_edits[pos].text = new_text
		_line_edits[pos].caret_column = 1
	
	if new_text != "" and _char_regex.search(new_text) == null:
		_line_edits[pos].text = ""
		return
	
	if new_text.length() == 1 and pos < _line_edits.size() - 1:
		_line_edits[pos].editable = false
		_line_edits[pos + 1].editable = true
		_line_edits[pos + 1].grab_focus()
		if not _line_edits[pos + 1].text.is_empty():
			_line_edits[pos + 1].caret_column = 1
	
	if auto_check and _check_code_complete():
		code_input_finished.emit(_code)
