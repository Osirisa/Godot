@tool
class_name ODateLineEdit
extends LineEdit

@export var format: String = "DD-MM-YYYY":
	set(value):
		format = value
		_recompile()


var _date_regex := RegEx.new()

func _ready():
	var callable = Callable(self, "_on_date_changed")
	connect("text_changed", callable)
	
	_recompile()

func _recompile() ->void:
	var regex_pattern = format
	
	regex_pattern = regex_pattern.replace("YYYY", "\\d{4}")
	regex_pattern = regex_pattern.replace("MM", "\\d{2}")
	regex_pattern = regex_pattern.replace("DD", "\\d{2}")
	var error = _date_regex.compile("^" + regex_pattern + "$")
	
	if error != OK:
		push_error("Invalid regex pattern")

func _on_date_changed(new_text):
	if not _date_regex.search(new_text):
		print("invalid")
		delete_char_at_caret()
	else:
		text = new_text
