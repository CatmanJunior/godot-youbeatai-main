class_name TrackSettingsRegistry
extends Resource

## Central registry that holds visual settings for all tracks.
## Export this resource on any scene that needs track visuals
## (ChaosPadUI, TrackSelectButtonContainer, BeatRingUI, etc.)
## instead of maintaining parallel arrays of loose textures.
##
## Layout:
##   sample_tracks[0..3] → SampleTrackSettings  (rings 0–3)
##   synth_tracks[0..1]  → SynthTrackSettings   (synth tracks 0–1)
##   song_track          → SongTrackSettings    (song mixing mode)

@export_group("Sample Tracks (4)")
@export var sample_tracks: Array[SampleTrackSettings] = []

@export_group("Synth Tracks (2)")
@export var synth_tracks: Array[SynthTrackSettings] = []

@export_group("Song Mixing Mode")
@export var song_track: SongTrackSettings


# ── Convenience accessors ────────────────────────────────────────────────────

## Returns the SampleTrackSettings for [param track_index] (0–3), or null.
func get_sample_track(track_index: int) -> SampleTrackSettings:
	if track_index >= 0 and track_index < sample_tracks.size():
		return sample_tracks[track_index]
	push_warning("TrackSettingsRegistry: invalid sample track index %d" % track_index)
	return null


## Returns the SynthTrackSettings for [param synth_index] (0–1), or null.
func get_synth_track(synth_index: int) -> SynthTrackSettings:
	if synth_index >= 0 and synth_index < synth_tracks.size():
		return synth_tracks[synth_index]
	push_warning("TrackSettingsRegistry: invalid synth track index %d" % synth_index)
	return null


## Returns the base TrackSettingsBase for any absolute track index
## (0–3 → sample, 4–5 → synth). Returns song_track if index is -1.
func get_track(track_index: int) -> TrackSettingsBase:
	const SAMPLE_COUNT := 4
	if track_index == -1:
		return song_track
	if track_index < SAMPLE_COUNT:
		return get_sample_track(track_index)
	return get_synth_track(track_index - SAMPLE_COUNT)


## Returns chaos pad icons [main, alt] for any absolute track index,
## or song_track icons if called from song mixing mode.
func get_chaos_pad_icons(track_index: int) -> Array[Texture2D]:
	var settings := get_track(track_index)
	if settings == null:
		return [null, null]
	return [settings.chaos_pad_main_icon, settings.chaos_pad_alt_icon]