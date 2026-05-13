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
	MIX = 0,
	CHORD = 1,
	VOICE_OVER = 2,
}

var BUS_SUFFIXES: Array[String] = ["Mix", "Chord", "VoiceOver"]
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
	EventBus.section_switch_requested.connect(seek_to_position)


func _process(delta: float) -> void:
	if is_song_recording:
		recording_timer += delta

# ── Playback ─────────────────────────────────────────────────────────────────

func play(offset: float = 0.0) -> void:
	if track_data and track_data.recorded_audio_stream:
		_is_playing = true
		players[SongLayer.VOICE_OVER].play(offset)
		players[SongLayer.MIX].play(offset)

func stop() -> void:
	_is_playing = false
	for p in players:
		p.stop()

func _set_recorded_stream(recording_data: RecordingData) -> void:
	if recording_data.track_data.index != track_index:
		return
	track_data.recorded_audio_stream = recording_data.audio_stream

	players[SongLayer.VOICE_OVER].stream = recording_data.audio_stream
	players[SongLayer.MIX].stream = recording_data.audio_stream # alt version with effects
	_has_recording = true
	set_weights(_weights)

# ── TrackPlayerBase overrides ────────────────────────────────────────────────

func setup(index: int, parent_bus: String, _settings : ChordPlayerSettings = null) -> void:
	super.setup(index, parent_bus, _settings)
	chords = Chords.new()
	
	chords.set_settings(_settings, sub_bus_names[SongLayer.CHORD] )
	add_child(chords)


func _on_soundbank_loaded(bank: SoundBank) -> void:
	super._on_soundbank_loaded(bank)
	apply_effect_profile(bank.synth_effect_profiles[0])

func pre_on_beat(beat:int):
	if beat == 0:
		EventBus.section_next_requested.emit()

func _on_beat_triggered(_beat: int) -> void:
	if not GameState.song_mode_active:
		return

	if not players[SongLayer.VOICE_OVER].playing:
		play(_calculate_play_offset(SongState.current_section_index) )

func seek_to_position(section_index: int):
	if players[SongLayer.VOICE_OVER].playing:
		stop()
		play( _calculate_play_offset(section_index) )


func _calculate_play_offset(section_index: int) -> float:
	if section_index == 0:
		return 0

	var sections = SongState.sections.filter( func(e:SectionData): return e.index < section_index )
	var lengths = sections.map( func(e:SectionData): return e.loop_count * SongState.beats_per_section )
	var offset_in_beats = lengths.reduce( func(accum, e): return accum + e );
	return offset_in_beats * SongState.beat_duration + SongState.beat_duration * GameState.current_beat

## Song track is NOT per-section — ignore section switches for stream loading.
## (The voice_over lives on SongState.song_track, not on sections.)
func _on_section_switched(_new: SectionData) -> void:
	pass

func apply_effect_profile(effect_profile: EffectProfile) -> void:
	_set_bus_effect(AudioServer.get_bus_index(sub_bus_names[SongLayer.MIX]), effect_profile,sub_bus_names[SongLayer.MIX])
	_set_bus_effect(AudioServer.get_bus_index(sub_bus_names[SongLayer.CHORD]), effect_profile,sub_bus_names[SongLayer.CHORD])

func _set_bus_effect(bus_idx: int, effect_profile: EffectProfile, bus: String):
	if bus_idx == -1:
		push_error("Bus '%s' not found for applying effect profile." % bus)
		return
	effect_profile.apply_effects(bus_idx)

# ── Section add/remove handlers ──────────────────────────────────────────────

func _on_section_added(section_index: int, _tex: Texture2D) -> void:
	if track_data.has_recording():
		track_data.insert_silence_for_section(section_index, SongState.beats_per_section, SongState.beat_duration)


func _on_section_removed(section_index: int) -> void:
	if track_data.has_recording():
		track_data.remove_audio_for_section(section_index, SongState.beats_per_section, SongState.beat_duration)

# When another track is selected stop playback of the songtrack
func _on_track_selected(new_track_index: int) -> void:
	if new_track_index != track_index:
		stop()
