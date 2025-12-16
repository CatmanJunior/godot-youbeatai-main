extends Node
@export var manager:Manager
@export var achievment_panel:Panel
var instruction_label:Label


func _ready() -> void:
	assert(manager!= null,"manger not found")
	if not manager.tutorialActivated():
		manager.OnAchievementDone.connect(_on_achievement_done)
		manager.OnUtteranceEnd.connect(_on_utterance_end)
	_get_insrtuction_label()


func _on_achievement_done(i):
	match i:
		0:  _fill_instruction_label("De 📣 Snare heeft een helder geluid, die wordt meestal op de lijntjes gezet.")
		1:  _fill_instruction_label("Dit korte ⌚ Hi-hat geluid laat de boel lekker swingen, zet er maar eens een hele hoop neer")
		2:  _fill_instruction_label("Met de hoge 🐦 Synth, kan je het lekker druk maken, maar ook even een kort geluidje is die heel goed in.")
		3:  _fill_instruction_label("Met de + kan je het liedje nog langer maken, de icoontjes kunnen je helpen structuur te geven")
		4:  _fill_instruction_label("Oke nu gaat het echte werk beginnen met de 🎵 Song Mode, alle rondjes worden achter elkaar afgespeeld, en met de microfoon kan je een hele lange opname maken")
		5:  _fill_instruction_label("Wat een leuke sample, daar krijg ik energie ⚡ van !")
		6: _fill_instruction_label( "Haha leuk! sleep nu de vingerafdruk naar de 🎤 op de mixer dan hoor je jou sample in de beat ring")

func _fill_instruction_label(_name:String):
	if instruction_label == null : push_error("Label not found")
	instruction_label.text = _name
	_achievement_panel_visibility(0)
	_start_tts(_name)

func _achievement_panel_visibility(_utterance_id:int):
	print("panel visibility yay")
	if not achievment_panel.visible :
		achievment_panel.visible = true



func _start_tts(message:String):
	var voices = DisplayServer.tts_get_voices_for_language("nl")
	if voices.size() == 0:
		voices = DisplayServer.tts_get_voices_for_language("en")

	if(voices.size() == 0): voices = DisplayServer.tts_get_voices_for_language("en")
	if(DisplayServer.tts_is_speaking()):DisplayServer.tts_stop()
	DisplayServer.tts_speak(manager.Text_without_emoticons(message),voices[0],100)

func _on_utterance_end(_utterance):
	achievment_panel.visible = false

func _get_insrtuction_label():
	for c in achievment_panel.get_children():
		if c.name == "InstructionLabel":
			instruction_label = c
