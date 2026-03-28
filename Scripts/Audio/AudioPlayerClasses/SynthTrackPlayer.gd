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

func _ready() -> void:
	EventBus.beat_triggered.connect(_on_beat_triggered)
	EventBus.section_switched.connect(_on_section_switched)

func _on_section_switched(_old, _new) -> void:
	# Clear stale scheduled notes when switching sections
	if note_player:
		note_player.note_off_all(note_player.get_time())

func _on_beat_triggered(beat: int) -> void:
	if _has_recording and note_player:
		play_note(beat)

# --- Public API ---

func set_recorded_stream(stream: AudioStream) -> void:
	for p in players:
		p.stream = stream # all layers share the same recording
	_has_recording = true
	set_weights(_weights) # reapply weights now that streams are loaded

	var thread := Thread.new()
	thread.start(_process_voice_threaded.bind(stream, thread))

func _process_voice_threaded(stream: AudioStream, thread: Thread) -> void:
	var sequence: Sequence = VoiceProcessor.process_audio(stream, GameState.notes)
	# Marshal back to main thread
	call_deferred("_on_voice_processed", sequence, thread)

func _on_voice_processed(sequence: Sequence, thread: Thread) -> void:
	thread.wait_to_finish()
	var data: SynthTrackData = _get_synth_data()
	if sequence and data:
		data.sequence = sequence
	# Optionally emit a signal so UI can react
	EventBus.synth_sequence_ready.emit(track_index)


## Playback control
func play(offset: float = 0.0) -> void:
	if not _has_recording:
		return
	for p in players:
		p.play(offset) # same frame → phase-locked across all effect layers

func play_note(beat: int) -> void:
	var data: SynthTrackData = _get_synth_data()
	if data == null or data.sequence == null:
		return
	var note: SequenceNote = data.sequence.get_note_at_beat(beat)
	if note and note_player:
		note_player.play_note(note)

	