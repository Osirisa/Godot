class_name OComboBoxItem
extends Resource

signal otext_changed(new_text: String)

@export var text: String:
	set(value):
		otext_changed.emit(value)
		text = value
@export var icon: Texture2D
@export var id: int
@export var disabled: bool
@export var separator: bool
@export var visible: bool = true
