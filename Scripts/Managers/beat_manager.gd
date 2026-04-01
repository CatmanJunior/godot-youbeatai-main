extends Node

# --- BPM properties ---
var beats_per_bar = 4.0

@export var bpm: int = 120:
	set(value):
		bpm = value
		EventBus.bpm_changed.emit(bpm)

static var total_beats: int = 16

@export var total_beat_count: int:
	get:
		return total_beats

var _is_playing: bool = false

@export var playing: bool:
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
	# BPM connections
	EventBus.bpm_up_requested.connect(func(value): bpm += value)
	EventBus.bpm_down_requested.connect(func(value): bpm -= value)
	EventBus.bpm_set_requested.connect(func(value): bpm = value)
	EventBus.play_pause_toggle_requested.connect(_on_play_pause_toggled)
	EventBus.playing_change_requested.connect(_on_playing_change_requested)
	EventBus.beat_seek_requested.connect(func(beat): current_beat = beat)
	EventBus.bpm_changed.emit(bpm)
	EventBus.swing_set_requested.connect(func(v: float): swing = v)

	# Beat manager connections
	EventBus.beat_sprite_clicked.connect(_on_beat_sprite_clicked)
	EventBus.beat_triggered.connect(_on_beat_triggered)
	EventBus.beat_set_requested.connect(set_beat)
	EventBus.template_set.connect(_on_template_set)
	EventBus.section_switched.connect(_on_section_switched)
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

func _on_section_switched(_old_section: SectionData, _new_section: SectionData):
	"""Reset beat states when switching sections"""
	for track in range(_new_section.SAMPLE_TRACKS_PER_SECTION):
		for beat in range(GameState.total_beats):
			var is_active = _new_section.get_beat(track, beat)
			EventBus.beat_state_changed.emit(track, beat, is_active)

func _on_beat_sprite_clicked(p_ring: int, beat: int):
	"""Handle beat sprite click via EventBus"""
	toggle_beat(p_ring, beat)
	var is_active = get_beat(p_ring, beat)
	if is_active:
		EventBus.play_sample_track_requested.emit(p_ring)
	if p_ring < GameState.colors.size():
		EventBus.particles_requested.emit(Vector2.ZERO, GameState.colors[p_ring])
	EventBus.track_selected.emit(p_ring)

func _on_beat_triggered(current_beat: int):
	"""Called when a beat occurs"""
	for track_index in range(GameState.current_section.SAMPLE_TRACKS_PER_SECTION):
		if GameState.current_section.get_beat(track_index, current_beat):
			EventBus.play_sample_track_requested.emit(track_index)
	if current_beat == 0:
		for track_index in range(GameState.current_section.SYNTH_TRACKS_PER_SECTION):
			EventBus.play_track_requested.emit(track_index + GameState.current_section.SAMPLE_TRACKS_PER_SECTION)

func _on_template_set(actives: Array):
	"""Apply template beat actives"""
	if GameState.current_section:
		GameState.current_section.set_beat_actives(actives)
	for track in actives.size():
		for beat in actives[track].size():
			EventBus.beat_state_changed.emit(track, beat, actives[track][beat])

func toggle_beat(ring: int, beat: int):
	"""Toggle a beat on or off"""
	GameState.current_section.toggle_beat(ring, beat)
	var is_active = GameState.current_section.get_beat(ring, beat)
	EventBus.beat_state_changed.emit(ring, beat, is_active)

func set_beat(ring: int, beat: int, active: bool):
	"""Set a beat to active or inactive"""
	GameState.current_section.set_beat(ring, beat, active)
	EventBus.beat_state_changed.emit(ring, beat, active)

func get_beat(ring: int, beat: int) -> bool:
	"""Get whether a beat is active"""
	return GameState.current_section.get_beat(ring, beat)
