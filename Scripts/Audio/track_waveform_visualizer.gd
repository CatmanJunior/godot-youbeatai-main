class_name TrackWaveformVisualizer

extends Node

## Manages waveform visualization and progress bars for SYNTH tracks

@export var progress_bars: Array[TextureProgressBar]
@export var waveform_lines: Array[Line2D]

var waveform_visualizers: Array[SynthWaveformVisualizer]


func _ready() -> void:
	# Initialize waveform visualizers for each track
	for i in range(waveform_lines.size()):
		if waveform_lines[i]:
			waveform_visualizers.append(SynthWaveformVisualizer.new(null, waveform_lines[i]))
		else:
			waveform_visualizers.append(null)


func update_progress(track_index: int, percentage: float) -> void:
	track_index = track_index - 4  # Adjust index for progress bars (only for SYNTH tracks)
	if track_index >= 0 and track_index < progress_bars.size() and progress_bars[track_index]:
		progress_bars[track_index].value = percentage


func update_waveform(track_index: int, audio: AudioStream) -> void:
	track_index = track_index - 4  # Adjust index for waveform visualizers (only for SYNTH tracks)
	if track_index >= 0 and track_index < waveform_visualizers.size() and waveform_visualizers[track_index]:
		if audio:
			waveform_visualizers[track_index].update_lines(audio)


func reset_progress(track_index: int) -> void:
	track_index = track_index - 4  # Adjust index for progress bars (only for SYNTH tracks)
	if track_index >= 0 and track_index < progress_bars.size() and progress_bars[track_index]:
		progress_bars[track_index].value = 0
