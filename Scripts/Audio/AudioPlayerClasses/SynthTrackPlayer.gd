class_name SynthTrackPlayer
extends TrackPlayerBase

var note_player: NotePlayer
var note_player_settings: NotePlayerSettings
var BUS_SUFFIXES : Array[String] = ["Alt" , "NotePlayer", "Recording"]

var BUS_PREFIX : String = "Synth"

func _get_bus_suffixes() -> Array[String]:
	return BUS_SUFFIXES

func _get_bus_prefix() -> String:
	return BUS_PREFIX

func _get_synth_data() -> SynthTrackData:
	var track : SynthTrackData = GameState.current_section.tracks[track_index] as SynthTrackData
	return track

func _ready() -> void:
	super._ready()
	EventBus.note_player_settings_changed.connect(_on_note_player_settings_changed)
	
func _on_note_player_settings_changed(new_settings: NotePlayerSettings, track_id: int) -> void:
	if track_id != self.track_index:
		return
	note_player_settings = new_settings
	note_player.apply_settings(note_player_settings)

func _on_section_switched(_old, _new) -> void:
	# Clear stale scheduled notes when switching sections
	if note_player:
		note_player.note_off_all(0)
	
	# Reload the new section's recorded stream into the audio players
	var data : SynthTrackData = _get_synth_data()
	if data and data.recorded_audio_stream:
		for i in [0, 2]:
			players[i].stream = data.recorded_audio_stream
		_has_recording = true
		set_weights(_weights)
	else:
		# No recording in this section — clear streams and flag
		for i in [0, 2]:
			players[i].stream = null
		_has_recording = false

func _on_beat_triggered(beat: int) -> void:
	if not _has_recording:
		return
	if note_player:
		play_note(beat)
	if beat == 0: 
		players[0].play()

func setup(index: int, parent_bus: String, settings : NotePlayerSettings = null) -> void:
	if settings:
		note_player_settings = settings
	else:
		print("Warning: No note player settings provided for SynthTrackPlayer %d, using defaults." % index)
	#call the base class setup to create buses and players
	super.setup(index, parent_bus, settings)



# --- Public API ---

func set_recorded_stream(stream: AudioStream) -> void:
	for i in [0,2]: # update all non-note player layers with the new recording
		players[i].stream = stream # all layers share the same recording
	_has_recording = true
	set_weights(_weights) # reapply weights now that streams are loaded

	# Store RecordingData on the track data and mark as PROCESSING before
	# set_recording_audio_stream so the PROCESSING state is preserved.
	var data := _get_synth_data()
	if data:
		if data.recording_data:
			data.recording_data.state = RecordingData.State.PROCESSING
		data.set_recording_audio_stream(stream)

	var thread := Thread.new()
	thread.start(_process_voice_threaded.bind(stream, thread))

## Playback control
func play(offset: float = 0.0) -> void:
	if not _has_recording:
		return
	for i in [0,2]:
		players[i].play(offset) # same frame → phase-locked across all effect layers

func play_note(beat: int) -> void:
	var data: SynthTrackData = _get_synth_data()
	if data == null or data.sequence == null:
		return
	var note: SequenceNote = data.sequence.get_note_at_beat(beat)
	if note and note_player:
		note_player.play_note(note)

func stop() -> void:
	for p in [players[0], players[2]]: # stop all non-note player layers
		p.stop()
	# Also stop all currently playing notes immediately
	if note_player:
		note_player.note_off_all(note_player.get_time())

# -- Voice Processing ---
func _process_voice_threaded(stream: AudioStream, thread: Thread) -> void:
	var sequence: Sequence = VoiceProcessor.process_audio(stream, GameState.notes)
	# Marshal back to main thread
	call_deferred("_on_voice_processed", sequence, thread)

func _on_voice_processed(sequence: Sequence, thread: Thread) -> void:
	thread.wait_to_finish()
	var data: SynthTrackData = _get_synth_data()
	if sequence and data:
		data.sequence = sequence
		# Voice processing complete — mark as done
		if data.recording_data:
			data.recording_data.state = RecordingData.State.RECORDING_DONE

	EventBus.synth_sequence_ready.emit(track_index)

##Overrides the base method to also update the note player stream
func _setup_players() -> void:
	players.append(_make_player(sub_bus_names[0]))

	var new_note_player := NotePlayer.new()
	new_note_player.bus = sub_bus_names[1]
	new_note_player.name = BUS_PREFIX + str(track_index) + "NotePlayer"
	add_child(new_note_player)
	note_player = new_note_player
	note_player.apply_settings(note_player_settings)
	
	players.append(note_player) # add the note player as the last player for weights

	players.append(_make_player(sub_bus_names[2]))
	

func update_note_player_settings(new_settings: NotePlayerSettings) -> void:
	note_player_settings = new_settings
	note_player.apply_settings(note_player_settings)