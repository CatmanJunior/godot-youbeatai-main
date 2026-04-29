class_name SynthTrackPlayer
extends TrackPlayerBase


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

func _get_bus_suffixes() -> Array[String]:
	return BUS_SUFFIXES

func _get_bus_prefix() -> String:
	return BUS_PREFIX

func _ready() -> void:
	super._ready()
	EventBus.sequence_ready.connect(_on_sequence_ready)

# --- Public API ---
func apply_note_player_settings(new_settings: NotePlayerSettings) -> void:
	note_player.apply_settings(new_settings)

func setup(index: int, parent_bus: String, settings: NotePlayerSettings = null) -> void:
	super.setup(index, parent_bus, settings)
	if settings:
		apply_note_player_settings(settings)
	else:
		push_warning("Warning: No note player settings provided for SynthTrackPlayer %d, using defaults." % index)

func _set_recorded_stream(recording_data: RecordingData) -> void:
	if recording_data.track_data.index != track_index:
		return
	if recording_data.section_index != track_data.section_index:
		return

	for i in [SynthLayer.ALT, SynthLayer.REC]: # update all non-note player layers with the new recording
		players[i].stream = recording_data.audio_stream # all layers share the same recording
	_has_recording = true
	set_weights(_weights) # reapply weights now that streams are loaded

	track_data.set_recording_audio_stream(recording_data)


func _on_soundbank_loaded(bank: SoundBank) -> void:
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
	if data == null or data.sequence == null:
		return
	var note: SequenceNote = data.sequence.get_note_at_beat(beat)
	if note and note_player:
		note_player.play_note(note)

func stop() -> void:
	for i in [SynthLayer.ALT, SynthLayer.REC]: # stop all non-note player layers
		players[i].stop()
	# Also stop all currently playing notes immediately
	if note_player:
		note_player.note_off_all(0)
		
# -- Voice Processing ---
func _on_sequence_ready(sequence: Sequence, p_track_data: TrackData) -> void:
	if p_track_data.index != track_index:
		return
	if p_track_data.section_index != track_data.section_index:
		return
	var data: SynthTrackData = track_data
	if sequence and data:
		data.set_sequence(sequence)
		if data.recording_data:
			data.recording_data.state = RecordingData.State.RECORDING_DONE

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
