extends Node

const LANGUAGE : String = "nl"
const BASE_RATE : float = 1.0
const BASE_VOLUME : int = 100
const BASE_PITCH : float= 1.0

func speak(text: String, rate: float = BASE_RATE, volume: int = BASE_VOLUME) -> void:
	var voices = get_voices()
	if voices.is_empty():
		return
	
	if DisplayServer.tts_is_speaking():
		stop_speaking()
	
	EventBus.utterance_content_changed.emit(text)
	DisplayServer.tts_speak(text, voices[0], volume, BASE_PITCH, rate)

func get_voices():
	var voices := DisplayServer.tts_get_voices_for_language("nl")
	if voices.is_empty():
		voices = DisplayServer.tts_get_voices_for_language("en")
	
	return voices

func stop_speaking():
	DisplayServer.tts_stop()

func Text_without_emoticons(text: String) -> String:
	var regex = RegEx.new()
	regex.compile(r":[^:\s]+:")
	return regex.sub(text, "")

func _ready():
	DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_ENDED, utterance_end)
	DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_STARTED, utterance_start)
	
func utterance_start(utterance_id: int):
	print("start speaking")
	EventBus.utterance_started.emit(utterance_id)
	
func utterance_end(utterance_id: int):
	print("done speaking")
	EventBus.utterance_ended.emit(utterance_id)
