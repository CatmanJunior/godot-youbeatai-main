extends Node

@export var bpm: int = 120:
	set(value):
		bpm = value
		on_bpm_changed.emit(bpm)

static var beats_amount: int = 16

@export var amount_of_beats: int:
	get:
		return beats_amount

var _playing: bool = false

@export var playing: bool:
	set(value):
		if _playing != value:
			on_playing_changed.emit(value)
		_playing = value
	get:
		return _playing

@export var current_beat: int = beats_amount - 1
var beat_timer: float = 0.0

@export var swing: float = 0.05

var base_time_per_beat: float
var time_per_beat: float

#----------------- Signals -----------------------
signal on_beat_event(beat: int)
signal on_bpm_changed(bpm: float)
signal on_playing_changed(playing: bool)

func _ready():
	pass

func _process(delta: float):
	if playing:
		beat_timer += delta
		var beats_per_bar = 4.0
		base_time_per_beat = 60.0 / bpm / beats_per_bar
		time_per_beat = base_time_per_beat + (base_time_per_beat * swing) if (current_beat % 2 == 1) else base_time_per_beat - (base_time_per_beat * swing)
		
		if beat_timer > time_per_beat:
			beat_timer -= time_per_beat
			current_beat = (current_beat + 1) % beats_amount
			on_beat_event.emit(current_beat)
