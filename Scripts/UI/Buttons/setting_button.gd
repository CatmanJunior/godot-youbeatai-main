extends Control

@export var uitleg : String
@export var tekstvak = Label


func _on_button_pressed() -> void:
	tekstvak.visible = true
	tekstvak.text = uitleg
	_speak_text(uitleg)
	

func _speak_text(text:String) -> void:
	var voices = DisplayServer.tts_get_voices_for_language("nl")
	
	if voices.size() == 0:
		voices = DisplayServer.tts_get_voices_for_language("en")
	
	if voices.size() > 0:
		if DisplayServer.tts_is_speaking():
			DisplayServer.tts_stop()
			
		DisplayServer.tts_speak(text, voices[0], 100)
