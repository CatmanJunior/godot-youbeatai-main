extends Node

@export var track_settings_registry: TrackSettingsRegistry

var beats_per_bar = 4.0

var bpm: int:
	get: return SongState.bpm
	set(value):
		GameState.beat_duration = 60.0 / value / beats_per_bar
		EventBus.bpm_changed.emit(value)
		SongState.bpm = value

var total_beats: int:
	get: return SongState.total_beats
	set(value): SongState.total_beats = value

var playing: bool:
	set(value):
		if GameState.playing != value:
			EventBus.playing_changed.emit(value)
			GameState.playing = value
	get: return GameState.playing
	
var current_beat: int:
	get: return GameState.current_beat
	set(value):
		GameState.current_beat = value

var swing: float:
	get: return SongState.swing
	set(value): SongState.swing = value

var beat_duration: float:
	get: return GameState.beat_duration
	set(value): GameState.beat_duration = value

var beat_elapsed: float = 0.0

var beat_progress: float = 0.0
var bar_progress: float = 0.0

func _ready():
	if track_settings_registry == null:
		push_error("BeatManager: No TrackSettingsRegistry assigned! Please assign one in the inspector.")

	EventBus.bpm_up_requested.connect(func(value): bpm += value)
	EventBus.bpm_down_requested.connect(func(value): bpm -= value)
	EventBus.bpm_set_requested.connect(func(value): bpm = value)
	EventBus.play_pause_toggle_requested.connect(_on_play_pause_toggled)
	EventBus.playing_change_requested.connect(_on_playing_change_requested)
	EventBus.beat_seek_requested.connect(func(beat): current_beat = beat)
	EventBus.swing_set_requested.connect(func(v: float): swing = v)

	EventBus.audio_bank_loaded.connect(_on_audio_bank_loaded)

	EventBus.beat_sprite_clicked.connect(_on_beat_sprite_clicked)
	EventBus.beat_set_requested.connect(_set_beat)
	EventBus.template_set.connect(_on_template_set)

func _on_template_set(actives: Array) -> void:
	SongState.current_section.set_beat_actives(actives)

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
	
	beat_progress = get_beat_progress()
	bar_progress = get_bar_progress()
	GameState.beat_progress = beat_progress
	GameState.bar_progress = bar_progress

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

		EventBus.particles_requested.emit(Vector2.ZERO, track_settings_registry.get_color(p_track))
	EventBus.track_selected.emit(p_track)

func toggle_beat(track: int, beat: int):
	"""Toggle a beat on or off"""
	SongState.current_section.toggle_beat(track, beat)
	var is_active = SongState.current_section.get_beat(track, beat)
	EventBus.beat_state_changed.emit(track, beat, is_active)

func _set_beat(track: int, beat: int, active: bool):
	"""Set a beat to active or inactive"""
	SongState.current_section.set_beat(track, beat, active)
	EventBus.beat_state_changed.emit(track, beat, active)

func get_beat(track: int, beat: int) -> bool:
	"""Get whether a beat is active"""
	return SongState.current_section.get_beat(track, beat)
