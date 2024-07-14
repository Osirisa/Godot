@tool
class_name ODateLineEdit
extends ORegexLineEdit

@export var format: String = "DD.MM.YYYY":
	set(value):
		format = value
		_analyze_format()
		text = text
		placeholder_text = format

@export var min_date: ODate = ODate.new(1,1,1)
@export var max_date: ODate = ODate.new(2199,12,31)

@export var change_color := true
@export_color_no_alpha var color_not_valid

var is_valid := true

var _separators: Array[String]
var _max_digits: int = 0
var _date_regex: String

func get_date() -> ODate:
	return ODate.from_string(text,format)

func set_date(date: ODate) -> void:
	text = date.to_string_formatted(format)

func _ready():
	super._ready()
	var callable = Callable(self, "_on_text_changed")
	connect("text_changed", callable)
	
	_analyze_format()

func _analyze_format() -> void:
	_separators.clear()
	
	_date_regex = format
	
	_date_regex = _date_regex.replace("YYYY", "(?<year>[0-9]+)")
	_date_regex = _date_regex.replace("MM", "(?<month>[0-9]{2})")
	_date_regex = _date_regex.replace("DD", "(?<day>[0-9]{2})")
	
	var separators = format
	separators = separators.replace("DD","")
	separators = separators.replace("MM","")
	separators = separators.replace("YYYY","")
	separators = separators.replace("YY","")
	
	for char in separators:
		_separators.append(char)
	
	_max_digits = format.length() - _separators.size()


func _on_text_changed(new_text: String) -> void:
	var pos := caret_column
	
	new_text = text
	new_text = new_text.strip_edges()
	
	for separator in _separators:
		new_text.replace(separator,"")
	var digits_only := new_text
	
	if digits_only.length() > _max_digits:
		digits_only = digits_only.substr(0,8)
	
	var formatted_text := ""
	var digit_idx: int = 0
	
	for i in range(format.length()):
		if digit_idx >= digits_only.length():
			break
		var cur_char = format[i]
		if cur_char in _separators:
			formatted_text += cur_char
			pos += 1
		else:
			formatted_text += digits_only[digit_idx]
			digit_idx += 1
	
	set_block_signals(true)
	text = formatted_text
	set_block_signals(false)
	caret_column = pos
	
	_validate_date()

func _validate_date() -> void:
	is_valid = false
	
	var regex = RegEx.new()
	var error = regex.compile(_date_regex)
	
	if error != OK:
		push_error("Invalid regex pattern")
		return 
	
	var matches = regex.search(text)
	
	if not matches:
		remove_theme_color_override("font_color")
		return 
	
	var year_s := int(matches.get_string("year"))
	var month_s := int(matches.get_string("month"))
	var day_s := int(matches.get_string("day"))
	
	if ODate.is_valid_date(year_s, month_s, day_s):
		is_valid = true
	
	var date := ODate.new(year_s, month_s, day_s)
	if date.get_difference(min_date) >= 0 and is_valid == true:
		is_valid = true
	else:
		is_valid = false
	
	if date.get_difference(max_date) < 0 and is_valid == true:
		is_valid = true
	else:
		is_valid = false
	
	if is_valid:
		remove_theme_color_override("font_color")
	else:
		add_theme_color_override("font_color", color_not_valid)
