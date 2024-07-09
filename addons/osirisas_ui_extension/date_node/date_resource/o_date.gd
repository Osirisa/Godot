# Date.gd
extends Resource
class_name O_Date

## This Class provides you with a Date - Resource which is more convinient than the built in Date
## 
## You can put in a date from a strint, compare it with other dates, check if that date is in a leap year, etc...
#-----------------------------------------Signals--------------------------------------------------#
#-----------------------------------------Enums----------------------------------------------------#

enum E_WEEKDAYS {
	MONDAY = 1,
	TUESDAY = 2,
	WEDNESDAY = 3,
	THURSDAY = 4,
	FRIDAY = 5,
	SATURDAY = 6,
	SUNDAY = 7
}

enum E_MONTHS {
	JANUARY = 1,
	FEBRUARY = 2,
	MARCH = 3,
	APRIL = 4,
	MAY = 5,
	JUNE = 6,
	JULY = 7,
	AUGUST = 8,
	SEPTEMBER = 9,
	OCTOBER = 10,
	NOVEMBER = 11,
	DECEMBER = 12
}
#-----------------------------------------Constants------------------------------------------------#

const MONTH_DAYS = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
const MONTH_DAYS_LEAP = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

#-----------------------------------------Export Var-----------------------------------------------#
#-----------------------------------------Public Var-----------------------------------------------#

var year := 1:
	set(value):
		year = value
		if month == 2:
			if not _block_set:
				_block_set = true
				
				var julian_date = to_julian()
				var new_g_date = O_TimeUtil.calc_from_jd(julian_date)
				
				year = new_g_date[0]
				month = new_g_date[1]
				day = new_g_date[2]
				
				_block_set = false

## The Month | NOTE: Calculations with adding and subtracting months could be values you not expect
## Rather use Days!!
## Example: 2012.12.31 - 1 month is 2012.12.01
var month := 1:
	set(value):
		month = value % 12
		
		if not _block_set:
			_block_set = true
			
			year += value / 12
			
			var julian_date = to_julian()
			var new_g_date = O_TimeUtil.calc_from_jd(julian_date)
			
			year = new_g_date[0]
			month = new_g_date[1]
			day = new_g_date[2]
			
			_block_set = false

var day := 1: 
	set(value):
		day = value
		
		if day > MONTH_DAYS[month - 1] or value < 1:
			if not _block_set:
				_block_set = true
				
				var julian_date = to_julian()
				var new_g_date = O_TimeUtil.calc_from_jd(julian_date)
				
				year = new_g_date[0]
				month = new_g_date[1]
				day = new_g_date[2]
				
				_block_set = false

#-----------------------------------------Private Var----------------------------------------------#

var _block_set := false

#-----------------------------------------Onready Var----------------------------------------------#

#-----------------------------------------Init and Ready-------------------------------------------#
# Constructor
func _init(i_year: int = 0, i_month: int = 0, i_day: int = 0):
	year = i_year
	month = i_month
	day = i_day

#-----------------------------------------Virtual methods------------------------------------------#

# Method to get a string representation of the date
func _to_string() -> String:
	return str(year) + "-" + str(month).pad_zeros(2) + "-" + str(day).pad_zeros(2)

#-----------------------------------------Public methods-------------------------------------------#

func to_string_formatted(format: String) -> String:
	var replacements = {
		"DD": str(day).pad_zeros(2),
		"D": str(day),
		"MM": str(month).pad_zeros(2),
		"M": str(month),
		"YYYY": str(year),
		"YY": str(year).right(2)
	}

	for key in replacements.keys():
		format = format.replace(key, replacements[key])
	
	return format

## Method to set the date
func set_date(i_year: int, i_month: int, i_day: int) -> void:
	year = i_year
	month = i_month
	day = i_day

