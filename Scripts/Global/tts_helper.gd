extends Node

const LANGUAGE : String = "nl"
const BASE_RATE : float = 1.0
const BASE_VOLUME : int = 100
const BASE_PITCH : float= 1.0

var initialized := false

var voice: String

func init():
	if initialized:
		return

	initialized = true	

	if not OS.has_feature("web"):
		return
	
	# try to speak, it wont play but will enable the tts
	speak("test", BASE_RATE, 100)
	await get_tree().process_frame
	stop_speaking()

var _next_uid: int = 1

## Speaks [param text] via TTS and returns the utterance ID, or -1 if skipped.
## Automatically respects [member GameState.mute_speech] (volume set to 0, still fires utterance_ended).
func speak(text: String, rate: float = BASE_RATE, volume: int = BASE_VOLUME) -> int:
	if text.strip_edges().is_empty():
		return -1
	if len(voice) == 0:
		voice = get_voice()

	EventBus.utterance_content_changed.emit(text)

	var mute: int = 0 if GameState.mute_speech else 1
	var uid: int = _next_uid
	_next_uid += 1
	DisplayServer.tts_speak(text_without_emoticons(text), voice, volume * mute, BASE_PITCH, rate, uid, true)
	return uid

## Shows the Klappy speech bubble with [param text] and speaks it via TTS in one atomic call.
## Returns the utterance ID (same as [method speak]), or -1 if text is empty.
func say(text: String, title: String = "", show_continue: bool = false, rate: float = BASE_RATE) -> int:
	if text.strip_edges().is_empty():
		return -1
	EventBus.set_klappy_speech_bubble.emit(text, title, show_continue)
	return speak(text, rate)

## Stops TTS and hides the Klappy speech bubble atomically.
func clear() -> void:
	stop_speaking()
	EventBus.set_klappy_speech_bubble.emit("", "", false)

func get_voice():
	var voices := DisplayServer.tts_get_voices_for_language("nl")
	if voices.is_empty():
		voices = DisplayServer.tts_get_voices_for_language("en")
	print("available voices", voices)
	
	if voices.is_empty():
		return ""

	print("intialized tts voice: %s" % voices[0])
	return voices[0]

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

func _ready() -> void:
	DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_ENDED, utterance_end)
	DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_STARTED, utterance_start)
	DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_CANCELED, utterance_cancel)
	
func utterance_start(utterance_id: int) -> void:
	print("start speaking")
	EventBus.utterance_started.emit(utterance_id)
	
func utterance_end(utterance_id: int) -> void:
	print("done speaking")
	EventBus.utterance_ended.emit(utterance_id)

func utterance_cancel(utterance_id: int) -> void:
	print("speaking canceled")
	EventBus.utterance_canceled.emit(utterance_id)
