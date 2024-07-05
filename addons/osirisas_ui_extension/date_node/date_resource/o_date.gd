# Date.gd
extends Resource
class_name O_Date

## This Class provides you with a Date - Resource which is more convinient than the built in Date
## 
## You can put in a date from a strint, compare it with other dates, check if that date is in a leap year, etc...
#-----------------------------------------Signals--------------------------------------------------#
#-----------------------------------------Enums----------------------------------------------------#

enum E_WEEKDAYS {
	MONDAY,
	TUESDAY,
	WEDNESDAY,
	THURSDAY,
	FRIDAY,
	SATURDAY,
	SUNDAY
}

enum E_MONTHS {
	JANUARY,
	FEBRUARY,
	MARCH,
	APRIL,
	MAY,
	JUNE,
	JULY,
	AUGUST,
	SEPTEMBER,
	OCTOBER,
	NOVEMBER,
	DECEMBER
} 

#-----------------------------------------Constants------------------------------------------------#

const MONTH_DAYS = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
const MONTH_DAYS_LEAP = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

#-----------------------------------------Export Var-----------------------------------------------#

#-----------------------------------------Public Var-----------------------------------------------#

var year: int
var month: int
var day: int

#-----------------------------------------Private Var----------------------------------------------#
#-----------------------------------------Onready Var----------------------------------------------#

#-----------------------------------------Init and Ready-------------------------------------------#
# Constructor
func _init(i_day: int, i_month: int, i_year: int):
	self.year = i_year
	self.month = i_month
	self.day = i_day

#-----------------------------------------Virtual methods------------------------------------------#

# Method to get a string representation of the date
func _to_string() -> String:
	return str(year) + "-" + str(month).pad_zeros(2) + "-" + str(day).pad_zeros(2)

#-----------------------------------------Public methods-------------------------------------------#

## Method to set the date
func set_date(i_day: int, i_month: int, i_year: int):
	self.year = i_year
	self.month = i_month
	self.day = i_day

## Method to create a Date object from a string and a format using regex
static func from_string(date_str: String, format: String) -> O_Date:
	var regex_pattern = format
	
	regex_pattern = regex_pattern.replace("YYYY", "(?<year>[0-9]{4})")
	regex_pattern = regex_pattern.replace("MM", "(?<month>[0-1]?[0-9])")
	regex_pattern = regex_pattern.replace("DD", "(?<day>[0-9]?[0-9])")
	
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

static func current_date() -> O_Date:
	var curr_date_dict := Time.get_datetime_dict_from_system()
	return O_Date.new(curr_date_dict.day, curr_date_dict.month, curr_date_dict.year)

## Method to create a Date object from a amount of days
static func from_days_since_epoch(days: int) -> O_Date:
	var jd_epoch_start = julian_date_st(1,1,1)
	var jd = jd_epoch_start + days
	
	return from_julian(jd)

static func from_julian(julian_date: float) -> O_Date:
	var Z = int(julian_date + 0.5)
	var F = (julian_date + 0.5) - Z
	var A = 0
	
	if Z < 2299161:
		A = Z
	else:
		var alpha = int((Z - 1867216.25) / 36524.25)
		A = Z + 1 + alpha - int(alpha / 4)
	var B = A + 1524
	var C = int((B - 122.1) / 365.25)
	var D = int(365.25 * C)
	var E = int((B - D) / 30.6001)
	
	var day = B - D - int(30.6001 * E) + F
	var month = E - 1 if E < 14 else E - 13
	var year = C - 4716 if month > 2 else C - 4715
	
	return O_Date.new(day, month, year)

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

# Method to calculate the difference in days between this date and another date
func get_difference(other: O_Date) -> int:
	var jd1 = self.julian_date()
	var jd2 = other.julian_date()
	return abs(jd1 - jd2)

func equals(other_date: O_Date) -> bool:
	if not self.year == other_date.year:
		return false
	
	if not self.month == other_date.month:
		return false
	
	if not self.day == other_date.day:
		return false
	
	return true

func add_days(days_to_add: int) -> void:
	var julian_date = self.julian_date()
	var new_julian_date = julian_date + days_to_add
	var new_g_date = from_julian(new_julian_date)
	
	self.year = new_g_date.year
	self.month = new_g_date.month
	self.day = new_g_date.day

func julian_date() -> float:
	var _year = self.year
	var _month = self.month
	var _day = self.day
	
	if _day <= 2:
		_year -= 1
		_month += 12
	var A = _year / 100
	var B = 2 - A + int(A / 4)
	var JD = int(365.25 * (_year + 4716)) + int(30.6001 * (_month + 1)) + _day + B - 1524.5
	return JD

static func julian_date_st(day: int, month: int, year: int) -> float:
	if month <= 2:
		year -= 1
		month += 12
	var A = year / 100
	var B = 2 - A + int(A / 4)
	var JD = int(365.25 * (year + 4716)) + int(30.6001 * (month + 1)) + day + B - 1524.5
	return JD

#-----------------------------------------Private methods------------------------------------------#



