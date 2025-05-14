class_name OChartData
extends Resource

enum ChartDataType { 
	VALUE, 
	VECTOR, 
	OHLC, 
	CUSTOM, 
	}

@export var data_type: ChartDataType = ChartDataType.VALUE

@export var data_name: String

@export var data: Array = []
@export var labels: Array[String] = []
@export var colors: Array[Color] = []

@export var value_unit: String = ""

@export var category: String = ""
@export var tags: Array[String] = []

@export var visible := true
