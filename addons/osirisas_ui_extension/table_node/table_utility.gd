extends Node
class_name TableUtility

static func check_column_input(column:int,max_size:int) -> bool:
	if column > max_size:
		push_error("ERROR, parameter row: " + str(column) + " exceeds Array size index: "+ str(max_size))
		return false
	return true

static func check_row_input(row:int, max_size:int) -> bool:
	if row > max_size:
		push_error("ERROR, parameter row: " + str(row) + " exceeds Array size index: "+ str(max_size))
		return false
	return true
