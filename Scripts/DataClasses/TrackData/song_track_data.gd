class_name SongTrackData
extends TrackData

## Data class for the global song-level track.
## Unlike SampleTrackData/SynthTrackData, this is NOT per-section — it spans
## the entire song (all sections played in sequence).
##
## Uses the base TrackData fields:
##   - recorded_audio_stream → the voice-over (mic input)
##   - knob_position, master_volume, weights 
##   - recording_data → runtime RecordingData for the voice-over
##
## Adds:
##   - master_recording_stream → the full master bus capture (SubMaster)

# ── Additional audio stream (the master bus recording) ───────────────────────

## The full master bus recording ("SubMaster" bus output).
## The base class `recorded_audio_stream` holds the voice-over (mic input).
@export var master_recording_stream: AudioStreamWAV = null

# ── Recording metadata ───────────────────────────────────────────────────────

## Duration of the last completed recording in seconds.
@export var recording_length: float = 0.0


# ── Init ─────────────────────────────────────────────────────────────────────

## Song track uses a fixed index. 
const SONG_TRACK_INDEX: int = 6

func _init(track_index: int = SONG_TRACK_INDEX, section_index: int = 0, knob_pos: Vector2 = Vector2.ZERO) -> void:
	super._init(track_index, section_index, knob_pos, TrackType.SONG)


# ── Helpers ──────────────────────────────────────────────────────────────────

## Returns the mixed voice_over + master stream (for export).
func get_mixed_stream() -> AudioStreamWAV:
	if recorded_audio_stream is AudioStreamWAV and master_recording_stream is AudioStreamWAV:
		return AudioSavingManager.mix_streams(
			master_recording_stream,
			recorded_audio_stream as AudioStreamWAV
		)
	elif master_recording_stream:
		return master_recording_stream
	elif recorded_audio_stream is AudioStreamWAV:
		return recorded_audio_stream as AudioStreamWAV
	return null


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
	master_recording_stream = null
	recording_data = null
	recording_length = 0.0


func duplicate_track() -> TrackData:
	var copy := SongTrackData.new(index, section_index, knob_position)
	copy.master_volume = master_volume
	copy.weights = weights
	copy.recorded_audio_stream = recorded_audio_stream
	copy.master_recording_stream = master_recording_stream
	copy.recording_data = recording_data
	copy.recording_length = recording_length
	return copy


# ── Section manipulation (insert/remove silence when sections change) ────────

func insert_silence_for_section(section_index: int, total_beats: int, beat_duration: float) -> void:
	var section_duration := total_beats * beat_duration
	var insert_time := section_index * section_duration

	if recorded_audio_stream is AudioStreamWAV:
		recorded_audio_stream = AudioSavingManager.insert_silence(
			recorded_audio_stream as AudioStreamWAV, insert_time, section_duration)
	if master_recording_stream:
		master_recording_stream = AudioSavingManager.insert_silence(
			master_recording_stream, insert_time, section_duration)
	_update_length()


func remove_audio_for_section(section_index: int, total_beats: int, beat_duration: float) -> void:
	var section_duration := total_beats * beat_duration
	var start_time := section_index * section_duration
	var end_time := start_time + section_duration

	if recorded_audio_stream is AudioStreamWAV:
		recorded_audio_stream = AudioSavingManager.remove_segment(
			recorded_audio_stream as AudioStreamWAV, start_time, end_time)
	if master_recording_stream:
		master_recording_stream = AudioSavingManager.remove_segment(
			master_recording_stream, start_time, end_time)
	_update_length()


## Get the section of the mixed audio for beat-level export.
func get_section_slice(section_index: int, total_beats: int, beat_duration: float) -> AudioStreamWAV:
	var section_duration := total_beats * beat_duration
	var start_time := section_index * section_duration
	var end_time := start_time + section_duration
	var mixed := get_mixed_stream()
	if mixed:
		return AudioSavingManager.trim_stream(mixed, start_time, end_time)
	return null


func _update_length() -> void:
	if recorded_audio_stream is AudioStreamWAV:
		recording_length = (recorded_audio_stream as AudioStreamWAV).get_length()
	elif master_recording_stream:
		recording_length = master_recording_stream.get_length()
	else:
		recording_length = 0.0