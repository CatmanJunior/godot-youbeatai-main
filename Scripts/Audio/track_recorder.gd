extends Node

## Thin coordinator between the record button UI and the track players.
## Notices button presses and tells the appropriate track player to start/stop
## recording via EventBus. Listens for progress and waveform updates.

@export var recording_sample_button: RecordSampleButton
@export var waveform_visualizer: TrackWaveformVisualizer

func _ready() -> void:
	EventBus.recording_sample_button_toggled.connect(_on_recording_sample_button_toggled)
	EventBus.recording_progress_updated.connect(_on_recording_progress_updated)
	EventBus.synth_sequence_ready.connect(_on_synth_sequence_ready)

# ── Event Handlers ───────────────────────────────────────────────────────────

func _on_recording_sample_button_toggled(toggled: bool) -> void:
	var track_index: int = SongState.selected_track_index
	if toggled:
		EventBus.track_recording_start_requested.emit(track_index)
	else:
		EventBus.track_recording_stop_requested.emit(track_index)

func _on_recording_progress_updated(track_index: int, percentage: float, recording_data: RecordingData) -> void:
	recording_sample_button.update_button(percentage)
	# Update waveform progress for synth tracks
	if recording_data and recording_data.track_data and recording_data.track_data.track_type == TrackData.TrackType.SYNTH:
		waveform_visualizer.update_progress(track_index, percentage)

func _on_synth_sequence_ready(track_index: int, recording_data: RecordingData) -> void:
	# Update waveform visualization when synth voice processing is complete
	if recording_data:
		waveform_visualizer.update_waveform(track_index, recording_data)
		waveform_visualizer.reset_progress(track_index)
