extends Node
@onready var klappy_response = $"../Klappy respons bubble"
@export var message:String
@onready var talking = $"../Robot/SubViewportContainer/SubViewport/Klappy"

func _ready() -> void:
	klappy_response.change_panel_visibility(true)
	klappy_response.fill_response_label(message)
	speak()
	talking.talking = true
	
func speak():
	TTSHelper.speak(message)

func _process(_delta: float) -> void:
	if not DisplayServer.tts_is_speaking():
		_on_timeout()

func _on_timeout():
	klappy_response.change_panel_visibility(false)
	DisplayServer.tts_stop()
	talking.talking = false
