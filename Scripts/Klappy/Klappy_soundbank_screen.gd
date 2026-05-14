extends Node

@export var message: String
@export var tutmessage: String

const INTRO_MESSAGE: String = "hoi ik ben klappy en wij gaan samen een beat maken"

var _intro_spoken: bool = false


func _ready() -> void:
	EventBus.utterance_ended.connect(_on_utterance_ended)
	#wait for 0.5 seconds to make sure everything is loaded and ready before speaking, otherwise the tts might not work
	await get_tree().create_timer(0.5).timeout
	_speak_intro()

func _speak_intro() -> void:
	_speak_with_bubble(INTRO_MESSAGE)
	_intro_spoken = true

func _speak_with_bubble(text: String) -> void:
	EventBus.set_klappy_speech_bubble.emit(text, "", false)
	TTSHelper.speak(text)


func _on_utterance_ended(_id: int) -> void:
	if _intro_spoken:
		var msg: String = tutmessage if GameState.use_tutorial else message
		_speak_with_bubble(msg)

