class_name SynthTrackPlayer
extends TrackPlayerBase

var thread: Thread = null

enum SynthLayer {
	ALT = 0,
	NOTE = 1,
	REC = 2
}

var SAMPLE_TRACK_COUNT = 4 # number of sample tracks before synth tracks, used to index into audio bank settings

var note_player: NotePlayer:
	get:
		return players[SynthLayer.NOTE] as NotePlayer

var BUS_SUFFIXES: Array[String] = ["Alt", "NotePlayer", "Recording"]

var BUS_PREFIX: String = "Synth"

## Whether we are waiting for beat 0 (countdown) before starting the mic.
var _waiting_for_countdown: bool = false

func _get_bus_suffixes() -> Array[String]:
	return BUS_SUFFIXES

func _get_bus_prefix() -> String:
	return BUS_PREFIX

func _ready() -> void:
	super._ready()

func _process(delta: float) -> void:
	if not _is_recording or _waiting_for_countdown:
		return
	_recording_time += delta
	var total_duration: float = SongState.total_beats * GameState.beat_duration
	var percentage: float = _recording_time / total_duration
	EventBus.recording_progress_updated.emit(track_index, percentage)
	if percentage >= 1.0:
		_end_recording()

# --- Public API ---
func apply_note_player_settings(new_settings: NotePlayerSettings) -> void:
	print(new_settings.soundfont)
	note_player.apply_settings(new_settings)

func setup(index: int, parent_bus: String, settings: NotePlayerSettings = null) -> void:
	super.setup(index, parent_bus, settings)
	if settings:
		apply_note_player_settings(settings)
	else:
		print("Warning: No note player settings provided for SynthTrackPlayer %d, using defaults." % index)

func _set_recorded_stream(stream: AudioStream) -> void:
	for i in [SynthLayer.ALT, SynthLayer.REC]: # update all non-note player layers with the new recording
		players[i].stream = stream # all layers share the same recording
	_has_recording = true
	set_weights(_weights) # reapply weights now that streams are loaded

	# Store RecordingData on the track data and mark as PROCESSING before
	# set_recording_audio_stream so the PROCESSING state is preserved.
	if track_data.recording_data:
		track_data.recording_data.state = RecordingData.State.PROCESSING
	track_data.set_recording_audio_stream(stream)

	thread = Thread.new()
	thread.start(_process_voice_threaded.bind(stream, thread))


func _on_audio_bank_loaded(bank: AudioBank) -> void:
	var effect_profile = bank.synth_effect_profiles[track_index - SAMPLE_TRACK_COUNT]
	if effect_profile:
		apply_effect_profile(effect_profile) # apply the synth's specific effect profile from the bank
	apply_note_player_settings(bank.noteplayer_settings[track_index - SAMPLE_TRACK_COUNT])

func _on_section_switched(_new) -> void:
	# Clear stale scheduled notes when switching sections
	if note_player:
		note_player.note_off_all(0)
	
	# Reload the new section's recorded stream into the audio players
	
	if track_data.recorded_audio_stream:
		for i in [SynthLayer.ALT, SynthLayer.REC]:
			players[i].stream = track_data.recorded_audio_stream
		_has_recording = true
		set_weights(_weights)
	else:
		# No recording in this section — clear streams and flag
		for i in [SynthLayer.ALT, SynthLayer.REC]:
			players[i].stream = null
		_has_recording = false

func _on_beat_triggered(beat: int) -> void:
	# Handle countdown → start recording at beat 0
	if _waiting_for_countdown and beat == 0:
		_waiting_for_countdown = false
		EventBus.countdown_close_requested.emit()
		EventBus.mute_all_requested.emit(true)
		EventBus.start_recording_requested.emit()
		return

	# Normal playback (skip during active recording)
	if _is_recording:
		return
	if not _has_recording:
		return
	if note_player:
		play_note(beat)
	if beat == 0:
		for i in [SynthLayer.ALT, SynthLayer.REC]:
			players[i].stop()
			players[i].play() # retrigger recording layer on the downbeat to keep it in sync

func _on_all_players_stop():
	stop()


## Playback control
func play(offset: float = 0.0) -> void:
	if not _has_recording:
		return
	for i in [SynthLayer.ALT, SynthLayer.REC]:
		players[i].play(offset) # same frame → phase-locked across all effect layers

func play_note(beat: int) -> void:
	var data: SynthTrackData = track_data
	if data == null or data._sequence == null:
		return
	var note: SequenceNote = data._sequence.get_note_at_beat(beat)
	if note and note_player:
		note_player.play_note(note)

func stop() -> void:
	for i in [SynthLayer.ALT, SynthLayer.REC]: # stop all non-note player layers
		players[i].stop()
	# Also stop all currently playing notes immediately
	if note_player:
		note_player.note_off_all(0)

# ── Recording ────────────────────────────────────────────────────────────────

func _begin_recording() -> void:
	_is_recording = true
	_waiting_for_countdown = true
	_has_detected_sound = false
	_recording_time = 0.0
	# Create recording data on the track
	track_data.create_recording_data(SongState.current_section_index)
	track_data.recording_data.state = RecordingData.State.RECORDING
	# Show countdown — mic starts when beat 0 is reached (see _on_beat_triggered)
	EventBus.countdown_show_requested.emit()

func _end_recording() -> void:
	if not _is_recording:
		return
	# If still waiting for countdown, cancel without starting mic
	if _waiting_for_countdown:
		_waiting_for_countdown = false
		_is_recording = false
		_recording_time = 0.0
		EventBus.countdown_close_requested.emit()
		if track_data and track_data.recording_data:
			track_data.recording_data.state = RecordingData.State.NOT_STARTED
		return
	# Normal stop — mic is running, stop it and unmute
	super._end_recording()

func _on_mic_recording_stopped(audio: AudioStream) -> void:
	if not _is_recording:
		return
	_is_recording = false
	_recording_time = 0.0

	if audio == null:
		if track_data and track_data.recording_data:
			track_data.recording_data.state = RecordingData.State.NOT_STARTED
		return

	# Mark as PROCESSING before storing audio (voice analysis pending)
	track_data.recording_data.state = RecordingData.State.PROCESSING
	track_data.set_recording_audio_stream(audio)

	# Update player streams
	for i in [SynthLayer.ALT, SynthLayer.REC]:
		players[i].stream = audio
	_has_recording = true
	set_weights(_weights)

	# Start threaded voice processing
	thread = Thread.new()
	thread.start(_process_voice_threaded.bind(audio, thread))

# -- Voice Processing ---
func _process_voice_threaded(stream: AudioStream, _thread: Thread) -> void:
	var sequence: Sequence = VoiceProcessor.process_audio(stream, GameState.notes)
	# Marshal back to main thread
	call_deferred("_on_voice_processed", sequence, _thread)

func _on_voice_processed(sequence: Sequence, _thread: Thread) -> void:
	_thread.wait_to_finish()
	var data: SynthTrackData = track_data
	if sequence and data:
		data.set_sequence(sequence)
		# Voice processing complete — mark as done
		if data.recording_data:
			data.recording_data.state = RecordingData.State.RECORDING_DONE

	EventBus.synth_sequence_ready.emit(track_index)

## Override to create NotePlayer for the NOTE layer
func _make_player(bus: String) -> AudioStreamPlayer:
	var new_player: AudioStreamPlayer
	if bus.contains(BUS_SUFFIXES[SynthLayer.NOTE]):
		new_player = NotePlayer.new()
	else:
		new_player = AudioStreamPlayer.new()
	new_player.name = bus
	new_player.bus = bus
	add_child(new_player)

	return new_player
