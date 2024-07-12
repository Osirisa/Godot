extends Resource
class_name OTime

var hour: int:
	set(value):
		hour = value
		
		if abs(value) > 0:
			if not _block_set:
				_block_set = true
				var tot_time = get_time_in_seconds()
				
				if tot_time < 0:
					_negative = true
				else:
					_negative = false
				
				hour = tot_time / 3600
				minute = (tot_time - (hour * 3600)) / 60
				second = ((tot_time - (hour * 3600)) - (minute * 60))
				
				_block_set = false

var minute: int:
	set(value):
		minute = value
		
		if abs(value) > 0:
			if not _block_set:
				_block_set = true
				var tot_time = get_time_in_seconds()
				
				if tot_time < 0:
					_negative = true
				else:
					_negative = false
				
				hour = tot_time / 3600
				minute = (tot_time - (hour * 3600)) / 60
				second = ((tot_time - hour * 3600) - (minute * 60))
				
				_block_set = false

var second: int:
	set(value):
		second = value
		
		if abs(value) > 0:
			if not _block_set:
				_block_set = true
				var tot_time = get_time_in_seconds()
				
				if tot_time < 0:
					_negative = true
				else:
					_negative = false
				
				hour = tot_time / 3600
				minute = (tot_time - (hour * 3600)) / 60
				second = ((tot_time - (hour * 3600)) - (minute * 60))
				
				_block_set = false

var _negative := false
var _block_set := false

func _init(i_hour: int = 0, i_minute: int = 0, i_second: int = 0):
	hour = i_hour
	minute = i_minute 
	second = i_second

func _to_string() -> String:
	if _negative:
		return "-" + str(abs(hour)).pad_zeros(2) + ":" + str(abs(minute)).pad_zeros(2) + ":" + str(abs(second)).pad_zeros(2)
	else:
		return str(hour).pad_zeros(2) + ":" + str(minute).pad_zeros(2) + ":" + str(second).pad_zeros(2)

func to_string_formated(format: String) -> String:
	var replacements := {
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

static func from_string(time_str: String, format: String) -> OTime:
	var regex_pattern := format
	
	regex_pattern = regex_pattern.replace("hh", "(?<hour>[0-9]+)")
	regex_pattern = regex_pattern.replace("mm", "(?<minute>[0-5]?[0-9])")
	regex_pattern = regex_pattern.replace("ss", "(?<second>[0-5]?[0-9])")
	
	var regex := RegEx.new()
	var error := regex.compile(regex_pattern)
	if error != OK:
		push_error("Invalid regex pattern")
		return null
	
	var matches = regex.search(time_str)
	#print(matches)
	
	if not matches:
		push_error("Date string does not match format")
		return null
	
	var hour_s := int(matches.get_string("hour"))
	var minute_s := int(matches.get_string("minute"))
	var second_s := int(matches.get_string("second"))
	
	return OTime.new(hour_s, minute_s, second_s)

static func from_julian(julian_date: float) -> OTime:
	var date_arr = OTimeUtil.calc_from_jd(julian_date)
	return OTime.new(date_arr[3], date_arr[4], date_arr[5])


static func current_time() -> OTime:
	var curr_date_dict := Time.get_datetime_dict_from_system()
	return OTime.new(curr_date_dict.hour, curr_date_dict.minute, curr_date_dict.second)

func set_time(i_hour: int, i_minute: int, i_second: int) -> void:
	hour = i_hour
	minute = i_minute 
	second = i_second

func get_difference(other_time: OTime) -> OTime:
	var difference := OTime.new()
	difference.hour = hour - other_time.hour
	difference.minute = minute - other_time.minute
	difference.second = second - other_time.second
	
	return difference

func equals(other_date: OTime) -> bool:
	if not hour == other_date.hour:
		return false
	
	if not minute == other_date.minute:
		return false
	
	if not second == other_date.second:
		return false
	
	return true

func get_time_in_seconds() -> int:
	return hour * 3600 + minute * 60 + second 
