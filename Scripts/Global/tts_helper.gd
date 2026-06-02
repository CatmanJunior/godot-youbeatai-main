extends Node

const LANGUAGE : String = "nl"
const BASE_RATE : float = 1.0
const BASE_VOLUME : int = 100
const BASE_PITCH : float= 1.0

## How long the bubble lingers after a say()-spoken line finishes before auto-hiding.
const AUTO_HIDE_LINGER_SEC : float = 0.6

var initialized := false

var voice: String

## UID of the utterance whose bubble should auto-hide when it ends, or -1 if none.
var _auto_hide_uid: int = -1
## Bumped on every say()/clear() so stale auto-hide timers can detect they were superseded.
var _auto_hide_generation: int = 0

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
## The bubble auto-hides shortly after the utterance ends when [param auto_close] is true,
## unless [param show_continue] is set (in which case it stays until something else clears it).
## When [param auto_close] is false, the bubble stays visible until [method clear] or the next
## [method say] call replaces it.
## Returns the utterance ID (same as [method speak]), or -1 if text is empty.
func say(text: String, title: String = "", show_continue: bool = false, rate: float = BASE_RATE, auto_close: bool = true) -> int:
	if text.strip_edges().is_empty():
		return -1
	_auto_hide_generation += 1
	EventBus.set_klappy_speech_bubble.emit(text, title, show_continue)
	var uid: int = speak(text, rate)
	_auto_hide_uid = uid if (auto_close and not show_continue) else -1
	return uid

## Stops TTS and hides the Klappy speech bubble atomically.
func clear() -> void:
	_auto_hide_uid = -1
	_auto_hide_generation += 1
	stop_speaking()
	EventBus.set_klappy_speech_bubble.emit("", "", false)

func get_voice():
	if not voice.is_empty():
		return voice

	var voices := DisplayServer.tts_get_voices_for_language("nl")
	if voices.is_empty():
		voices = DisplayServer.tts_get_voices_for_language("en")
	print("available voices", voices)

	if voices.is_empty():
		return ""

	voice = voices[0]
	print("intialized tts voice: %s" % voice)
	return voice

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
	_maybe_auto_hide(utterance_id)

func utterance_cancel(utterance_id: int) -> void:
	print("speaking canceled")
	EventBus.utterance_canceled.emit(utterance_id)
	_maybe_auto_hide(utterance_id)

## Hides the say()-opened bubble shortly after its utterance settles, unless superseded.
func _maybe_auto_hide(utterance_id: int) -> void:
	if utterance_id != _auto_hide_uid:
		return
	_auto_hide_uid = -1
	var gen: int = _auto_hide_generation
	await get_tree().create_timer(AUTO_HIDE_LINGER_SEC).timeout
	if gen != _auto_hide_generation:
		return
	EventBus.set_klappy_speech_bubble.emit("", "", false)
