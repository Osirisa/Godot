# Date.gd
extends Resource
class_name O_Date

# Properties
var year: int
var month: int
var day: int

# Constructor
func _init(i_year: int, i_month: int, i_day: int):
	self.year = i_year
	self.month = i_month
	self.day = i_day

# Method to set the date
func set_date(i_year: int, i_month: int, i_day: int):
	self.year = i_year
	self.month = i_month
	self.day = i_day

# Method to get a string representation of the date
func _to_string() -> String:
	return str(year) + "-" + str(month).pad_zeros(2) + "-" + str(day).pad_zeros(2)

# Method to check if the year is a leap year
func is_leap_year() -> bool:
	if year % 4 == 0 and (year % 100 != 0 or year % 400 == 0):
		return true
	return false

# Method to get the number of days in the month
func days_in_month() -> int:
	match month:
		1, 3, 5, 7, 8, 10, 12:
			return 31
		4, 6, 9, 11:
			return 30
		2:
			if is_leap_year():
				return 29 
			else:
				return 28
		_:
			return 0

# Method to calculate the difference in days between this date and another date
func get_difference(to_date: O_Date) -> int:
	var current_date_in_days = _to_days_since_epoch(self)
	var other_date_in_days = _to_days_since_epoch(to_date)
	return abs(current_date_in_days - other_date_in_days)

# Helper method to convert a date to the number of days since a fixed point in time
func _to_days_since_epoch(date: O_Date) -> int:
	var total_days = 0
	
	total_days += date.year * 365
	total_days += date.year / 4 - date.year / 100 + date.year / 400
	
	# Calculate days for the months in the current year
	var month_days = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	if date.is_leap_year():
		month_days[2] = 29  # February in a leap year
	
	for m in range(1, date.month):
		total_days += month_days[m]
	
	# Add days for the days of the current month
	total_days += date.day
	
	return total_days

# Method to create a Date object from a string and a format using regex
static func from_string(date_str: String, format: String) -> O_Date:
	var regex_pattern = format
	
	regex_pattern = regex_pattern.replace("YYYY", "(?<year>[0-9]{4})")
	regex_pattern = regex_pattern.replace("MM", "(?<month>[0-1]?[0-9])")
	regex_pattern = regex_pattern.replace("DD", "(?<day>[0-9]?[0-9])")
	
	print(date_str)
	print(regex_pattern)
	
	var regex = RegEx.new()
	var error = regex.compile(regex_pattern)
	if error != OK:
		push_error("Invalid regex pattern")
		return null
	
	var matches = regex.search(date_str)
	print(matches)
	
	if not matches:
		push_error("Date string does not match format")
		return null
	
	print(matches.names)
	print(matches.strings)
	
	var year_s = int(matches.get_string("year"))
	var month_s = int(matches.get_string("month"))
	var day_s = int(matches.get_string("day"))
	
	return O_Date.new(year_s, month_s, day_s)
