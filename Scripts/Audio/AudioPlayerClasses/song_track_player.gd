class_name SongTrackPlayer
extends TrackPlayerBase

## Audio player for the song-level track (extends TrackPlayerBase).
##
## Key difference from SampleTrackPlayer/SynthTrackPlayer:
##   - track_data getter reads from GameState.song_track (NOT current_section.tracks[])
##   - Records from BOTH the Microphone bus (voice-over) AND SubMaster bus (full mix)
##   - Plays back the voice-over recording during song mode
##   - Not driven by beat_triggered (continuous playback, not per-beat)
##
## Bus layout (3 sub-buses via TrackPlayerBase):
##   SongTrack6_VoiceOver  → plays the voice-over recording
##   SongTrack6_Master     → plays the master bus recording (for preview/export)
##   SongTrack6_Mix        → reserved for real-time mixed output

enum SongLayer {
	VOICE_OVER = 0,
	MASTER = 1,
	MIX = 2
}

var BUS_SUFFIXES: Array[String] = ["VoiceOver", "Master", "Mix"]
var BUS_PREFIX: String = "Song"

## AudioEffectRecord on the Microphone bus (captures voice-over).
var voice_record_effect: AudioEffectRecord

## AudioEffectRecord on the SubMaster bus (captures master output).
var master_record_effect: AudioEffectRecord

## Recording timer (for progress calculation).
var recording_timer: float = 0.0

## Whether we're in song-recording mode.
var is_song_recording: bool = false


# ── TrackPlayerBase overrides ────────────────────────────────────────────────

func _get_bus_suffixes() -> Array[String]:
	return BUS_SUFFIXES

func _get_bus_prefix() -> String:
	return BUS_PREFIX



func _ready() -> void:
	super._ready()
	_setup_record_effects()

	# Song-specific signals
	# EventBus.song_recording_start_requested.connect(_on_song_recording_start)
	# EventBus.song_recording_stop_requested.connect(_on_song_recording_stop)
	EventBus.section_added.connect(_on_section_added)
	EventBus.section_removed.connect(_on_section_removed)


func _process(delta: float) -> void:
	if is_song_recording:
		recording_timer += delta


# ── Record effect setup ──────────────────────────────────────────────────────

func _setup_record_effects() -> void:
	# Voice-over record effect (Microphone bus, effect index 1)
	var mic_bus := AudioServer.get_bus_index("Microphone")
	if mic_bus >= 0 and AudioServer.get_bus_effect_count(mic_bus) > 1:
		voice_record_effect = AudioServer.get_bus_effect(mic_bus, 1)

	# Master bus record effect (SubMaster bus, effect index 0)
	var master_bus := AudioServer.get_bus_index("SubMaster")
	if master_bus >= 0 and AudioServer.get_bus_effect_count(master_bus) > 0:
		master_record_effect = AudioServer.get_bus_effect(master_bus, 0)


# ── Playback ─────────────────────────────────────────────────────────────────

func play(offset: float = 0.0) -> void:
	var data := track_data as SongTrackData
	if data and data.recorded_audio_stream:
		players[SongLayer.VOICE_OVER].stream = data.recorded_audio_stream
		players[SongLayer.VOICE_OVER].play(offset)


func stop() -> void:
	for p in players:
		p.stop()


func _set_recorded_stream(rec: AudioStream) -> void:
	players[SongLayer.VOICE_OVER].stream = rec
	_has_recording = rec != null
	set_weights(_weights)


# ── Song Recording ───────────────────────────────────────────────────────────

func start_song_recording() -> void:
	if is_song_recording:
		return

	is_song_recording = true
	recording_timer = 0.0

	var data := track_data as SongTrackData
	if data:
		data.start_recording(-1)  # section -1 = song-level

	# Start both record effects
	if voice_record_effect:
		voice_record_effect.set_recording_active(true)
	if master_record_effect:
		master_record_effect.set_recording_active(true)

	# Reduce master volume so mic picks up voice, not feedback
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SubMaster"), linear_to_db(0.1))

	EventBus.buttons_disabled_requested.emit(true)
	EventBus.recording_started.emit()


func stop_song_recording() -> void:
	if not is_song_recording:
		return

	is_song_recording = false

	var data := track_data as SongTrackData
	if not data:
		return

	# Stop voice record effect and capture
	if voice_record_effect:
		voice_record_effect.set_recording_active(false)
		var voice_wav := voice_record_effect.get_recording()
		data.set_recording_audio_stream(voice_wav)  # uses base TrackData method

	# Stop master record effect and capture
	if master_record_effect:
		master_record_effect.set_recording_active(false)
		data.master_recording_stream = master_record_effect.get_recording()

	# Update metadata
	data.recording_length = recording_timer

	# Restore master volume
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SubMaster"), 0.0)

	# Load voice stream into player for immediate playback
	if data.recorded_audio_stream:
		players[SongLayer.VOICE_OVER].stream = data.recorded_audio_stream
		_has_recording = true
		set_weights(_weights)

	EventBus.buttons_disabled_requested.emit(false)
	EventBus.recording_stopped.emit(data.recorded_audio_stream)


## Get recording progress (0.0 – 1.0) based on total song duration.
func get_recording_progress() -> float:
	if not is_song_recording:
		return 0.0
	var sections_count := GameState.sections.size()
	var total_time := sections_count * GameState.total_beats * GameState.beat_duration
	if total_time <= 0.0:
		return 0.0
	return clampf(recording_timer / total_time, 0.0, 1.0)


# ── TrackPlayerBase overrides ────────────────────────────────────────────────

## Song track is not beat-driven — do nothing on beat_triggered.
func _on_beat_triggered(_beat: int) -> void:
	pass


## Song track is NOT per-section — ignore section switches for stream loading.
## (The voice_over lives on GameState.song_track, not on sections.)
func _on_section_switched(_new) -> void:
	pass


# ── Section add/remove handlers ──────────────────────────────────────────────

func _on_section_added(section_index: int, _emoji: String) -> void:
	var data := track_data as SongTrackData
	if data and data.has_recording():
		data.insert_silence_for_section(section_index, GameState.total_beats, GameState.beat_duration)


func _on_section_removed(section_index: int) -> void:
	var data := track_data as SongTrackData
	if data and data.has_recording():
		data.remove_audio_for_section(section_index, GameState.total_beats, GameState.beat_duration)