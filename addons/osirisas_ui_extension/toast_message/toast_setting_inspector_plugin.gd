extends EditorInspectorPlugin

func _can_handle(object: Object) -> bool:
	return object is OToastSettings


func _parse_begin(object: Object) -> void:
	if object is OToastSettings and not EditorInterface.get_inspector().is_connected("property_edited", _on_property_changed):
		EditorInterface.get_inspector().property_edited.connect(_on_property_changed.bind(object))


func _parse_property(object, type, name, hint, hint_text, usage, wide):
	if name == "toast_animation_settings":
		var animation_type = object.toast_animation
		var vbox = VBoxContainer.new()
		
		match animation_type:
			object.Toast_Animation.FADE_SLIDE:
				vbox.add_child(_make_vector_field(object, "slide_starting_point", Vector2(80, 40)))
			object.Toast_Animation.SHAKE:
				vbox.add_child(_make_4d_vector_field(object, "shake_strength", Vector4(8, -8, 4, -4)))
			object.Toast_Animation.FLY_IN:
				vbox.add_child(_make_option_field(object, "fly_from_direction", ["top_left", "top", "top_right", "left", "right", "bottom_right", "bottom", "bottom_left"], "right"))
			object.Toast_Animation.SCALE:
				vbox.add_child(_make_option_field(object, "scale_from_position", ["center", "top_left", "top", "top_right", "left", "bottom_right", "bottom", "bottom_left", "right"], "center"))
		
		add_custom_control(vbox)
		return true
	
	return false


func _make_vector_field(obj, key: String, default: Vector2, label_text := "") -> Control:
	var vec: Vector2 = obj.toast_animation_settings.get(key, default)
	var values = [vec.x, vec.y]
	var names = ["x", "y"]
	var colors = [Color("9e7667"), Color("67a383")]

	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label := Label.new()
	label.text = label_text if label_text != "" else key.capitalize().replace("_", " ")
	label.clip_text = true
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_FILL
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	#label.custom_minimum_size = Vector2(120, 0)
	hbox.add_child(label)
	
	var spin_boxes := []
	var coord_vbox := VBoxContainer.new()
	coord_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	for i in range(2):
		var coord_hbox := HBoxContainer.new()
		#coord_vbox.alignment = BoxContainer.ALIGNMENT_CENTER

		var char_box := ColorRect.new()
		char_box.color = Color.BLACK
		char_box.custom_minimum_size = Vector2(20, 20)

		var char_label := Label.new()
		char_label.text = names[i]
		char_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		char_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		char_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		char_label.modulate = colors[i]
		char_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		char_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		char_box.add_child(char_label)

		var spin_box := SpinBox.new()
		spin_box.min_value = -1000000
		spin_box.max_value = 1000000
		spin_box.value = values[i]
		spin_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spin_box.custom_minimum_size = Vector2(50, 20)
		spin_box.select_all_on_focus = true
		
		
		spin_boxes.append(spin_box)

		spin_box.value_changed.connect(func(_value):
			var v = Vector2(
				spin_boxes[0].value,
				spin_boxes[1].value
			)
			_set_dict_value(obj, key, v)
		)

		coord_hbox.add_child(char_box)
		coord_hbox.add_child(spin_box)
		coord_vbox.add_child(coord_hbox)
	hbox.add_child(coord_vbox)

	return hbox


func _make_4d_vector_field(obj, key: String, default: Vector4, label_text := "") -> Control:
	var vec: Vector4 = obj.toast_animation_settings.get(key, default)
	var values = [vec.x, vec.y, vec.z, vec.w]
	var names = ["x", "y", "z", "w"]
	var colors = [Color("9e7667"), Color("67a383"), Color("7364a1"), Color("60a0a6")]

	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label := Label.new()
	label.text = label_text if label_text != "" else key.capitalize().replace("_", " ")
	label.clip_text = true
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_FILL
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	#label.custom_minimum_size = Vector2(120, 0)
	hbox.add_child(label)
	
	var spin_boxes := []
	var coord_vbox := VBoxContainer.new()
	coord_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	for i in range(4):
		var coord_hbox := HBoxContainer.new()
		#coord_vbox.alignment = BoxContainer.ALIGNMENT_CENTER

		var char_box := ColorRect.new()
		char_box.color = Color.BLACK
		char_box.custom_minimum_size = Vector2(20, 20)

		var char_label := Label.new()
		char_label.text = names[i]
		char_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		char_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		char_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		char_label.modulate = colors[i]
		char_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		char_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		char_box.add_child(char_label)

		var spin_box := SpinBox.new()
		spin_box.min_value = -1000000
		spin_box.max_value = 1000000
		spin_box.value = values[i]
		spin_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spin_box.custom_minimum_size = Vector2(50, 20)
		spin_box.select_all_on_focus = true
		
		
		spin_boxes.append(spin_box)

		spin_box.value_changed.connect(func(_value):
			var v = Vector4(
				spin_boxes[0].value,
				spin_boxes[1].value,
				spin_boxes[2].value,
				spin_boxes[3].value
			)
			_set_dict_value(obj, key, v)
		)

		coord_hbox.add_child(char_box)
		coord_hbox.add_child(spin_box)
		coord_vbox.add_child(coord_hbox)
	hbox.add_child(coord_vbox)

	return hbox


func _make_int_field(obj, key: String, default: int) -> Control:
	var val = obj.toast_animation_settings.get(key, default)
	var field = SpinBox.new()
	field.min_value = 0
	field.max_value = 100
	field.value = val
	field.value_changed.connect(func(value):
		_set_dict_value(obj, key, int(value))
	)
	return field


func _make_option_field(obj, key: String, options: Array, default: String, label_text := "") -> Control:
	var val = obj.toast_animation_settings.get(key, default)
	
	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var label := Label.new()
	label.text = label_text if label_text != "" else key.capitalize().replace("_", " ")
	label.clip_text = true
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_FILL
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.add_child(label)
	
	var field = OptionButton.new()
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(field)
	
	for o in options:
		field.add_item(o)
	field.selected = options.find(val)
	field.item_selected.connect(func(idx):
		_set_dict_value(obj, key, options[idx])
	)
	return hbox


func _set_dict_value(obj: Resource, key: String, value):
	var new_dict = obj.toast_animation_settings.duplicate()
	new_dict[key] = value
	obj.toast_animation_settings = new_dict
	obj.notify_property_list_changed()


func _on_property_changed(property:String, object: OToastSettings):
	if property == "toast_animation":
		object.notify_property_list_changed()
