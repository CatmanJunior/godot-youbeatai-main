extends Node

func free() -> void:
	OS.open_midi_inputs()

func _input(input_event):
	if input_event is InputEventMIDI:
		_print_midi_info(input_event)

func _print_midi_info(midi_event):
	#if delay: return
	if (midi_event.message == 250):
		print("received MIDI Start")
		pass
	if (midi_event.message == 252):
		print("received MIDI Stop")
		pass
