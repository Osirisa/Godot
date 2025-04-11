class_name OAdvancedOptionBtnItem
extends Resource

func _init(_text: String = "", _id: int = 0, _icon = null, _metadata: Variant = null, _disabled: bool = false, _is_separator: bool = false) -> void:
	label = _text
	id = _id
	icon = _icon
	metadata = _metadata
	disabled = _disabled
	is_separator = _is_separator

@export var label: String
@export var icon: Texture2D
var metadata: Variant
@export var id: int
@export var disabled: bool = false
@export var is_separator: bool = false
