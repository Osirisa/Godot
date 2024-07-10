@tool
class_name ODateLineEdit
extends LineEdit

@export var format: String = "DD-MM-YYYY":
	set(value):
		format = value
		_recompile()


var _date_regex := RegEx.new()

func _ready():
	var callable = Callable(self, "_on_text_changed")
	connect("text_changed", callable)
	
	_recompile()

func _recompile() ->void:
	var regex_pat = format
	
	regex_pat = regex_pat.replace("YYYY", "\\d{0,4}")
	regex_pat = regex_pat.replace("MM", "\\d{0,2}")
	regex_pat = regex_pat.replace("DD", "\\d{0,2}")
	
	print(regex_pat)
	var error = _date_regex.compile("^" + regex_pat + "$")
	if error != OK:
		push_error("Invalid regex pattern")
	
func _on_text_changed(new_text):
	# Validate the input text
	var match = _date_regex.search(new_text)

	if match:
		var year = match.get_string(1)
		var month = match.get_string(2)
		var day = match.get_string(3)
		print(O_Date.is_valid_date(int(year), int(month), int(day)))
		# Check if the date is complete and valid
		if year.length() == 4 and month.length() == 2 and day.length() == 2:
			
			if O_Date.is_valid_date(int(year), int(month), int(day)):
				add_theme_color_override("font_color", Color(0, 1, 0))  # Green text for valid date
			else:
				add_theme_color_override("font_color", Color(1, 0, 0))  # Red text for invalid date
		else:
			add_theme_color_override("font_color", Color(1, 1, 1))  # Default text color for incomplete input
	else:
		add_theme_color_override("font_color", Color(1, 0, 0))  # Red text for invalid input
