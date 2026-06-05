extends Node
class_name BeatManager

@export var track_settings_registry: TrackUISettingsRegistry

@export var swing_reduce_amount: float = 0.2

const BEATS_PER_BAR: int = 4
const BEAT_EARLY_FIRE_TOLERANCE_SWING: float = 0.005

var bpm: int:
	get: return SongState.bpm
	set(value):
		EventBus.bpm_changed.emit(value)

var total_beats: int:
	get: return SongState.beats_per_section
	set(value): SongState.beats_per_section = value

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
	set(value):
		EventBus.swing_changed.emit(value)

var beat_duration: float:
	get: return SongState.beat_duration
	set(value): SongState.beat_duration = value

var beat_elapsed: float = 0.0
var beat_progress: float = 0.0
var bar_progress: float = 0.0

var last_beat_time = Time.get_ticks_msec()

func _ready():
	if track_settings_registry == null:
		push_error("BeatManager: No TrackUISettingsRegistry assigned! Please assign one in the inspector.")

	EventBus.bpm_up_requested.connect(func(value): bpm += value)
	EventBus.bpm_down_requested.connect(func(value): bpm -= value)
	EventBus.bpm_set_requested.connect(func(value): bpm = value)
	EventBus.play_pause_toggle_requested.connect(_on_play_pause_toggled)
	EventBus.playing_change_requested.connect(_on_playing_change_requested)
	EventBus.beat_seek_requested.connect(func(beat):
		current_beat = beat
		
		if playing:
			EventBus.beat_triggered.emit(0)
	)
	EventBus.swing_set_requested.connect(func(v: float): swing = v)

	EventBus.soundbank_loaded.connect(_on_soundbank_loaded)

	EventBus.beat_sprite_clicked.connect(_on_beat_sprite_clicked)
	EventBus.beat_set_requested.connect(_set_beat)
	EventBus.template_set.connect(_on_template_set)

func _on_template_set(actives: Array) -> void:
	SongState.current_section.set_beat_actives(actives)

func _on_soundbank_loaded(bank: SoundBank) -> void:
	print("Soundbank loaded: %s" % bank)
	bpm = bank.bpm
	swing = bank.swing * swing_reduce_amount

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

	if playing:
		EventBus.beat_triggered.emit(current_beat)

	if not playing:
		EventBus.all_players_stop_requested.emit()

func _on_playing_change_requested(is_playing: bool):
	playing = is_playing

	if playing:
		EventBus.beat_triggered.emit(current_beat)
	
	if not playing:
		EventBus.all_players_stop_requested.emit()

func _process(_delta: float):
	beat_progress = get_beat_progress()
	bar_progress = get_bar_progress()
	GameState.beat_progress = beat_progress
	GameState.bar_progress = bar_progress
	
	if playing:
		var current_time = Time.get_ticks_msec()
		var elapsed = current_time - last_beat_time
		var swing_adjusted_duration = beat_duration + (beat_duration * _get_swing_offset())
		beat_elapsed = elapsed / 1000.0
	
		if elapsed >= (swing_adjusted_duration - BEAT_EARLY_FIRE_TOLERANCE_SWING) * 1000:
			beat_elapsed = 0
			current_beat = (current_beat + 1) % total_beats
			EventBus.pre_beat_triggered.emit(current_beat)
			EventBus.beat_triggered.emit(current_beat)

			_trigger_animations_on_beat(current_beat)

			last_beat_time = current_time

func _trigger_animations_on_beat(beat: int) -> void:
	if SongState.current_section.get_beat(0, beat):
		EventBus.trigger_animation_requested.emit(KlappyAnimations.AnimationType.STAMP)
	if SongState.current_section.get_beat(1, beat):
		EventBus.trigger_animation_requested.emit(KlappyAnimations.AnimationType.CLAP)

func _get_swing_offset() -> float:
	if current_beat % 2 == 1:
		return swing
	else:
		return -swing
 
# --- Beat manager functions ---
func _on_beat_sprite_clicked(p_track: int, beat: int):
	var is_active = SongState.current_section.get_beat(p_track, beat)
	if not is_active and not (GameState.use_tutorial or GameState.energy_points >= 1.0):
		EventBus.beat_state_changed.emit(p_track, beat, is_active)
		EventBus.not_enough_energy.emit()
		return
	
	_set_beat(p_track, beat, not is_active)

	if not is_active:
		EventBus.play_track_requested.emit(p_track)
		EventBus.particles_requested.emit(Vector2.ZERO, track_settings_registry.get_track(p_track).track_color)

	EventBus.track_selected.emit(p_track)

func _set_beat(track: int, beat: int, active: bool):
	"""Set a beat to active or inactive"""
	SongState.current_section.set_beat(track, beat, active)
	EventBus.beat_state_changed.emit(track, beat, active)


static func calculate_time_until_top() -> float:
	var cur_beat: int = GameState.current_beat
	var beats_until_top: int = SongState.beats_per_section - cur_beat - 1
	var duration_until_top: float = (beats_until_top + 1 - GameState.beat_progress) * SongState.beat_duration
	return duration_until_top

static func calculate_beat_duration(p_bpm: int, p_total_beats: int, beats_per_bar: int) -> float:
	var _beat_duration: float = snapped((60.0 / p_bpm) / p_total_beats * beats_per_bar, 0.001)
	return _beat_duration
