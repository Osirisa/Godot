@tool
class_name ODateLineEdit
extends ORegexLineEdit

@export var format: String = "DD-MM-YYYY"

var _separator: String
var _positions: Array[int] = [0, 0, 0]
var _year_short := false

func _ready():
	var callable = Callable(self, "_on_text_changed")
	connect("text_changed", callable)
	
	placeholder_text = format
	
	super._ready()

func _analyze_format() -> void:
	_positions[0] = format.find("DD")
	
	_positions[1] = format.find("MM")
	
	_positions[2] = format.find("YYYY")
	if _positions[2] == -1:
		_positions[2] = format.find("YY")
		_year_short == true

func _on_text_changed(new_text: String) -> void:
	var sanitized_text = new_text.strip_edges()
	_defer.call_deferred(sanitized_text)

func _defer(input_text: String) -> void:
	var formatted_text = _format_date(input_text)
	if formatted_text != text:
		text = formatted_text
		caret_column = text.length()

func _format_date(input_text: String) -> String:
	var day = ""
	var month = ""
	var year = ""
	
	if input_text.length() > 0:
		day = input_text.substr(0, 2)
	#else:
		#day = input_text.substr(0, 1)
	if input_text.length() >= 2:
		month = input_text.substr(2, 2)
	if input_text.length() > 4:
		year = input_text.substr(4, input_text.length() - 4)
	
	var formatted_date = day
	if month != "":
		var pos = format.find("DD")
		formatted_date += format[pos + 2] + month
	if year != "":
		var pos = format.find("MM")
		formatted_date += format[pos + 2] + year
	
	return formatted_date
