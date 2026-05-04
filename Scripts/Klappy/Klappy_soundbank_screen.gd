extends Node
@onready var klappy_response = $"../Klappy respons bubble"
@export var message:String
@onready var talking = $"../Robot/SubViewportContainer/SubViewport/Klappy"

func _ready() -> void:
	EventBus.utterance_started.connect(start_speaking)	
	EventBus.utterance_ended.connect(done_speaking)
	EventBus.utterance_content_changed.connect(update_bubble)
	klappy_response.change_panel_visibility(false)
	
	speak()
	
func speak():
	TTSHelper.speak(message)

func start_speaking(id: int):
	klappy_response.change_panel_visibility(true)
	talking.talking = true

func update_bubble(text: String):
	klappy_response.fill_response_label(text)

func done_speaking(id: int):
	klappy_response.change_panel_visibility(false)
	talking.talking = false
	DisplayServer.tts_stop()
