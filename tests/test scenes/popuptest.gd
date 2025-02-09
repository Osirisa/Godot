extends Control

var test_arr := ["test",
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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for string in test_arr:
		$OComboBox.add_item(string)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	$OComboBox.add_item(random_string(randi_range(4, 20)))
	$OComboBox.add_separator("Tesss")

func random_string(length: int) -> String:
	var result = ""
	for i in range(length):
		result += random_letter_mixed()
	return result

func random_letter_mixed():
	var is_upper = randi() % 2 == 0
	return char(randi() % 26 + (65 if is_upper else 97))
