extends Node
class_name ClapStompDetector

const CLAP_TRACK: int = 1
const STOMP_TRACK: int = 0

@export var clap_freq_min: float = 2000.0
@export var clap_threshold: float = 0.03
@export var stamp_freq_max: float = 150.0
@export var stamp_threshold: float = 0.1
@export var beat_on_beat_window: float = 0.25

## Onset detection: an interaction only registers when the band volume rises sharply
## above its adaptive noise floor. This rejects the steady low-frequency energy a live
## microphone always carries (mains hum, DC offset, self-noise) which would otherwise
## make is_stamping permanently true and fire false stomps on every kick beat.
@export var onset_ratio: float = 3.0
## How quickly the noise-floor baseline tracks the live signal (per frame, 0–1).
## Low = slow adaptation, so a transient spike stays well above the baseline.
@export var baseline_adapt: float = 0.05

var is_clapping: bool:
	get: return clap_volume > clap_threshold \
		and clap_volume > stamp_volume \
		and clap_volume > _clap_baseline * onset_ratio
var is_stamping: bool:
	get: return stamp_volume > stamp_threshold \
		and stamp_volume > clap_volume \
		and stamp_volume > _stamp_baseline * onset_ratio

# Live analysis
var clap_volume: float = 0.0
var stamp_volume: float = 0.0

# Adaptive noise-floor estimates (exponential moving average of each band).
var _clap_baseline: float = 0.0
var _stamp_baseline: float = 0.0

var _beat_epoch: int = 0
var _last_clap_registered_epoch: int = -1
var _last_stomp_registered_epoch: int = -1

func _process(_delta: float):
	# Live volume analysis
	stamp_volume = _get_magnitude(0.0, stamp_freq_max)
	clap_volume = _get_magnitude(clap_freq_min, 20000.0)

	# Track the slow-moving noise floor for each band. Steady noise raises the
	# baseline (suppressing false triggers); a sudden stomp/clap spikes above it.
	_stamp_baseline = lerp(_stamp_baseline, stamp_volume, baseline_adapt)
	_clap_baseline = lerp(_clap_baseline, clap_volume, baseline_adapt)

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
	_beat_epoch += 1

func _handle_clap_stomp(interaction_type: InteractionType) -> void:
	var track_index: int = CLAP_TRACK if interaction_type == InteractionType.CLAP else STOMP_TRACK
	var on_beat_epoch: int = _get_on_beat_target_epoch(interaction_type)
	if on_beat_epoch >= 0 and GameState.playing:
		# Epoch dedup: emit the on-beat signal at most once per beat.
		if interaction_type == InteractionType.CLAP and on_beat_epoch != _last_clap_registered_epoch:
			_last_clap_registered_epoch = on_beat_epoch
			EventBus.clap_on_beat_detected.emit()
		elif interaction_type == InteractionType.STOMP and on_beat_epoch != _last_stomp_registered_epoch:
			_last_stomp_registered_epoch = on_beat_epoch
			EventBus.stomp_on_beat_detected.emit()

	if GameState.clap_adds_beats and interaction_type == InteractionType.CLAP:
		EventBus.beat_set_requested.emit(track_index, GameState.current_beat, true)


func _get_on_beat_target_epoch(interaction_type: InteractionType) -> int:
	if not GameState.playing:
		return -1
	var progress: float = GameState.beat_progress
	var track_index: int = CLAP_TRACK if interaction_type == InteractionType.CLAP else STOMP_TRACK

	# Tutorial mode uses a wider window (0.5) so head + tail cover the full beat,
	# making button presses and microphone input much more forgiving for children.
	var window: float = 0.5 if GameState.tutorial_activated else beat_on_beat_window

	# Head window: beat just fired, check if current beat is set
	if progress < window:
		if SongState.current_section.get_beat(track_index, GameState.current_beat):
			return _beat_epoch
		return -1

	# Tail window: approaching next beat, check if next beat is set
	if progress > 1.0 - window:
		var next_beat: int = (GameState.current_beat + 1) % SongState.beats_per_section
		if SongState.current_section.get_beat(track_index, next_beat):
			return _beat_epoch + 1
		return -1

	# Outside both windows — not on beat
	return -1
