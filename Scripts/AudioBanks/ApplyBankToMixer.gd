extends Node

@export var bank: AudioBank

func _ready():
	on_audio_bank_loaded(bank)

func on_audio_bank_loaded(bank: AudioBank):
	
	var green_alt = AudioServer.get_bus_index("Green_alt")
	bank.effectProfile.apply(green_alt)
	
	var green = AudioServer.get_bus_index("Green")
	bank.effectProfile.apply(green)
	
	var purple = AudioServer.get_bus_index("Purple")
	bank.effectProfile.apply(purple)
	
	var purple_alt = AudioServer.get_bus_index("Purple_alt")
	bank.effectProfile.apply(purple_alt)