## Method to create a Date object from a string and a format using regex
static func from_string(date_str: String, format: String) -> O_Date:
	var regex_pattern = format
	
	regex_pattern = regex_pattern.replace("YYYY", "(?<year>[0-9]+)")
	regex_pattern = regex_pattern.replace("MM", "(?<month>[0-1]?[0-9])")
	regex_pattern = regex_pattern.replace("DD", "(?<day>[0-3]?[0-9])")
	
	#print(date_str)
	#print(regex_pattern)
	
	var regex = RegEx.new()
	var error = regex.compile(regex_pattern)
	if error != OK:
		push_error("Invalid regex pattern")
		return null
	
	var matches = regex.search(date_str)
	#print(matches)
	
	if not matches:
		push_error("Date string does not match format")
		return null
	
	#print(matches.names)
	#print(matches.strings)
	
	var year_s = int(matches.get_string("year"))
	var month_s = int(matches.get_string("month"))
	var day_s = int(matches.get_string("day"))
	
	return O_Date.new(year_s, month_s, day_s)

## Method to create a Date object from a amount of days
static func from_days_since_epoch(days: int) -> O_Date:
	var jd_epoch_start = to_julian_st(1,1,1)
	var jd = jd_epoch_start + days
	
	return from_julian(jd)

static func from_julian(julian_date: float) -> O_Date:
	var date_arr = O_TimeUtil.calc_from_jd(julian_date)
	return O_Date.new(date_arr[0], date_arr[1], date_arr[2])

static func current_date() -> O_Date:
	var curr_date_dict := Time.get_datetime_dict_from_system()
	return O_Date.new(curr_date_dict.year, curr_date_dict.month, curr_date_dict.day)

func get_weekday() -> E_WEEKDAYS:
	var A = year
	var M = month
	var D = day

	var month_offset_normal: Array[int] = [0, 3, 3, 6, 1, 4, 6, 2, 5, 0, 3, 5]
	var month_offset_leap: Array[int] = [0, 3, 4, 0, 2, 5, 0, 3, 6, 1, 4, 6]

	var offset: int

	if is_leap_year():
		offset = month_offset_leap[M - 1]
	else:
		offset = month_offset_normal[M - 1]

	var weekday = (D + offset + 5*((A-1)%4) + 4*((A-1)%100) + 6*((A-1)%400))%7

	match weekday:
		0:
			return E_WEEKDAYS.SUNDAY
		1, 2, 3, 4, 5, 6:
			return weekday
		_:
			return -1
	return weekday

func equals(other_date: O_Date) -> bool:
	if not year == other_date.year:
		return false
	
	if not month == other_date.month:
		return false
	
	if not day == other_date.day:
		return false
	
	return true
	
func get_difference(other: O_Date) -> int:
	var jd1 = self.to_julian()
	var jd2 = other.to_julian()
	return abs(jd1 - jd2)

## Method to check if the year is a leap year
func is_leap_year() -> bool:
	if year == 0:
		return false
	if year % 4 == 0 and (year % 100 != 0 or year % 400 == 0):
		return true
	return false

## Method to check if the year is a leap year
static func is_year_leap_st(year: int) -> bool:
	return (year % 4 == 0) and (year % 100 != 0 or year % 400 == 0)

## Method to get the number of days in the month
func days_in_month() -> int:
	match month:
		2:
			if is_leap_year():
				return 29 
			else:
				return 28
		
		4, 6, 9, 11:
			return 30
		
		_:
			return 31

## Method to get the number of days in the month
static func days_in_month_st(month: int, is_leap_year := false) -> int:
	match month:
		2:
			if is_leap_year:
				return 29 
			else:
				return 28
		
		4, 6, 9, 11:
			return 30
		
		_:
			return 31

func days_in_year() -> int:
	return 366 if is_leap_year() else 365

func to_julian() -> float:
	return O_TimeUtil.calc_jd(year, month, day, 0, 0, 0)

static func to_julian_st(day: int = 1, month: int = 1, year: int = 1, _t: int = 0, _2t: int = 0, _t3: int = 0) -> float:
	return O_TimeUtil.calc_jd(year, month, day, 0, 0, 0)
#-----------------------------------------Private methods------------------------------------------#



