extends Control

@export var uitleg : String
@export var tekstvak = Label


func _on_button_pressed() -> void:
	tekstvak.visible = true
	tekstvak.text = uitleg
	TTSHelper.speak(uitleg)
	
