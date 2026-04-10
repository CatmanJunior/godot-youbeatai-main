class_name TrackWaveformVisualizer

extends Node

## Manages waveform visualization and progress bars for SYNTH tracks

@export var progress_bars: Array[TextureProgressBar]
@export var waveform_lines: Array[Line2D]
@export var track_settings: TrackUISettingsRegistry


const LINE_CONFIGS = [
	{"points": 100, "base_dist": 280, "volume_dist": 28, "reversed": false},  # Track 0 (4) – big line
	{"points": 40, "base_dist": 50, "volume_dist": 15, "reversed": false},    # Track 1 (5) – small line
]

var _sample_track_amount: int = AudioPlayerManager.SAMPLE_TRACKS_COUNT  # Number of sample tracks to offset synth track indices

func _ready() -> void:
	EventBus.section_added.connect(_on_section_added)
	EventBus.section_switched.connect(_on_section_switched)

func _on_section_switched(new_section_data: SectionData):
	for i in range(waveform_lines.size()):
		if waveform_lines[i]:
			if new_section_data.tracks[i+_sample_track_amount].synth_waveform_visualizer:
				waveform_lines[i].points = new_section_data.tracks[i+_sample_track_amount].synth_waveform_visualizer.offsets  # Update waveform points for new section
			

func _on_section_added(section_index: int, _emoji: String):
	for i in range(waveform_lines.size()):
		if waveform_lines[i]:
			var cfg = LINE_CONFIGS[i]
			var visualizer = SynthWaveform.new(waveform_lines[i], cfg.points, cfg.base_dist, cfg.volume_dist, cfg.reversed)
			var section_data = SongState.sections[section_index]
			section_data.tracks[i+_sample_track_amount].synth_waveform_visualizer = visualizer  # Link visualizer to track data

func update_progress_bar(rec_data: RecordingData, percentage: float) -> void:
	var track_index = rec_data.track_data.index
	track_index = track_index - _sample_track_amount  # Adjust index for progress bars (only for SYNTH tracks)
	if track_index >= 0 and track_index < progress_bars.size() and progress_bars[track_index]:
		progress_bars[track_index].value = percentage


func update_waveform(rec_data: RecordingData) -> void:
	var track_index = rec_data.track_data.index
	track_index = track_index - _sample_track_amount  # Adjust index for waveform visualizers (only for SYNTH tracks)
	if track_index >= 0 and track_index < waveform_lines.size() and waveform_lines[track_index]:
		if rec_data:
			SongState.sections[SongState.current_section_index].tracks[track_index + _sample_track_amount].synth_waveform_visualizer.update_line_from_recording(rec_data)
			print("Updated waveform for track ", track_index + _sample_track_amount)
			waveform_lines[track_index].self_modulate = track_settings.get_synth_track(track_index).track_color


func reset_progress_bar(rec_data: RecordingData) -> void:
	var track_index = rec_data.track_data.index
	track_index = track_index - _sample_track_amount									  # Adjust index for progress bars (only for SYNTH tracks)
	if track_index >= 0 and track_index < progress_bars.size() and progress_bars[track_index]:
		progress_bars[track_index].value = 0
