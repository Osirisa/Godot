extends Node
class_name O_TableUtility

static func check_column_input(column: int,max_size: int) -> bool:
	if column > max_size:
		push_error("ERROR, parameter row: " + str(column) + " exceeds Array size index: "+ str(max_size))
		return false
	return true

static func check_row_input(row: int, max_size: int) -> bool:
	if row > max_size:
		push_error("ERROR, parameter row: " + str(row) + " exceeds Array size index: "+ str(max_size))
		return false
	return true

static func create_standard_label() -> Label:
	var standard_label = Label.new()
	standard_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	standard_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	standard_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	return standard_label
