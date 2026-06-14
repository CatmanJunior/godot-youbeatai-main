class_name Metronome
extends AudioStreamPlayer

const STEPS_PER_METRONOME_CLICK: int = 4

var klappy_amount = 3

func _ready():
	EventBus.beat_triggered.connect(on_beat)

func on_beat(_beat:int):
	if not GameState.metronome_enabled:
		return

	if _beat % STEPS_PER_METRONOME_CLICK == 0:
		if GameState.use_tutorial:
			TTSHelper.speak(str(klappy_amount),2.0)
			klappy_amount -=1
			if klappy_amount == 0:
				klappy_amount = 3
		play()
