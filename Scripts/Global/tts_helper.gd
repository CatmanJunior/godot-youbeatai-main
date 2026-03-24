class_name TTSHelper

static func speak(text: String, rate: float = 1.0, volume: int = 100) -> void:
	var voices := DisplayServer.tts_get_voices_for_language("nl")
	if voices.is_empty():
		voices = DisplayServer.tts_get_voices_for_language("en")
	if voices.is_empty():
		return
	if DisplayServer.tts_is_speaking():
		DisplayServer.tts_stop()
	DisplayServer.tts_speak(text, voices[0], volume, 1.0, rate)
