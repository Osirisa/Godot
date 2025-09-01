@tool
class_name ORegexLineEdit
extends LineEdit

signal valid_text_changed(new_text: String)

@export var regex_validator := ".":
	set(value):
		regex_validator = value
		_recompile()

# Optional: leere Eingabe zulassen (Backspace etc.)
@export var allow_empty := true

var _rx := RegEx.new()
var _last_valid_text := ""
var _mutating := false

func _ready() -> void:
	connect("text_changed", Callable(self, "_on_text_changed"))
	_recompile()

func _recompile() -> void:
	var pat := regex_validator
	if not pat.begins_with("^"):
		pat = "^" + pat
	if not pat.ends_with("$"):
		pat += "$"
	var err = _rx.compile(pat)
	if err != OK:
		push_error("Invalid regex pattern: " + regex_validator)

func _full_match(s: String) -> bool:
	if s == "" and allow_empty:
		return true
	var m := _rx.search(s)
	return m != null and m.get_start() == 0 and m.get_end() == s.length()

func _best_valid_prefix(s: String) -> String:
	var best := "" if allow_empty else null
	# gehe von links nach rechts – sobald ein Präfix nicht passt, kann späteres nicht retten
	for i in range(1, s.length() + 1):
		var sub := s.substr(0, i)
		if _full_match(sub):
			best = sub
		else:
			break
	# Falls gar kein Präfix passt, bleib beim letzten gültigen Zustand
	if best == null:
		return _last_valid_text
	return best

func _on_text_changed(new_text: String) -> void:
	if _mutating: return
	var accepted := _best_valid_prefix(new_text)

	if accepted != new_text:
		_mutating = true
		text = accepted
		caret_column = accepted.length() # setz den Cursor ans Ende
		_mutating = false

	if accepted != _last_valid_text:
		_last_valid_text = accepted
		valid_text_changed.emit(accepted)
