extends Node
@export var manager:Manager
@export var achievment_panel:Panel
var instruction_label:Label

func _ready() -> void:
	assert(manager!= null,"manger not found")
	manager.OnAchievementDone.connect(_on_achievement_done)
	manager.OnUtteranceEnd.connect(_on_utterance_end)
	_get_insrtuction_label()


func _on_achievement_done(i):
	match i:
		0:  _fill_instruction_label("de snare knop")
		1:  _fill_instruction_label("de hi-hat knop")
		2:  _fill_instruction_label("de paarse synth")
		3:  _fill_instruction_label("de nieuwe layer knop")
		4:  _fill_instruction_label("de song mode")
		5:  _fill_instruction_label("de energy opslag")

func _fill_instruction_label(_name:String):
	if instruction_label == null : push_error("Label not found")
	var message = "Jij hebt %s voltooid!"
	var message_name= message % _name
	instruction_label.text = message_name
	_achievement_panel_visibility(0)
	_start_tts(message_name)

func _achievement_panel_visibility(_utterance_id:int):
	print("panel visibility yay")
	achievment_panel.visible = !achievment_panel.visible


func _start_tts(message:String):
	var voices = DisplayServer.tts_get_voices_for_language("nl")
	if(voices.size() == 0): voices = DisplayServer.tts_get_voices_for_language("en")
	if(DisplayServer.tts_is_speaking()):DisplayServer.tts_stop()
	DisplayServer.tts_speak(message,voices[0],100)

func _on_utterance_end(_utterance):
	achievment_panel.visible = false

func _get_insrtuction_label():
	for c in achievment_panel.get_children():
		if c.name == "InstructionLabel":
			instruction_label = c
