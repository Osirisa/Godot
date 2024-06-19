@tool
class_name TableNode_v2
extends Control

## This Class provides you with a Table where you can add | remove | hide rows and columns
## 
## With the Table you can add | remove | hide rows and columns and fill the cells with
## Control - nodes and its children (preferably Buttons, Line-Edits and Labels 

#-----------------------------------------Signals--------------------------------------------------#

## Signal when the user clicks on a cell
signal cell_clicked(row:int, column:int)

## Signal when the user edits a cell (double click)
signal cell_edit(row:int,column:int)

## Signal when the user edited
signal cell_edit_finished(row:int,column:int)

## Signal when a column sorting was requested
signal column_sort_requested(column: int, sort: Sorting)

## Signal when a column sorting was finished
signal column_sort_finished(column: int, sort: Sorting)

#-----------------------------------------Enums----------------------------------------------------#
enum Sorting {
	ASCENDING,
	DESCENDING,
}
#-----------------------------------------Constants------------------------------------------------#

#-----------------------------------------Export Var-----------------------------------------------#

@export_category("Header")
## The header titles
@export var header_titles: Array[String] = []
## The cell height of the header
@export var header_cell_height := 30

@export_category("Body")
## The starting widths for each column
@export var column_widths: Array[int] = []
## The standard cell dimension a row / a column gets created with
@export var standard_cell_dimension := Vector2i(150,25)

@export_category("Resizing")
## Enables the resizing (drag on the separator for resizing the cells)
@export var resizing := true
## To stop the resizing below a certain threshhold of the cell
@export var min_size := Vector2i(50,20)

@export_category("Special")
@export_group("Culling")
## Culling makes it that only so many rows are being inserted to maximize performacne (For Large Tables)
@export var culling := true
## Count for the maximum simultaneously "Active / inserted" Rows at any Moment 
@export var max_row_count_active_culling := 100

@export_group("Pagination")
## Pagination for very large tables
@export var pagination := false
## Count of rows per Page
@export var max_row_count_per_page := 250

@export_category("Themes")
##If not defined, it uses the theme applied to the Table or its parents
@export var header_theme: Theme
##If not defined, it uses the theme applied to the Table or its parents
@export var body_theme: Theme
##if a row gets selected, it uses an other theme applied. (if not defined...)
@export var selection_theme: Theme


#-----------------------------------------Public Var-----------------------------------------------#

var column_count: int = 0
var row_count: int = 0

#-----------------------------------------Private Var----------------------------------------------#

# Utility Class
var _table_util := preload("res://addons/osirisas_ui_extension/table_node/table_utility.gd")

# Array for the standard cell heights 
var _body_cell_heights := []
# Array for the changed cell heights (due to resizing)
var _body_cell_heights_temp := []
# Array for the changed cell widths (due to resizing)
var _cell_widths_temp := []


# Array with all the Rows (and its contents) in it
var _rows: Array[RowContent] = []

# Array for the visibility of the columns
var _column_visiblity: Array[bool] = []


# Seperators
var _separator_group := Control.new()
var _vertical_separators := []
var _horizontal_separators := []

# Groups for header and body for cleaner overview
var _header_group := Control.new()
var _body_group := Control.new()

# Panels for Background-Color etc.
var _panel_header := Panel.new()
var _panel_body := Panel.new()

# Selections
var _selected_rows: Array[RowContent] = []
var _current_row: RowContent = null
var _last_selected_row := -1

# Threads
var _sort_thread: Thread = null

#-----------------------------------------Onready Var----------------------------------------------#

#-----------------------------------------Init and Ready-------------------------------------------#

func _init():
	pass

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

#-----------------------------------------Virtual methods------------------------------------------#

#-----------------------------------------Public methods-------------------------------------------#

#region Header Edit -------------

func add_header(title: String, cell_width := standard_cell_dimension.x) -> void:
	pass

#TBD:: insert_header(title,column_pos)
#TBD:: remove_header(column_pos)

#endregion

#region Row Edit ----------------

## Adds a row to the table directly below the previous row can also called with no data, then it fills the row with empty labels
func add_row(data: Array[Control] = [], clip_text: bool = true, height: float = standard_cell_dimension.y) -> void:
	pass

#TBD:: insert_row(title,pos)

## Takes in following template: [ [node:Control],...] as data use this for populating the table with data
func add_rows_batch(data :Array, clip_text: bool = true, height: float = standard_cell_dimension.y) -> void:
	pass

## Overrides the row from the Table 
func set_row(data: Array[Control], row: int) -> void:
	pass

## Removes the row from the Table
func remove_row(row: int) -> void:
	pass

#endregion

#region Table Edit --------------

## Clears the whole Table
func clear() -> void:
	pass

#endregion

#region Counts ------------------

func get_row_count() -> int:
	return 0
	pass

func get_column_count() -> int:
	return 0
	pass

#endregion

#region Cell edit ---------------

func get_row(row: int) -> Array:
	return[]
	pass

func get_cell(row: int, column: int) -> Control:
	return Control.new()
	pass

func set_cell(node: Control,row: int, column: int, remain_clip_setting: bool = true) -> void:
	pass

func set_row_height(row: int, height: float) -> void:
	pass

func set_column_width(column: int, width: float) -> void:
	pass

#endregion 

#region Visibility --------------

func set_visibility_row(row: int, visible: bool) -> void:
	pass

func get_visibility_row(row: int) -> bool:
	return false
	pass

func set_visibility_column(column: int, visible: bool) -> void:
	pass

func get_visibility_column(column: int) -> bool:
	return false
	pass

#endregion

#region Editablity --------------

#TBD:: set_editable_status_cell -> void:
#TBD:: get_editable_status_cell -> bool:

#endregion

#region Sorting -----------------

func sort_rows_by_column(column: int, sort: Sorting) -> void:
	pass

#endregion

#region Selection ---------------

#TBD:: select row
#TBD:: select rows

## Selects all rows
func select_all_rows() -> void:
	pass

## Deselects all rows
func deselect_all_rows() -> void:
	pass

## Returns if the Table has a selection
func has_selection() -> bool:
	return false
	pass

## Returns the positions of the last selected Row 
func get_current_row() -> int:
	return 0
	pass

## Returns the positions of the Rows that got selected
func get_selection_positions() -> Array[int]:
	return []
	pass

#endregion

#region Sizes -------------------

## Get the total size of the header
func get_size_vec_of_header() -> Vector2i:
	return Vector2i(0,0)
	pass
	
## Get the total size of the body
func get_size_vec_of_body() -> Vector2i:
	return Vector2i(0,0)
	pass

#endregion

#-----------------------------------------Private methods------------------------------------------#

#<--------------------------|Slots|------------------------------>#

#-----------------------------------------Subclasses-----------------------------------------------#

class Sorter:
	var column: int
	var ascending: bool
	
	func _init(column: int, ascending: bool):
		self.column = column
		self.ascending = ascending
	
	func _sort(a, b):
		var node_a = a.nodes[column]
		var node_b = b.nodes[column]
		
		var text_a: String = node_a.text if node_a.text != null else ""
		var text_b: String = node_b.text if node_b.text != null else ""
		
		if ascending:
			return text_a.naturalcasecmp_to(text_b) < 0
		else:
			return text_a.naturalcasecmp_to(text_b) > 0

class RowContent:
	var nodes: Array[Control] = []
	var row_visible := true
	var editable: Array[bool] = []
