extends Node
class_name O_TimeUtil

static func calc_jd(year: int, month: int, day: int, hour: int, minute: int, second: int) -> float:
	if month <= 2:
		year -= 1
		month += 12
	var A = year / 100
	var B = 2 - A + int(A / 4)
	var JD = int(365.25 * (year + 4716)) + int(30.6001 * (month + 1)) + day + B - 1524.5
	
	# Add the fractional day component
	var day_fraction = (hour + (minute / 60.0) + (second / 3600.0)) / 24.0
	JD += day_fraction
	
	return JD

static func calc_from_jd(julian_date) -> Array[int]:
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
	
	var date_arr: Array[int] = []
	
	var day: int = B - D - int(30.6001 * E)
	var month: int = E - 1 if E < 14 else E - 13
	var year: int = C - 4716 if month > 2 else C - 4715
	
	# Calculate the fractional day part to get time
	var day_fraction = F * 24
	var hour := int(day_fraction)
	var minute := int((day_fraction - hour) * 60)
	var second := int((((day_fraction - hour) * 60) - minute) * 60)
	
	date_arr.append(year)
	date_arr.append(month)
	date_arr.append(day)
	date_arr.append(hour)
	date_arr.append(minute)
	date_arr.append(second)
	
	return date_arr
