extends ODate
class_name ODateTime

@export var hour: int:
	set(value):
		hour = value
		
		if value > 23 or value < 0:
			if not _block_set:
				_block_set = true
				
				var julian_date := to_julian()
				var new_g_date := OTimeUtil.calc_from_jd(julian_date)
				
				year = new_g_date[0]
				month = new_g_date[1]
				day = new_g_date[2]
				hour = new_g_date[3]
				minute = new_g_date[4]
				second = new_g_date[5]
				_block_set = false

@export var minute: int:
	set(value):
		minute = value
		if value > 59 or value < 0:
			if not _block_set:
				_block_set = true
				
				var julian_date := to_julian()
				var new_g_date := OTimeUtil.calc_from_jd(julian_date)
				
				year = new_g_date[0]
				month = new_g_date[1]
				day = new_g_date[2]
				hour = new_g_date[3]
				minute = new_g_date[4]
				second = new_g_date[5]
				_block_set = false

@export var second: int:
	set(value):
		second = value
		
		if value > 59 or value < 0:
			if not _block_set:
				_block_set = true
				
				var julian_date := to_julian()
				var new_g_date := OTimeUtil.calc_from_jd(julian_date)
				
				year = new_g_date[0]
				month = new_g_date[1]
				day = new_g_date[2]
				hour = new_g_date[3]
				minute = new_g_date[4]
				second = new_g_date[5]
				_block_set = false

func _init(i_year: int = 1, i_month: int = 1, i_day: int = 1, i_hour: int = 0, i_minute: int = 0, i_second: int = 0):
	super(i_year, i_month, i_day)
	hour = i_hour
	minute = i_minute
	second = i_second

func _to_string() -> String:
	return str(year) + "-" + str(month).pad_zeros(2) + "-" + str(day).pad_zeros(2) + " " + str(hour).pad_zeros(2) + ":" + str(minute).pad_zeros(2) + ":" + str(second).pad_zeros(2)

func to_string_formatted(format: String) -> String:
	var replacements := {
		"DD": str(day).pad_zeros(2),
		"D": str(day),
		"MM": str(month).pad_zeros(2),
		"M": str(month),
		"YYYY": str(year),
		"YY": str(year).right(2),
		"hh": str(hour).pad_zeros(2),
		"h": str(hour),
		"mm": str(minute).pad_zeros(2),
		"m": str(minute),
		"ss": str(second).pad_zeros(2),
		"s": str(second)
	}

	for key in replacements.keys():
		format = format.replace(key, replacements[key])
	
	return format

func to_offset_iso(tz_shift_minutes: int = 0, use_own_tz_shift: bool = false) -> String:
	var sys = Time.get_time_zone_from_system()
	var total := tz_shift_minutes if use_own_tz_shift else int(sys["bias"])
	
	var sign := "+"
	if total < 0:
		sign = "-"
		total = -total
	
	var hours: int = total / 60               
	var minutes: int = total % 60            
	
	var iso := self.to_string_formatted("YYYY-MM-DDThh:mm:ss")
	iso += "%s%02d:%02d" % [sign, hours, minutes]
	return iso

func to_utc_iso(tz_shift_minutes: int = 0, use_own_tz_shift: bool = false) -> String:
	var sys = Time.get_time_zone_from_system()
	var total := tz_shift_minutes if use_own_tz_shift else int(sys["bias"])
	
	var shifted_time: ODateTime = self.duplicate()
	
	shifted_time.minute -= total
	
	var sign := "+"
	if total < 0:
		sign = "-"
		total = -total
	
	var hours := total / 60
	var minutes := total % 60
	
	var iso := shifted_time.to_string_formatted("YYYY-MM-DDThh:mm:ss") + "Z"
	
	return iso


