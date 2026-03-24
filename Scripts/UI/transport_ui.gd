extends Node
class_name TransportUI

@export var metronome: Sprite2D
@export var section_loop_toggle: CheckButton
@export var real_time_audio_recording_progress_bar: ProgressBar
@export var progress_bar: ProgressBar

# Private state
var _slow_beat_timer: float = 0.0
var progress_bar_value: float = 25.0




func _process(delta: float) -> void:

	# _update_metronome(delta)

	# _update_progress_bar()

	pass


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
