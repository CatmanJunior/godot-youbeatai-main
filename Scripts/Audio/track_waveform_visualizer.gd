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
	EventBus.song_loaded.connect(_on_song_loaded)
	EventBus.synth_progress_bar_visible_requested.connect(_set_progress_bar_visible)
	for i in range(progress_bars.size()):
		var bar = progress_bars[i]
		if bar:
			bar.self_modulate = track_settings.get_synth_track(i).track_color

func _set_progress_bar_visible(bar: int, visible: bool) -> void:
	if bar >= 0 and bar < progress_bars.size() and progress_bars[bar]:
		progress_bars[bar].visible = visible

func _on_section_switched(new_section_data: SectionData):
	for i in range(waveform_lines.size()):
		if waveform_lines[i]:
			if new_section_data.tracks[i+_sample_track_amount].synth_waveform_visualizer:
				waveform_lines[i].points = new_section_data.tracks[i+_sample_track_amount].synth_waveform_visualizer.offsets  # Update waveform points for new section
			

func _on_song_loaded() -> void:
	# Rebuild SynthWaveform visualizer instances for every loaded section, and
	# pre-compute waveform offsets for sections that have a voice recording.
	for section in SongState.sections:
		for i in range(waveform_lines.size()):
			if not waveform_lines[i]:
				continue
			var cfg: Dictionary = LINE_CONFIGS[i]
			var visualizer := SynthWaveform.new(
				waveform_lines[i],
				cfg.points,
				cfg.base_dist,
				cfg.volume_dist,
				cfg.reversed
			)
			var track: TrackData = section.tracks[i + _sample_track_amount]
			track.synth_waveform_visualizer = visualizer
			if track.recorded_audio_stream is AudioStreamWAV:
				var wav := track.recorded_audio_stream as AudioStreamWAV
				var samples := VoiceProcessor.get_samples(wav)
				var rate := float(wav.mix_rate)
				var length := wav.get_length()
				visualizer.update_line(samples, rate, length)
			visualizer.set_color(track_settings.get_synth_track(i).track_color)


func _on_section_added(section_index: int, _tex: Texture2D):
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
		if rec_data == null or rec_data.audio_stream == null:
			return
		var samples := VoiceProcessor.get_samples(rec_data.audio_stream)
		var length := rec_data.audio_stream.get_length()
		var rate := float(rec_data.audio_stream.mix_rate)
		rec_data.track_data.synth_waveform_visualizer.update_line(samples, rate, length)
		waveform_lines[track_index].self_modulate = track_settings.get_synth_track(track_index).track_color


func reset_progress_bar(rec_data: RecordingData) -> void:
	var track_index = rec_data.track_data.index
	track_index = track_index - _sample_track_amount									  # Adjust index for progress bars (only for SYNTH tracks)
	if track_index >= 0 and track_index < progress_bars.size() and progress_bars[track_index]:
		progress_bars[track_index].value = 0
