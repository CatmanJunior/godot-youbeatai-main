extends Node


func _ready() -> void:
	if not GameState.tutorial_activated:
		_connect_signals()
	else:
		EventBus.on_tutorial_done.connect(_on_tutorial_done)

func _on_achievement_done(i):
	if GameState.achievements_active:
		match i:
			0:  _fill_instruction_label("De 📣 Snare heeft een helder geluid, die wordt meestal op de lijntjes gezet.")
			1:  _fill_instruction_label("Dit korte ⌚ Hi-hat geluid laat de boel lekker swingen, zet er maar eens een hele hoop neer")
			2:  _fill_instruction_label("Met de hoge 🐦 Synth, kan je het lekker druk maken, maar ook even een kort geluidje is die heel goed in.")
			3:  _fill_instruction_label("Met de + kan je het liedje nog langer maken, de icoontjes kunnen je helpen structuur te geven")
			4:  _fill_instruction_label("Oke nu gaat het echte werk beginnen met de 🎵 Song Mode, alle rondjes worden achter elkaar afgespeeld, en met de microfoon kan je een hele lange opname maken")
			5:  _fill_instruction_label("Wat een leuke sample, daar krijg ik energie ⚡ van !")
			6: _fill_instruction_label( "Haha leuk! sleep nu de vingerafdruk naar de 🎤 op de mixer dan hoor je jou sample in de beat ring")


func _on_tutorial_done() -> void:
	_connect_signals()

func _connect_signals() -> void:
	EventBus.achievement_done.connect(_on_achievement_done)
	EventBus.utterance_ended.connect(_on_utterance_end)


func _fill_instruction_label(_name:String):
	EventBus.set_klappy_speech_bubble.emit(_name, "", false)
	_start_tts(_name)

func _start_tts(message:String):
	TTSHelper.speak(TTSHelper.text_without_emoticons(message))

func _on_utterance_end(_utterance):
	EventBus.set_klappy_speech_bubble.emit("", "", false)


