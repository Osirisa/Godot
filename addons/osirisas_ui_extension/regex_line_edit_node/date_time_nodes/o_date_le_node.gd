@tool
class_name ODateLineEdit
extends ORegexLineEdit

signal date_changed(valid: bool, date: ODate)

@export var format: String = "DD.MM.YYYY":
	set(value):
		format = value
		_analyze_format()
		text = text
		placeholder_text = format

@export var min_date: ODate = ODate.new(1,1,1)
@export var max_date: ODate = ODate.new(2199,12,31)

@export var change_color := true
@export_color_no_alpha var color_not_valid := Color(1, 0, 0)

var is_valid := false

var _separators: Array[String] = []
var _year_len := 4
var _max_digits := 8 # 2+2+year_len
var _allow_class := "" # z.B. ".-" für ".", "-"

func _ready() -> void:
	super._ready()
	connect("valid_text_changed", Callable(self, "_on_text_changed"))
	_analyze_format()

func _enter_tree() -> void:
	placeholder_text = format

func _analyze_format() -> void:
	# 1) Trenner extrahieren
	_separators.clear()
	var tmp := format
	for token in ["DD","MM","YYYY","YY"]:
		tmp = tmp.replace(token, "")
	for ch in tmp:
		_separators.append(ch)

	# 2) Jahrlänge bestimmen
	_year_len = 4 if format.find("YYYY") != -1 else 2
	_max_digits = 2 + 2 + _year_len

	# 3) Regex: nur erlaubte Zeichen (Ziffern + Trenner), beliebige Länge
	_allow_class = ""
	for s in _separators:
		_allow_class += _escape_for_class(s)
	# ORegexLineEdit ankert automatisch mit ^...$ (aus deiner verbesserten Version)
	regex_validator = "[0-9" + _allow_class + "]*"

func _escape_for_class(ch: String) -> String:
	# Escapes für Zeichenklassen
	if ch == "\\" or ch == "]" or ch == "-" or ch == "^":
		return "\\" + ch
	return ch

func _on_text_changed(new_text: String) -> void:
	# 1) nur Ziffern sammeln (Trenner ignorieren; Buchstaben fliegen raus)
	var digits := ""
	for c in new_text:
		if c >= "0" and c <= "9":
			digits += c
	if digits.length() > _max_digits:
		digits = digits.substr(0, _max_digits)

	# 2) Guardrails live (Blocken von „31-02“, „xx-13“ usw.)
	digits = _apply_guardrails(digits)

	# 3) In formatierte Anzeige mit Trennern gießen
	var formatted := _format_digits(digits)

	# 4) Schreiben (loop-sicher)
	set_block_signals(true)
	text = formatted
	set_block_signals(false)
	caret_column = formatted.length()

	# 5) finale Validierung + Farbe/Signal
	_validate_date()

func _apply_guardrails(d: String) -> String:
	# Erwartet Reihenfolge DD MM Y... (für andere Reihenfolgen: anpassen)
	var out := ""

	# Tag (1–31)
	if d.length() >= 1:
		out += d[0] # erste Ziffer vom Tag immer erlauben (1–3 möglich)
	if d.length() >= 2:
		var day := int(d.substr(0,2))
		if day < 1 or day > 31:
			return out # zweite Tagesziffer verwerfen
		out = d.substr(0,2)

	# Monat (1–12)
	if d.length() >= 3:
		out += d[2] # erste Monatsziffer
	if d.length() >= 4:
		var day := int(d.substr(0,2))
		var month := int(d.substr(2,2))
		if month < 1 or month > 12:
			return out # zweite Monatsziffer verwerfen

		# 31 in Monaten mit 30 Tagen verbieten
		if day == 31 and not _has_31_days(month):
			return out
		# 30 in Februar verbieten
		if day == 30 and month == 2:
			return out
		# 29 in Feb. vorerst erlauben; Leapcheck erst mit Jahr
		out = d.substr(0,4)

	# Jahr (2 oder 4 Ziffern – keine harten Guardrails nötig)
	if d.length() > 4:
		out += d.substr(4, min(_year_len, d.length() - 4))

	return out

func _has_31_days(m: int) -> bool:
	# Jan, Mär, Mai, Jul, Aug, Okt, Dez → 31
	return m == 1 or m == 3 or m == 5 or m == 7 or m == 8 or m == 10 or m == 12

func _format_digits(d: String) -> String:
	var out := ""
	var di := 0
	for i in range(format.length()):
		if di >= d.length():
			break
		var ch := format[i]
		if _separators.has(ch):
			out += ch
		else:
			out += d[di]
			di += 1
	return out

func _validate_date() -> void:
	is_valid = false
	var dmy := _extract_dmy_from_text()
	if dmy.is_empty():
		_set_color(false); emit_signal("date_changed", false, null); return

	var day: int= dmy["day"]
	var month: int = dmy["month"]
	var year: int = dmy["year"]

	# Feb 29 erst mit Jahr final entscheiden
	if month == 2 and day == 29:
		# Wenn Jahr noch unvollständig (z.B. YY=2 Ziffern): akzeptieren; finale Prüfung bei Vollständigkeit
		if _digits_in_text() < 2 + 2 + _year_len:
			_set_color(false); emit_signal("date_changed", false, null); return

	if ODate.is_valid_date(year, month, day):
		var date := ODate.new(year, month, day)
		if date.get_difference(min_date) >= 0 and max_date.get_difference(date) > 0:
			is_valid = true
			_set_color(true)
			emit_signal("date_changed", true, date)
			return

	_set_color(false)
	emit_signal("date_changed", false, null)

func _digits_in_text() -> int:
	var n := 0
	for c in text:
		if c >= "0" and c <= "9":
			n += 1
	return n

func _extract_dmy_from_text()-> Dictionary[String, int]:
	# holt exakt eingetippte Ziffern in DD/MM/YY.. Reihenfolge
	var digits := ""
	for c in text:
		if c >= "0" and c <= "9":
			digits += c
	if digits.length() < 4:
		return {}
	var day := int(digits.substr(0,2))
	var month := int(digits.substr(2,2))
	var year := 0
	if digits.length() >= 4 + _year_len:
		var ys := digits.substr(4, _year_len)
		year = int(ys) if _year_len == 4 else (2000 + int(ys)) # YY → 20YY; anpassbar
	else:
		return {}
	return { "day": day, "month": month, "year": year }

func _set_color(ok: bool) -> void:
	if not change_color:
		return
	if ok:
		remove_theme_color_override("font_color")
	else:
		add_theme_color_override("font_color", color_not_valid)
