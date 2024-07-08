extends Resource
class_name O_Time

var hour: int
var minute: int:
	set(value):
		var correction := int(value / 60)
		#print(correction)
		if correction >= 0 and value > 0:
			hour += correction
			minute = value % 60
			#print("pos1_min")
		else:
			if hour >= abs(correction) + 1:
				hour += correction
				minute = value % 60
				#print("pos2_min")
			else:
				#print("neg_min")
				_negative = true
				correction += hour
				
				minute = 60 - value % 60

var second: int:
	set(value):
		var correction := int(value / 60)
		if correction >= 0 and value > 0:
			minute += correction
			second = value % 60
			#print("pos1")
		else:
			if minute >= abs(correction) + 1:
				minute += correction - 1
				second = value % 60
				#print("pos2")
			else:
				if hour < abs(correction / 60) + 1:
					#print("neg")
					_negative = true
					correction += hour
					minute = correction
					second = 60 - value % 60
				else:
					#print("pos3")
					minute += correction
					second = value % 60

var _negative := false

func _init(i_hour: int = 0, i_minute: int = 0, i_second: int = 0):
	hour = i_hour
	minute = i_minute 
	second = i_second

func _to_string() -> String:
	if _negative:
		return "- " + str(abs(hour)).pad_zeros(2) + ":" + str(abs(minute)).pad_zeros(2) + ":" + str(abs(second)).pad_zeros(2)
	else:
		return str(hour).pad_zeros(2) + ":" + str(minute).pad_zeros(2) + ":" + str(second).pad_zeros(2)

func to_string_formated(format: String) -> String:
	return ""

static func from_string(time_str: String, format: String) -> O_Time:
	var regex_pattern = format
	
	regex_pattern = regex_pattern.replace("hh", "(?<hour>[0-9]+)")
	regex_pattern = regex_pattern.replace("mm", "(?<minute>[0-5]?[0-9])")
	regex_pattern = regex_pattern.replace("ss", "(?<second>[0-5]?[0-9])")
	
	var regex = RegEx.new()
	var error = regex.compile(regex_pattern)
	if error != OK:
		push_error("Invalid regex pattern")
		return null
	
	var matches = regex.search(time_str)
	#print(matches)
	
	if not matches:
		push_error("Date string does not match format")
		return null
	
	var hour_s = int(matches.get_string("hour"))
	var minute_s = int(matches.get_string("minute"))
	var second_s = int(matches.get_string("second"))
	
	return O_Time.new(hour_s, minute_s, second_s)

static func from_julian(julian_date: float) -> O_Time:
	var date_arr = O_TimeUtil.calc_from_jd(julian_date)
	return O_Time.new(date_arr[3], date_arr[4], date_arr[5])


static func current_time() -> O_Time:
	var curr_date_dict := Time.get_datetime_dict_from_system()
	return O_Time.new(curr_date_dict.hour, curr_date_dict.minute, curr_date_dict.second)

func set_time(i_hour: int, i_minute: int, i_second: int) -> void:
	hour = i_hour
	minute = i_minute 
	second = i_second

func get_difference(other_time: O_Time) -> O_Time:
	var difference := O_Time.new()
	difference.hour = hour - other_time.hour
	difference.minute = minute - other_time.minute
	difference.second = second - other_time.second
	
	return difference

func equals(other_date: O_Time) -> bool:
	if not hour == other_date.hour:
		return false
	
	if not minute == other_date.minute:
		return false
	
	if not second == other_date.second:
		return false
	
	return true
