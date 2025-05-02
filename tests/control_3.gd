@tool
extends Control

var strings: Array[String] = [
	"Test",
	"blala",
	"aefkj",
	"fasef",
]

func _ready() -> void:
	%OBreadCrumbs.path.clear()
	for string in strings:
		%OBreadCrumbs.path.append(string)
		#%OBreadCrumbs.update_breadcrumbs()
