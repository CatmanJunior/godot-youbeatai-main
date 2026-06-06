extends Node
class_name ClapStompDetector

const CLAP_TRACK: int = 1
const STOMP_TRACK: int = 0

# Clap and stomp detection
var clapped_amount: int = 0
var clapped_on_beat_amount: int = 0
var stomped_amount: int = 0
var stomped_on_beat_amount: int = 0

@export var clap_freq_min: float = 2000.0
@export var clap_threshold: float = 0.03
@export var stamp_freq_max: float = 150.0
@export var stamp_threshold: float = 0.1
@export var beat_on_beat_window: float = 0.25

var is_clapping: bool:
	get: return clap_volume > clap_threshold and clap_volume > stamp_volume
var is_stamping: bool:
	get: return stamp_volume > stamp_threshold and stamp_volume > clap_volume

# Live analysis
var clap_volume: float = 0.0
var stamp_volume: float = 0.0

var _clap_on_beat_registered: bool = false
var _stomp_on_beat_registered: bool = false

func _process(_delta: float):
	# Live volume analysis
	stamp_volume = _get_magnitude(0.0, stamp_freq_max)
	clap_volume = _get_magnitude(clap_freq_min, 20000.0)

	if is_clapping:
		EventBus.clap_stomp_detected.emit(InteractionType.CLAP)
	elif is_stamping:
		EventBus.clap_stomp_detected.emit(InteractionType.STOMP)
		

func _get_magnitude(_freq_min: float, _freq_max: float) -> float:
	return MicrophoneRecorder.get_magnitude(_freq_min, _freq_max)

enum InteractionType {
	STOMP,
	CLAP
}

func _ready() -> void:
	EventBus.clap_stomp_detected.connect(_handle_clap_stomp)
	EventBus.beat_triggered.connect(_on_beat_triggered)


func _on_beat_triggered(_beat: int) -> void:
	_clap_on_beat_registered = false
	_stomp_on_beat_registered = false

func _handle_clap_stomp(interaction_type: InteractionType) -> void:
	# Emit signals for next beat
	var track_index = CLAP_TRACK if interaction_type == InteractionType.CLAP else STOMP_TRACK
	var on_beat: bool = _is_clap_stomp_next_beat(interaction_type)
	if on_beat and GameState.playing:
		if interaction_type == InteractionType.CLAP and not _clap_on_beat_registered:
			_clap_on_beat_registered = true
			clapped_on_beat_amount += 1
			EventBus.clap_on_beat_detected.emit()
		elif interaction_type == InteractionType.STOMP and not _stomp_on_beat_registered:
			_stomp_on_beat_registered = true
			stomped_on_beat_amount += 1
			EventBus.stomp_on_beat_detected.emit()
	else:
		if interaction_type == InteractionType.CLAP:
			clapped_amount += 1
		else:
			stomped_amount += 1

	if GameState.clap_adds_beats and interaction_type == InteractionType.CLAP:
		EventBus.beat_set_requested.emit(track_index, GameState.current_beat, true)


func _is_clap_stomp_next_beat(interaction_type: InteractionType) -> bool:
	if not GameState.playing:
		return false
	var progress: float = GameState.beat_progress
	var track_index: int = CLAP_TRACK if interaction_type == InteractionType.CLAP else STOMP_TRACK

	# Head window: beat just fired, check if current beat is set
	if progress < beat_on_beat_window:
		return SongState.current_section.get_beat(track_index, GameState.current_beat)

	# Tail window: approaching next beat, check if next beat is set
	if progress > 1.0 - beat_on_beat_window:
		var next_beat: int = (GameState.current_beat + 1) % SongState.beats_per_section
		return SongState.current_section.get_beat(track_index, next_beat)

	# Outside both windows — not on beat
	return false
