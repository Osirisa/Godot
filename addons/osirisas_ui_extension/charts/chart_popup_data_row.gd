@tool
extends HBoxContainer

var data_color: Color = Color.GRAY:
	set(value):
		data_color = value
		var color_stylbebox: StyleBox = %P_Data_Color.get_theme_stylebox("panel", "Panel")
		if color_stylbebox:
			color_stylbebox.bg_color = value

var data_name: String = "data":
	set(value):
		data_name = value
		%L_Data_Name.text = value

var data_value = 0:
	set(value):
		data_value = value
		if data_value is int:
			%L_Data_Value.text = str(data_value)
		if data_value is Vector2 or data_value is Vector2i:
			%L_Data_Value.text = str("(", data_value.x," | " ,data_value.y, ")")
