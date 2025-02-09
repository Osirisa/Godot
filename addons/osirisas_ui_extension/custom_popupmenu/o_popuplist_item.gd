class_name OPopUpListItem
extends Resource

signal otext_changed(new_text: String)

enum CHECKABLE_SELECT{
	NO, 
	AS_CHECK_BOX,
	AS_RADIO_BUTTON,
}

@export var text: String:
	set(value):
		otext_changed.emit(value)
		text = value
@export var icon: Texture2D
@export var checkable: CHECKABLE_SELECT
@export var checked: bool
@export var id: int
@export var disabled: bool
@export var separator: bool
@export var visible: bool = true
