class_name SongTrackPlayer
extends TrackPlayerBase

## Audio player for the song-level track (extends TrackPlayerBase).
##
## Key difference from SampleTrackPlayer/SynthTrackPlayer:
##   - track_data getter reads from SongState.song_track (NOT current_section.tracks[])
##   - Records from BOTH the Microphone bus (voice-over) AND SubMaster bus (full mix)
##   - Plays back the voice-over recording during song mode
##   - Not driven by beat_triggered (continuous playback, not per-beat)
##
## Bus layout (3 sub-buses via TrackPlayerBase):
##   SongTrack6_VoiceOver  → plays the voice-over recording
##   SongTrack6_Chord      → plays the chord progression
##   SongTrack6_Mix        → reserved for real-time mixed output

enum SongLayer {
	VOICE_OVER = 0,
	CHORD = 1,
	MIX = 2
}

var BUS_SUFFIXES: Array[String] = ["VoiceOver", "Chord", "Mix"]
var BUS_PREFIX: String = "Song"

## Recording timer (for progress calculation).
var recording_timer: float = 0.0

## Whether we're in song-recording mode.
var is_song_recording: bool = false

var _is_playing: bool = false

#Chord Noteplayer object
var chords: Chords

# ── TrackPlayerBase overrides ────────────────────────────────────────────────

func _get_bus_suffixes() -> Array[String]:
	return BUS_SUFFIXES

func _get_bus_prefix() -> String:
	return BUS_PREFIX

func _ready() -> void:
	super._ready()

	# Song-specific signals
	EventBus.track_selected.connect(_on_track_selected)
	EventBus.section_added.connect(_on_section_added)
	EventBus.section_removed.connect(_on_section_removed)
	EventBus.pre_beat_triggered.connect(pre_on_beat)


func _process(delta: float) -> void:
	if is_song_recording:
		recording_timer += delta

# ── Playback ─────────────────────────────────────────────────────────────────

func play(offset: float = 0.0) -> void:
	if track_data and track_data.recorded_audio_stream:
		_is_playing = true
		players[SongLayer.VOICE_OVER].play(offset)

func stop() -> void:
	_is_playing = false
	for p in players:
		p.stop()

func _set_recorded_stream(recording_data: RecordingData) -> void:
	if recording_data.track_data.index != track_index:
		return
	track_data.recorded_audio_stream = recording_data.audio_stream
	players[SongLayer.VOICE_OVER].stream = recording_data.audio_stream
	_has_recording = true
	set_weights(_weights)

# ── TrackPlayerBase overrides ────────────────────────────────────────────────

func setup(index: int, parent_bus: String, _settings = null) -> void:
	super.setup(index, parent_bus, _settings)
	chords = Chords.new()
	
	chords.set_settings(_settings, sub_bus_names[1] )
	add_child(chords)

func pre_on_beat(beat:int):
	if beat == 0:
		EventBus.section_next_requested.emit()

func _on_beat_triggered(_beat: int) -> void:
	if SongState.selected_track_index != track_index:
		return

	if _beat != 1:
		return

	if SongState.current_section_index == 0 and not _is_playing:
		play()
		return

## Song track is NOT per-section — ignore section switches for stream loading.
## (The voice_over lives on SongState.song_track, not on sections.)
func _on_section_switched(_new) -> void:
	pass


# ── Section add/remove handlers ──────────────────────────────────────────────

func _on_section_added(section_index: int, _tex: Texture2D) -> void:
	if track_data.has_recording():
		track_data.insert_silence_for_section(section_index, SongState.total_beats, GameState.beat_duration)


func _on_section_removed(section_index: int) -> void:
	if track_data.has_recording():
		track_data.remove_audio_for_section(section_index, SongState.total_beats, GameState.beat_duration)

# When another track is selected stop playback of the songtrack
func _on_track_selected(new_track_index: int) -> void:
	if new_track_index != track_index:
		stop()