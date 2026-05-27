extends Node

var _uid: int = -1

func _ready() -> void:
	EventBus.achievement_done.connect(_on_achievement_done)
	if not GameState.tutorial_activated:
		_connect_signals()
	else:
		EventBus.on_tutorial_done.connect(_on_tutorial_done)

func _on_achievement_done(i: int) -> void:
	print("Achievement %d done, showing instruction for it" % i)
	if GameState.achievements_active:
		match i:
			AchievementDef.AchievementNode.TRACK_2:
				_say("De 📣 Snare heeft een helder geluid, die wordt meestal op de lijntjes gezet.")
			AchievementDef.AchievementNode.TRACK_3:
				_say("Dit korte ⌚ Hi-hat geluid laat de boel lekker swingen, zet er maar eens een hele hoop neer")
			AchievementDef.AchievementNode.SYNTH_2:
				_say("Met de hoge 🐦 Synth, kan je het lekker druk maken, maar ook even een kort geluidje is die heel goed in.")
			AchievementDef.AchievementNode.ADD_SECTION:
				_say("Met de + kan je het liedje nog langer maken, de icoontjes kunnen je helpen structuur te geven")
			AchievementDef.AchievementNode.SONG_MODE:
				_say("Oke nu gaat het echte werk beginnen met de 🎵 Song Mode, alle rondjes worden achter elkaar afgespeeld, en met de microfoon kan je een hele lange opname maken")
			AchievementDef.AchievementNode.FIRST_SAMPLE:
				_say("Gaaf! Je hebt je eerste 🎤 geluid opgenomen, zet hem in de ring!")
			AchievementDef.AchievementNode.SECOND_SAMPLE:
				_say("Wat een leuke sample, daar krijg ik energie ⚡ van !")
			AchievementDef.AchievementNode.TEMPLATE_TIP:
				_say("Ik weet een leuke beat voor je, in de beat ring staan nu stipjes die je een hint geven")


func _on_tutorial_done() -> void:
	print("Tutorial done, connecting signals for klappy reaction")
	_connect_signals()

func _connect_signals() -> void:
	if not EventBus.utterance_ended.is_connected(_on_utterance_end):
		EventBus.utterance_ended.connect(_on_utterance_end)


func _say(text: String) -> void:
	print("Filling instruction label with message: %s" % text)
	_uid = TTSHelper.say(text)

func _on_utterance_end(utterance: int) -> void:
	if utterance != _uid:
		return
	if GameState.use_tutorial:
		return
	TTSHelper.clear()
