extends Node

@export var achievement_panel:Panel
var instruction_label:Label

func _ready() -> void:
	if not GameState.tutorialActivated:
		EventBus.achievement_done.connect(_on_achievement_done)
		EventBus.utterance_ended.connect(_on_utterance_end)
	_get_instruction_label()

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
	if not achievement_panel.visible :
		achievement_panel.visible = true



func _start_tts(message:String):
	var voices = DisplayServer.tts_get_voices_for_language("nl")
	if voices.size() == 0:
		voices = DisplayServer.tts_get_voices_for_language("en")

	if(voices.size() == 0): voices = DisplayServer.tts_get_voices_for_language("en")
	if(DisplayServer.tts_is_speaking()):DisplayServer.tts_stop()
	DisplayServer.tts_speak(GameState.Text_without_emoticons(message),voices[0],100)

func _on_utterance_end(_utterance):
	achievement_panel.visible = false

func _get_instruction_label():
	for c in achievement_panel.get_children():
		if c.name == "InstructionLabel":
			instruction_label = c
