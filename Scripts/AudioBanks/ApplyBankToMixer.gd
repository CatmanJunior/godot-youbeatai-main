extends Node

@export var bank: AudioBank

func _ready():
	on_audio_bank_loaded(bank)

func on_audio_bank_loaded(bank: AudioBank):
	
	var green_alt = AudioServer.get_bus_index("Green_alt")
	bank.effectProfile.apply_effects(green_alt)
	
	var green = AudioServer.get_bus_index("Green")
	bank.effectProfile.apply_effects(green)
	
	var purple = AudioServer.get_bus_index("Purple")
	bank.effectProfile.apply_effects(purple)
	
	var purple_alt = AudioServer.get_bus_index("Purple_alt")
	bank.effectProfile.apply_effects(purple_alt)
