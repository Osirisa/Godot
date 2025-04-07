@tool
class_name ODateLineEdit
extends ORegexLineEdit

## The format in which the date will be displayed and accepted
@export var format: String = "DD.MM.YYYY":
	set(value):
		format = value
		_analyze_format()
		text = text
		placeholder_text = format

## The minimum date in which the entered date can be
@export var min_date: ODate = ODate.new(1,1,1)
## The maximum date in which the entered date can be
@export var max_date: ODate = ODate.new(2199,12,31)

## If the font should change if the date is not valid
@export var change_color := true
## The color the font changes to, if the date is not valid
@export_color_no_alpha var color_not_valid := Color(1, 0, 0)

## Is the date valid
var is_valid := false

var _separators: Array[String]
var _max_digits: int = 0
var _date_regex: String

## Gets the date and returns the ODate object (See ODate Class for more info)
func get_date() -> ODate:
	return ODate.from_string(text, format)

## Sets the date from a ODate object (See ODate Class for more info)
func set_date(date: ODate) -> void:
	text = date.to_string_formatted(format)

func _ready():
	super._ready()
	var callable = Callable(self, "_on_text_changed")
	connect("valid_text_changed", callable)
	
	_analyze_format()

func _enter_tree():
	#regex_validator = "\\d+"
	placeholder_text = format

func _analyze_format() -> void:
	_separators.clear()
	
	var separators = format
	separators = separators.replace("DD","")
	separators = separators.replace("MM","")
	separators = separators.replace("YYYY","")
	separators = separators.replace("YY","")
	
	for char in separators:
		_separators.append(char)
	
	_date_regex = format
	if _separators.size() > 1 and _separators[0] == _separators[1]:
		_date_regex = _date_regex.replace(_separators[0], "\\" + _separators[0] + "?")
	else:
		for separator in _separators:
			_date_regex = _date_regex.replace(separator, "\\" + separator + "?")
	
	_date_regex = _date_regex.replace("YYYY", "(?<year>[0-9]+)?")
	_date_regex = _date_regex.replace("MM", "(?<month>0[1-9]|1[0-2])?")
	_date_regex = _date_regex.replace("DD", "(?<day>0[1-9]|[12][0-9]|3[01])?")
	
	regex_validator = _date_regex
	
	_max_digits = format.length() - _separators.size()

func _on_text_changed(new_text: String) -> void:
	var pos := caret_column
	
	new_text = new_text.strip_edges()
	
	for separator in _separators:
		new_text = new_text.replace(separator, "")
	
	var digits_only := new_text
	
	if digits_only.length() > _max_digits:
		digits_only = digits_only.substr(0, _max_digits)
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
	caret_column = formatted_text.length()
	
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
		if change_color:
			remove_theme_color_override("font_color")
		return 
	
	var year_s := int(matches.get_string("year"))
	var month_s := int(matches.get_string("month"))
	var day_s := int(matches.get_string("day"))
	
	if ODate.is_valid_date(year_s, month_s, day_s):
		is_valid = true
		
		var date := ODate.new(year_s, month_s, day_s)
		if not date.get_difference(min_date) >= 0:
			tooltip_text = "date can't be lower then " + str(min_date)
			is_valid = false
		elif not date.get_difference(max_date) < 0:
			tooltip_text = "date can't be higher then " + str(max_date)
			is_valid = false
	else:
		is_valid = false
	
	if change_color:
		if not is_valid:
			add_theme_color_override("font_color", color_not_valid)
		else:
			remove_theme_color_override("font_color")
