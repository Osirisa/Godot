@tool
class_name ORegexLineEdit
extends LineEdit

@export var regex_validator := ".":
	set(value):
		regex_validator = value

var _regex_pattern := RegEx.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	var callable = Callable(self, "__on_text_changed")
	connect("text_changed", callable)
	_recompile()

func _recompile() -> void:
	var error = _regex_pattern.compile(regex_validator)
	if error != OK:
		push_error("Invalid regex pattern")

func __on_text_changed(new_text: String) -> void:
	var valid_text := _filter_text(new_text)
	
	if text != valid_text:
		text = valid_text
		caret_column = valid_text.length()

func _filter_text(string_to_filter: String) -> String:
	var matches := _regex_pattern.search_all(string_to_filter)
	var valid_text := ""
	for char_match in matches:
		valid_text += char_match.get_string()
	return valid_text
