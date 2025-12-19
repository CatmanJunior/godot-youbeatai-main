extends Node
@onready var klappy_response = $"../Klappy respons bubble"
@export var message:String

func _ready() -> void:
	klappy_response.change_panel_visibility(true)
	klappy_response.fill_response_label(message)
	speak()

func speak():
	var voices = DisplayServer.tts_get_voices_for_language("nl")
	if voices.size() == 0:
		voices = DisplayServer.tts_get_voices_for_language("en")
	if(voices.size() == 0): voices = DisplayServer.tts_get_voices_for_language("en")
	if(DisplayServer.tts_is_speaking()):DisplayServer.tts_stop()
	DisplayServer.tts_speak(message,voices[0],100)

func _process(_delta: float) -> void:
	if not DisplayServer.tts_is_speaking():
		_on_timeout()

func _on_timeout():
	klappy_response.change_panel_visibility(false)
	DisplayServer.tts_stop()
