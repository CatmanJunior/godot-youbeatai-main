extends Node

# --- BPM properties ---
var beats_per_bar = 4.0

var bpm: int = 120:
	set(value):
		bpm = value
		EventBus.bpm_changed.emit(bpm)

var total_beats: int = 16

var _is_playing: bool = false

var playing: bool:
	set(value):
		if _is_playing != value:
			EventBus.playing_changed.emit(value)
		_is_playing = value
	get:
		return _is_playing

var current_beat: int = 0
var beat_elapsed: float = 0.0

var swing: float = 0.00

var beat_duration: float

var beat_progress: float = 0.0
var bar_progress: float = 0.0

func _ready():
	EventBus.bpm_up_requested.connect(func(value): bpm += value)
	EventBus.bpm_down_requested.connect(func(value): bpm -= value)
	EventBus.bpm_set_requested.connect(func(value): bpm = value)
	EventBus.play_pause_toggle_requested.connect(_on_play_pause_toggled)
	EventBus.playing_change_requested.connect(_on_playing_change_requested)
	EventBus.beat_seek_requested.connect(func(beat): current_beat = beat)
	EventBus.bpm_changed.emit(bpm)
	EventBus.swing_set_requested.connect(func(v: float): swing = v)

	EventBus.audio_bank_loaded.connect(_on_audio_bank_loaded)

	EventBus.beat_sprite_clicked.connect(_on_beat_sprite_clicked)
	EventBus.beat_set_requested.connect(set_beat)

func _on_audio_bank_loaded(bank: AudioBank) -> void:
	bpm = bank.bpm
	swing = bank.swing

# --- BPM functions ---
func get_beat_progress() -> float:
	var swing_adjusted_duration = beat_duration + (beat_duration * _get_swing_offset())
	var progress = beat_elapsed / swing_adjusted_duration
	return clamp(progress, 0.0, 1.0)

func get_bar_progress() -> float:
	var current_beat_with_progress = float(current_beat) + get_beat_progress()
	return current_beat_with_progress / float(total_beats)

func _on_play_pause_toggled():
	playing = not playing
	if not playing:
		EventBus.all_players_stop_requested.emit()

func _on_playing_change_requested(is_playing: bool):
	playing = is_playing
	if not playing:
		EventBus.all_players_stop_requested.emit()

func _process(delta: float):
	beat_duration = 60.0 / bpm / beats_per_bar
	beat_progress = get_beat_progress()
	bar_progress = get_bar_progress()
	GameState.beat_progress = beat_progress
	GameState.bar_progress = bar_progress
	GameState.total_beats = total_beats
	GameState.beat_duration = beat_duration

	if playing:
		beat_elapsed += delta
		var swing_adjusted_duration = beat_duration + (beat_duration * _get_swing_offset())
		if beat_elapsed > swing_adjusted_duration:
			beat_elapsed -= swing_adjusted_duration
			current_beat = (current_beat + 1) % total_beats
			EventBus.beat_triggered.emit(current_beat)

func _get_swing_offset() -> float:
	if current_beat % 2 == 1:
		return swing
	else:
		return -swing

# --- Beat manager functions ---
func _on_beat_sprite_clicked(p_track: int, beat: int):
	"""Handle beat sprite click via EventBus"""
	toggle_beat(p_track, beat)
	var is_active = get_beat(p_track, beat)
	if is_active:
		EventBus.play_track_requested.emit(p_track)
	if p_track < GameState.colors.size():
		EventBus.particles_requested.emit(Vector2.ZERO, GameState.colors[p_track])
	EventBus.track_selected.emit(p_track)

func toggle_beat(track: int, beat: int):
	"""Toggle a beat on or off"""
	GameState.current_section.toggle_beat(track, beat)
	var is_active = GameState.current_section.get_beat(track, beat)
	EventBus.beat_state_changed.emit(track, beat, is_active)

func set_beat(track: int, beat: int, active: bool):
	"""Set a beat to active or inactive"""
	GameState.current_section.set_beat(track, beat, active)
	EventBus.beat_state_changed.emit(track, beat, active)

func get_beat(track: int, beat: int) -> bool:
	"""Get whether a beat is active"""
	return GameState.current_section.get_beat(track, beat)
