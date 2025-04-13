extends Control

var test_arr :Array[String]= ["test",
	"damn",
	"president",
	"discount",
	"studio",
	"god",
	"despair",
	"blow",
	"army",
	"arm",
	"busy",
	"testing",
	"overeat",
	"experiment",
	"technology",
	"exemption",
	"thesis",
	"spit",
	"week",
	"glimpse",
	"suspect",
	"sustain",
	"hospital",
	"expect",
	"leadership",
	"leader",
	"fear",
	"sulphur",
	"hardware",
	"assault",
	"definite",
	"waterfall",
	"tail",
	"tooth",
	"increase",
	"donor",
	"indication",
	"cereal",
	"receipt",
	"trade",
	"community",
	"teach",
	"hypnothize",
	"bang",
	"develop",
	"rank",
	"rock",
	"contract",
	"employee",
	"concrete",
	"dismissal",
	"constituency",
	"lick",
	"battle",
	"peace",
	"machinery",
	"know",
	"wealth",
	"environmental",
	"smash",
	"ring",
	"kit",
	"responsibility",
	"amber",
	"familiar",
	"policy",
	"election",
	"unity",
	"explicit",
	"no",
	"consolidate",
	"reptile",
	"valid",
	"tourist",
	"resist",
	"stimulation",
	"X-ray",
	"complain",
	"turn",
	"visual",
	"steam",
	"immune",
	"bland",
	"chocolate",
	"magazine",
	"lesson",
	"leaf",
	"cage",
	"round",
	"wtawofawfkawüfkaowkfü",
	]

var window =  Window.new()
var oa_btn2 = OAdvancedOptionButton.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	get_viewport().gui_embed_subwindows = false
	window.borderless = false
	
	window.add_child(oa_btn2)
	add_child(window)
	
	window.show()
	#for string in test_arr:
		#$OComboBox.add_item(string)
	for string in test_arr:
		$OAdvancedOptionButton.add_item(string)
		oa_btn2.add_item(string)
		oa_btn2.set_item_metadata(oa_btn2.items.size()-1, string)


func _on_button_pressed() -> void:
	$OAdvancedOptionButton.add_item(random_string(randi_range(4, 20)))
	$OAdvancedOptionButton.add_separator("Tesss")

func random_string(length: int) -> String:
	var result = ""
	for i in range(length):
		result += random_letter_mixed()
	return result

func random_letter_mixed():
	var is_upper = randi() % 2 == 0
	return char(randi() % 26 + (65 if is_upper else 97))


func _on_o_advanced_option_button_2_item_selected(index: int, item: OAdvancedOptionBtnItem) -> void:
	print(oa_btn2.get_item_metadata(index))
	print(index)
	print(item.label)