## Takes in a string containing a date and a time and a format to show where the numbers are[br]
## Example: "2024-07-08|8:7:06" and "YYYY-MM-DD|hh:mm:ss"
static func from_string(time_date_str: String, format: String) -> ODateTime:
	var regex_pattern := format
	
	regex_pattern = regex_pattern.replace("YYYY", "(?<year>[0-9]+)")
	regex_pattern = regex_pattern.replace("MM", "(?<month>0[1-9]|1[0-2])")
	regex_pattern = regex_pattern.replace("DD", "(?<day>[0-3]?[0-9])")
	regex_pattern = regex_pattern.replace("hh", "(?<hour>[0-2]?[0-9])")
	regex_pattern = regex_pattern.replace("mm", "(?<minute>[0-5]?[0-9])")
	regex_pattern = regex_pattern.replace("ss", "(?<second>[0-5]?[0-9])")
	
	var regex := RegEx.new()
	var error := regex.compile(regex_pattern)
	if error != OK:
		push_error("Invalid regex pattern")
		return null
	
	var matches = regex.search(time_date_str)
	#print(matches)
	
	if not matches:
		push_error("Date string does not match format")
		return null
	
	#print(matches.names)
	#print(matches.strings)
	
	var year_s := int(matches.get_string("year"))
	var month_s := int(matches.get_string("month"))
	var day_s := int(matches.get_string("day"))
	var hour_s := int(matches.get_string("hour"))
	var minute_s := int(matches.get_string("minute"))
	var second_s := int(matches.get_string("second"))
	
	return ODateTime.new(year_s, month_s, day_s, hour_s, minute_s, second_s)

static func from_julian(julian_date: float) -> ODateTime:
	var date_arr := OTimeUtil.calc_from_jd(julian_date)
	return ODateTime.new(date_arr[0], date_arr[1], date_arr[2], date_arr[3], date_arr[4], date_arr[5])

static func current_date_time() -> ODateTime:
	var curr_date_dict := Time.get_datetime_dict_from_system()
	return ODateTime.new(curr_date_dict.year, curr_date_dict.month, curr_date_dict.day, 
							curr_date_dict.hour, curr_date_dict.minute, curr_date_dict.second)

func set_date_time(i_year: int, i_month: int, i_day: int, 
					i_hour: int, i_minute: int, i_second: int) -> void:
	super.set_date(i_year, i_month, i_day)
	hour = i_hour
	minute = i_minute
	second = i_second

## Own Date - Other Date
func get_difference_dt(other: ODateTime) -> int:
	var jd1: float = self.to_julian()
	var jd2: float = other.to_julian()
	return jd1 - jd2

func to_julian() -> float:
	return OTimeUtil.calc_jd(year, month, day, hour, minute, second)

static func from_utc_iso(iso: String, tz_shift_minutes: int = 0, use_own_tz_shift: bool = false) -> ODateTime:
	# Accepts: "YYYY-MM-DDThh:mm:ssZ" (optionally with fractional seconds)
	var re := RegEx.new()
	re.compile(r"^(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):(\d{2}):(\d{2})(?:\.\d+)?Z$")
	var m := re.search(iso)
	if not m:
		push_error("from_utc_iso: invalid UTC ISO string: %s" % iso)
		return null

	var y := int(m.get_string(1))
	var mo := int(m.get_string(2))
	var d := int(m.get_string(3))
	var h := int(m.get_string(4))
	var mi := int(m.get_string(5))
	var s := int(m.get_string(6))

	# Create UTC time first
	var dt := ODateTime.new(y, mo, d, h, mi, s)
#	print("DATETIME BEFORE CONVERSION", dt.to_string())
	# Convert UTC -> local by ADDING the bias (inverse of your to_utc_iso which subtracted it)
	var sys := Time.get_time_zone_from_system()
	var total := tz_shift_minutes if use_own_tz_shift else int(sys["bias"])
	dt.minute += total  # your setters + julian conversion will normalize overflow
#	print("DATETIME AFTER CONVERSION", dt.to_string())
	return dt


static func to_julian_st(day: int = 1, month: int = 1, year: int = 1, hour: int = 0, minute: int = 0, second: int = 0) -> float:
	return OTimeUtil.calc_jd(year, month, day, hour, minute, second)
