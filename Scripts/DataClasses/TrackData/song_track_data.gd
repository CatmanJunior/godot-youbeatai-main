class_name SongTrackData
extends TrackData

## Data class for the global song-level track.
## Unlike SampleTrackData/SynthTrackData, this is NOT per-section — it spans
## the entire song (all sections played in sequence).

## Song track uses a fixed index. 
const SONG_TRACK_INDEX: int = 6

func _init(p_track_index: int = SONG_TRACK_INDEX, p_section_index: int = 0, knob_pos: Vector2 = TrackData.KNOB_POSITION_UNSET) -> void:
	super._init(p_track_index, p_section_index, knob_pos, TrackType.SONG)


# ── Helpers ──────────────────────────────────────────────────────────────────

## Called after loading from disk to rebuild runtime RecordingData.
func rebuild_runtime() -> void:
	if recorded_audio_stream is AudioStreamWAV:
		recording_data = RecordingData.new(self, recorded_audio_stream as AudioStreamWAV)
		recording_data.state = RecordingData.State.RECORDING_DONE
	else:
		recording_data = null

## Clear both recordings.
func clear() -> void:
	recorded_audio_stream = null
	recording_data = null

func duplicate_track() -> TrackData:
	var copy := SongTrackData.new(index, section_index, knob_position)
	copy.master_volume = master_volume
	copy.weights = weights
	if recorded_audio_stream:
		copy.recorded_audio_stream = recorded_audio_stream
	if recording_data:
		copy.recording_data = recording_data.duplicate()
	return copy