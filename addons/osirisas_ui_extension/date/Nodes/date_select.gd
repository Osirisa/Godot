extends Control

@export var starting_date: ODate = ODate.current_date()
@export var max_date: ODate = ODate.new(2099,12,1)
@export var min_date: ODate = ODate.new(2000,1,1)

var selected_month: int = 1:
	set(value):
		selected_month = (value % 13)
		
		if value > 12:
			selected_year += (value + 1) / 12
		
		if value < 1:
			selected_year -= (value / 12) - 1
		
		selected_month = clampi(selected_month, 1, 12)
		
		_ob_month_select.set_block_signals(true)
		_ob_month_select.select(selected_month - 1)
		_ob_month_select.set_block_signals(false)

var selected_year: int = 1:
	set(value):
		selected_year = value if value > 0 else 1
		
		_le_year_select.set_block_signals(true)
		_le_year_select.text = str(selected_year)
		_le_year_select.set_block_signals(false)

@onready
var _ob_month_select: OptionButton = %OB_Month_Select
@onready
var _le_year_select: ORegexLineEdit = %LE_Year_Select

# Called when the node enters the scene tree for the first time.
func _ready():
	var callable = Callable(self, "_on_month_selected")
	_ob_month_select.connect("item_selected", callable)
	
	var callable2 = Callable(self, "_on_year_input")
	_le_year_select.connect("text_submitted", callable2)
	
	selected_month = starting_date.month
	selected_year = starting_date.year
	
func refresh() -> void:
	pass
	

func _on_month_selected(month: int) -> void:
	selected_month = month + 1
	print(month)

func _on_year_input(year: String) -> void:
	selected_year = int(year)
	print(year)
