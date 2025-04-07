extends Popup

signal date_selected(date: ODate)

@export var starting_date: ODate = ODate.current_date()
@export var max_date: ODate = ODate.new(2099,12,1)
@export var min_date: ODate = ODate.new(2000,1,1)

@onready
var _ob_month_select: OptionButton = %OB_Month_Select
@onready
var _le_year_select: ORegexLineEdit = %LE_Year_Select
@onready
var _vb_day_buttons: VBoxContainer = %VB_Buttongroup_Days
@onready
var _vb_calender_week_labels: VBoxContainer = %VB_Calender_Week

var selected_month: int = 1:
	set(value):
		selected_month = (value - 1) % 12
		selected_month += 1
		
		if selected_month <= 0:
			selected_month = 12 - selected_month
			selected_year += ((value - 1) / 12) - 1
		else:
			selected_year += (value - 1) / 12
		
		_ob_month_select.set_block_signals(true)
		_ob_month_select.select(selected_month - 1)
		_ob_month_select.set_block_signals(false)
		
		refresh.call_deferred()

var selected_year: int = 1:
	set(value):
		selected_year = value if value > 0 else 1
		
		selected_year = clampi(selected_year, min_date.year, max_date.year)
		
		_le_year_select.set_block_signals(true)
		_le_year_select.text = str(selected_year)
		_le_year_select.set_block_signals(false)
		
		refresh.call_deferred()

# Called when the node enters the scene tree for the first time.
func _ready():
	var callable = Callable(self, "_on_month_selected")
	_ob_month_select.connect("item_selected", callable)
	
	var callable2 = Callable(self, "_on_year_input")
	_le_year_select.connect("text_submitted", callable2)
	
	selected_month = starting_date.month
	selected_year = starting_date.year
	
	for days in _vb_day_buttons.get_children():
		for day: Button in days.get_children():
			var callable3 = Callable(self, "_on_date_button_pressed").bind(day)
			day.connect("pressed", callable3)

func refresh() -> void:
	var weeks = _vb_day_buttons.get_children()
	
	var date := ODate.new(selected_year, selected_month, 1)
	
	var week := date.get_week()
	var starting_weekday := date.get_weekday()
	
	var starting_date := date.duplicate()
	starting_date.day -= (starting_weekday - 1)
	
	var calender_week_lables = _vb_calender_week_labels.get_children()
	calender_week_lables.remove_at(0)
	
	for week_idx in range(weeks.size()):
		var days = weeks[week_idx].get_children()
		if week > 52:
			week = starting_date.get_week()
		calender_week_lables[week_idx].text = str(week)
		week += 1
		
		for day_idx in range(days.size()):
			var day: Button = days[day_idx]
			day.text = str(starting_date.day)
			
			if starting_date.month != date.month and not day.disabled:
				day.disabled = true
			elif starting_date.month == date.month and day.disabled:
				day.disabled = false
			
			starting_date.day += 1

func _on_month_selected(month: int) -> void:
	selected_month = month + 1

func _on_year_input(year: String) -> void:
	selected_year = int(year)

func _on_date_button_pressed(button: Button) -> void:
	var date = ODate.new(selected_year, selected_month, int(button.text))
	date_selected.emit(date)

func _on_b_next_year_pressed():
	selected_year += 1

func _on_b_previous_year_pressed():
	selected_year -= 1

func _on_b_next_month_pressed():
	selected_month += 1

func _on_b_previous_month_pressed():
	selected_month -= 1
