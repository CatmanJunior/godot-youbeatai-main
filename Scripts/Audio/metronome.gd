class_name Metronome
extends AudioStreamPlayer

const STEPS_PER_METRONOME_CLICK: int = 4

var klappy_amount = 3

var _amount_to_do: int = 3
var _set_amount: bool = false

func _ready():

	EventBus.beat_triggered.connect(on_beat)
	EventBus.metronome_do_amount.connect(_on_metronome_do_amount)

func _on_metronome_do_amount(amount: int) -> void:
	_amount_to_do = amount
	_set_amount = true
	GameState.metronome_enabled = true

func on_beat(_beat: int) -> void:
	if not GameState.metronome_enabled:
		return

	if _beat % STEPS_PER_METRONOME_CLICK == 0:
		if _set_amount:
			play()
			_amount_to_do -= 1
			if _amount_to_do <= 0:
				_set_amount = false
				GameState.metronome_enabled = false
		if GameState.use_tutorial:
			TTSHelper.speak(str(klappy_amount), 2.0)
			klappy_amount -= 1
			if klappy_amount == 0:
				klappy_amount = 3
		play()
