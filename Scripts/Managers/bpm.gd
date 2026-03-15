extends Node

@export var bpm: int = 120:
	set(value):
		bpm = value
		EventBus.bpm_changed.emit(bpm)

static var beats_amount: int = 16

@export var amount_of_beats: int:
	get:
		return beats_amount

var _playing: bool = false

@export var playing: bool:
	set(value):
		if _playing != value:
			EventBus.playing_changed.emit(value)
		_playing = value
	get:
		return _playing

@export var current_beat: int = beats_amount - 1
var beat_timer: float = 0.0

@export var swing: float = 0.05

var base_time_per_beat: float
var time_per_beat: float = 60.0 / bpm

var beat_progress: float = 0.0
var bar_progress: float = 0.0

func get_beat_progress() -> float:
	var new_beat_progress = beat_timer / time_per_beat
	if current_beat % 2 == 1:
		# Swing the odd beats by adding the swing percentage to the beat progress
		new_beat_progress += swing
	else:
		# Swing the even beats by subtracting the swing percentage from the beat progress
		new_beat_progress -= swing
	return clamp(new_beat_progress, 0.0, 1.0)

func get_bar_progress() -> float:
	var total_beats = beats_amount
	var current_beat_with_progress = float(current_beat) + get_beat_progress()
	return current_beat_with_progress / float(total_beats)

func _ready():
	EventBus.bpm_up_requested.connect(func(value): bpm += value)
	EventBus.bpm_down_requested.connect(func(value): bpm -= value)
	EventBus.bpm_set_requested.connect(func(value): bpm = value)
	EventBus.play_pause_toggled.connect(func(): playing = !playing)
	EventBus.playing_change_requested.connect(_on_playing_change_requested)
	EventBus.bpm_changed.emit(bpm)


func _on_playing_change_requested(isplaying: bool):
	playing = isplaying
	

func _process(delta: float):
	beat_progress = get_beat_progress()
	bar_progress = get_bar_progress()
	GameState.beat_progress = beat_progress
	GameState.bar_progress = bar_progress
	
	if playing:
		beat_timer += delta
		var beats_per_bar = 4.0
		base_time_per_beat = 60.0 / bpm / beats_per_bar
		time_per_beat = base_time_per_beat + (base_time_per_beat * swing) if (current_beat % 2 == 1) else base_time_per_beat - (base_time_per_beat * swing)
		
		if beat_timer > time_per_beat:
			beat_timer -= time_per_beat
			current_beat = (current_beat + 1) % beats_amount
			EventBus.beat_triggered.emit(current_beat)
