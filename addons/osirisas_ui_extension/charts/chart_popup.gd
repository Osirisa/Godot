@tool
class_name OChartPopup
extends OPopup


@export var data_title: String = ""

var _data_arr: Array[OChartPopupData] = []



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	super._ready()
	hide_on_unfocus = false
	transparent_bg = true

func clear_popup() -> void:
	_data_arr.clear()

func add_data(data: OChartPopupData) -> void:
	_data_arr.append(data)
	_build_popup()

func remove_data(data: OChartPopupData) -> void:
	_data_arr.erase(data)
	_build_popup()


func _build_popup() -> void:
	for child in  $MC_Body/VB_Body.get_children():
		if child is not VBoxContainer:
			$MC_Body/VB_Body.remove_child(child)
			child.queue_free()
	
	if data_title:
		$MC_Body/VB_Body/VB_Title.show()
		%L_Title.text = data_title
	else:
		$MC_Body/VB_Body/VB_Title.hide()
	
	for d in _data_arr:
		var data_row = load("res://addons/osirisas_ui_extension/charts/chart_popup_data_row.tscn")
		var data_row_instance = data_row.instantiate() 
		
		data_row_instance.data_color = d.data_color
		data_row_instance.data_name = d.data_name
		data_row_instance.data_value = d.data_value as int
		
		$MC_Body/VB_Body.add_child(data_row_instance)


class OChartPopupData:
	var data_color := Color.GRAY
	var data_name := ""
	var data_value = 0


func _on_mc_body_resized() -> void:
	size = $MC_Body.size
	$P_Background.size = $MC_Body.size
