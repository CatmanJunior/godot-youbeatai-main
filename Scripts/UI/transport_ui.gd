extends Node

@export var play_pause_button: Button

@export var pointer: Sprite2D
@export var metronome: Sprite2D

@export var section_loop_toggle: CheckButton
@export var real_time_audio_recording_progress_bar: ProgressBar
@export var progress_bar: ProgressBar

# Private state
var _slow_beat_timer: float = 0.0
var progress_bar_value: float = 25.0


func _ready() -> void:
	play_pause_button.pressed.connect(_on_play_pause)

func update(delta: float) -> void:
	_update_play_pause_button()
	_update_pointer()
	_update_metronome(delta)

	_update_progress_bar()

func _update_play_pause_button() -> void:
	play_pause_button.text = "⏸️" if GameState.playing else "▶️"

func _update_pointer() -> void:
	if GameState.playing:
		pointer.rotation_degrees = GameState.bar_progress * 360.0 - 7.0

func _update_metronome(delta: float) -> void:
	if GameState.playing:
		_slow_beat_timer += delta / 4.0
		if _slow_beat_timer > GameState.time_per_beat:
			_slow_beat_timer -= GameState.time_per_beat
		var beat_progress = _slow_beat_timer / GameState.time_per_beat
		metronome.position.y = lerp(-0.4, 0.4, beat_progress)


func _update_progress_bar() -> void:
	progress_bar_value = clamp(progress_bar_value, 0.0, 100.0)
	progress_bar.value = progress_bar_value

func _on_play_pause() -> void:
	if not play_pause_button.disabled:
		EventBus.play_pause_toggled.emit()
