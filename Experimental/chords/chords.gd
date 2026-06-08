extends NotePlayer
class_name Chords


var song_cursor = 0
var settings: ChordPlayerSettings

func _ready():
	super._ready()
	base_note = Note.new()
	gain = -2

	EventBus.beat_triggered.connect(on_beat)
	print("chord player ready")

func _exit_tree():
	EventBus.beat_triggered.disconnect(on_beat)

func set_settings(_settings: ChordPlayerSettings, _bus: StringName) -> void:
	settings = _settings

	# load soundbank
	var soundbank = SongState.selected_soundbank
	if soundbank == null:
		push_warning("Chords: No soundbank selected, using fallback bank '%s'." % settings.fallback_bank.resource_name)
		soundbank = settings.fallback_bank
	soundfont = soundbank.chord_progressions.soundFont
	instrument = soundbank.chord_progressions.instrument
	bus = _bus

func on_beat(beat: int):
	if not SongState.chords_active:
		return

	if beat % settings.chordDuration != 0:
		return

	var section: SectionData = SongState.current_section
	var length = len(section.progression.chords)
	var divider: int = length * settings.chordDuration / float(SongState.beats_per_section)

	@warning_ignore("integer_division")
	song_cursor = (beat / settings.chordDuration) % (length / divider)
	song_cursor += section.progression_offset.offset

	var chord: Chord = section.progression.chords[song_cursor % length]
	play_chord_object(chord, settings.chordDuration * SongState.beat_duration)

func play_chord_object(chord: Chord, duration: float):
	match chord.type:
		Chord.ChordType.MAJOR:
			on_chord_major(chord.base_note, duration)		
		Chord.ChordType.MINOR:
			on_chord_minor(chord.base_note, duration)
		Chord.ChordType.SEVEN:
			on_chord_7(chord.base_note, duration)
		Chord.ChordType.MAJOR7:
			on_chord_major_7(chord.base_note, duration)
		Chord.ChordType.MINOR7:
			on_chord_minor_7(chord.base_note, duration)


func play_chord(intervals, duration = 0.5) -> void:
	var t = get_time() -.005
	for i in range(intervals.size()):
		channel_note_on(t, 0, base_note.id + intervals[i], 0.5)
		channel_note_off(t + duration, 0, base_note.id + intervals[i])

func on_chord_major(offset = 0, duration=0.5) -> void:
	play_chord([0 + offset, 4 + offset, 7 + offset], duration)

func on_chord_minor(offset = 0, duration=0.5) -> void:
	play_chord([0 + offset, 3 + offset, 7 + offset], duration)

func on_chord_7(offset = 0, duration=0.5) -> void:
	play_chord([0 + offset, 4 + offset, 7 + offset, 10 + offset], duration)

func on_chord_major_7(offset = 0, duration=0.5) -> void:
	play_chord([0 + offset, 4 + offset, 7 + offset, 11 + offset], duration)

func on_chord_minor_7(offset = 0, duration=0.5) -> void:
	play_chord([0 + offset, 3 + offset, 7 + offset, 10 + offset], duration)

func on_chord_diminished_7(offset = 0, duration=0.5) -> void:
	play_chord([0 + offset, 3 + offset, 6 + offset, 9 + offset], duration)
