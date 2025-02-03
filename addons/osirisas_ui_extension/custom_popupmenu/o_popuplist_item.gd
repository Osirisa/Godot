class_name OPopUpListItem
extends Resource

signal otext_changed(item: OPopUpListItem)

enum CHECKABLE_SELECT{
	NO, 
	AS_CHECK_BOX,
	AS_RADIO_BUTTON,
}

@export var text: String:
	set(value):
		if value != text:
			otext_changed.emit.call_deferred(self)
		text = value

@export var icon: Texture2D
@export var checkable: CHECKABLE_SELECT
@export var checked: bool
@export var id: int
@export var disabled: bool
@export var separator: bool
