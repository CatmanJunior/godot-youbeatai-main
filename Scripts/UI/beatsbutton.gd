extends Panel
#TODO omg wtf lol?
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$"8/pressed".visible = false
	$"16/pressed".visible = true
	$"32/pressed".visible = false

func _on_button_pressed() -> void:
	$"8/pressed".visible = true
	$"16/pressed".visible = false
	$"32/pressed".visible = false

func _on_button_2_pressed() -> void:
	$"8/pressed".visible = false
	$"16/pressed".visible = true
	$"32/pressed".visible = false

func _on_button_3_pressed() -> void:
	$"8/pressed".visible = false
	$"16/pressed".visible = false
	$"32/pressed".visible = true
