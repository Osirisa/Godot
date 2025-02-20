@tool
class_name ORegexLineEdit
extends LineEdit

signal valid_text_changed(new_text: String)

@export var regex_validator := r"\d+([.,]\d{0,2})?":
	set(value):
		regex_validator = value
		_recompile()

var _regex_pattern := RegEx.new()

func _ready():
	connect("text_changed", Callable(self, "__on_text_changed"))
	_recompile()

func _recompile() -> void:
	var error = _regex_pattern.compile(regex_validator)  # Regex direkt kompilieren, kein ^ oder $
	if error != OK:
		push_error("Invalid regex pattern: " + regex_validator)

func __on_text_changed(new_text: String) -> void:
	var valid_text := _filter_text(new_text)
	
	if text != valid_text:
		text = valid_text
		caret_column = valid_text.length()
	else:
		valid_text_changed.emit(text)

func _filter_text(string_to_filter: String) -> String:
	# Suche ALLE möglichen Teilmatches des regulären Ausdrucks
	var matches := _regex_pattern.search_all(string_to_filter)
	
	# Falls es Matches gibt, nehme den längsten passenden Teilstring
	if matches.size() > 0:
		var best_match = ""
		for match in matches:
			var match_str = match.get_string()
			if match_str.length() > best_match.length():
				best_match = match_str
		return best_match
	
	# Falls nichts passt, gebe einen leeren String zurück
	return ""
