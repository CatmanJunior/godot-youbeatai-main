class_name SynthTrackPlayer
extends TrackPlayerBase

var note_player: notePlayer

var BUS_SUFFIXES : Array[String] = ["Dry", "Alt1", "Alt2"]

var BUS_PREFIX : String = "Track"

func _get_bus_suffixes() -> Array[String]:
	return BUS_SUFFIXES

func _get_bus_prefix() -> String:
	return BUS_PREFIX

func _get_synth_data() -> SynthTrackData:
	var track : SynthTrackData = GameState.current_section.tracks[track_index] as SynthTrackData
	return track

# --- Public API ---

func set_recorded_stream(stream: AudioStream) -> void:
	for p in players:
		p.stream = stream # all layers share the same recording
	_has_recording = true
	set_weights(_weights) # reapply weights now that streams are loaded

	# Process voice recording into note sequence and store in data
	var sequence : Sequence = VoiceProcessor.process_audio(stream, GameState.notes)
	var data : SynthTrackData = _get_synth_data()
	if sequence and data:
		data.sequence = sequence
		if note_player:
			note_player.queue_song(GameState.current_beat, sequence)

## Playback control
func play(offset: float = 0.0) -> void:
	if not _has_recording:
		return
	for p in players:
		p.play(offset) # same frame → phase-locked across all effect layers

func play_note() -> void:
	var data : SynthTrackData = _get_synth_data()
	var current_sequence_note : SequenceNote = data.sequence.sequence[GameState.current_beat]
	if current_sequence_note:
		note_player.play_note(current_sequence_note)

	