class_name TTSHelper

const LANGUAGE : String = "nl"
const BASE_RATE : float = 1.0
const BASE_VOLUME : int = 100
const BASE_PITCH : float= 1.0

static func speak(text: String, rate: float = BASE_RATE, volume: int = BASE_VOLUME) -> void:
	var voices := DisplayServer.tts_get_voices_for_language("nl")
	if voices.is_empty():
		voices = DisplayServer.tts_get_voices_for_language("en")
	if voices.is_empty():
		return
	if DisplayServer.tts_is_speaking():
		DisplayServer.tts_stop()
	DisplayServer.tts_speak(text, voices[0], volume, BASE_PITCH, rate)


static func text_without_emoticons(text: String) -> String:
	var regex = RegEx.new()
	regex.compile(r":[^:\s]+:")
	return regex.sub(text, "")


func _ready() -> void:
	DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_ENDED, _utterance_end)



func _utterance_end(utterance_id: int) -> void:
	EventBus.utterance_ended.emit(utterance_id)