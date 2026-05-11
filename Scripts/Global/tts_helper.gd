extends Node

const LANGUAGE : String = "nl"
const BASE_RATE : float = 1.0
const BASE_VOLUME : int = 100
const BASE_PITCH : float= 1.0

var initialized := false

func init():
	if initialized:
		return

	initialized = true
	
	if not OS.has_feature("web"):
		return
	
	# try to speak, it wont play but will enable the tts
	speak("test")

func speak(text: String, rate: float = BASE_RATE, volume: int = BASE_VOLUME) -> void:
	if GameState.mute_speech:
		return

	var voices = get_voices()
	if voices.is_empty():
		return
	
	if DisplayServer.tts_is_speaking():
		stop_speaking()
	
	EventBus.utterance_content_changed.emit(text)
	DisplayServer.tts_speak(text_without_emoticons(text), voices[0], volume, BASE_PITCH, rate)

func get_voices():
	var voices := DisplayServer.tts_get_voices_for_language("nl")
	if voices.is_empty():
		voices = DisplayServer.tts_get_voices_for_language("en")
	
	return voices

func stop_speaking():
	DisplayServer.tts_stop()

func text_without_emoticons(text: String) -> String:
	var colon_regex := RegEx.new()
	colon_regex.compile(r":[^:\s]+:")
	var result := colon_regex.sub(text, "", true)

	var emoji_regex := RegEx.new()
	emoji_regex.compile(r"\p{Emoji_Presentation}|\p{Extended_Pictographic}")
	result = emoji_regex.sub(result, "", true)
	return result.replace("!", "").replace("'", "").replace('"', "")

func _ready():
	DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_ENDED, utterance_end)
	DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_STARTED, utterance_start)
	
func utterance_start(utterance_id: int):
	print("start speaking")
	EventBus.utterance_started.emit(utterance_id)
	
func utterance_end(utterance_id: int):
	print("done speaking")
	EventBus.utterance_ended.emit(utterance_id)
