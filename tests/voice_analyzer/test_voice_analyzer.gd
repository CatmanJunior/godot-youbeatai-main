extends SceneTree

## Headless smoke test for VoiceAnalyzer.
##
## Feeds synthetic sine waves at known pitches into the streaming analyzer
## and asserts the resulting Sequence contains notes whose project note IDs
## match the expected pitch (within one semitone, to account for parabolic
## interpolation rounding).
##
## Run with:
##   godot --headless --script res://tests/voice_analyzer/test_voice_analyzer.gd
##
## Exits with non-zero status on failure.

const SAMPLE_RATE: float = 44100.0
const BEATS_PER_SECTION: int = 4
const BEAT_DURATION: float = 0.5  # seconds → 2 s total clip
const AMPLITUDE: float = 0.5
const CHUNK_FRAMES: int = 512  # roughly one mic _process burst

# Test cases: { freq_hz: expected MIDI note }.
# Project note ID = clampi(MIDI - 24, 36, 83).
const CASES: Array = [
	{"freq": 220.0, "midi": 57, "label": "A3"},
	{"freq": 440.0, "midi": 69, "label": "A4"},
	{"freq": 880.0, "midi": 81, "label": "A5"},
]

var _failures: int = 0

func _init() -> void:
	for case in CASES:
		_run_case(case["freq"], case["midi"], case["label"])
	if _failures > 0:
		printerr("VoiceAnalyzer tests: %d FAILURE(S)" % _failures)
		quit(1)
	else:
		print("VoiceAnalyzer tests: all passed")
		quit(0)

func _run_case(freq: float, expected_midi: int, label: String) -> void:
	var analyzer := VoiceAnalyzer.new()
	analyzer.start(SAMPLE_RATE, BEATS_PER_SECTION, BEAT_DURATION)

	var total_seconds: float = float(BEATS_PER_SECTION) * BEAT_DURATION
	var total_frames: int = int(SAMPLE_RATE * total_seconds)
	var phase: float = 0.0
	var phase_inc: float = TAU * freq / SAMPLE_RATE

	var fed: int = 0
	while fed < total_frames:
		var n: int = mini(CHUNK_FRAMES, total_frames - fed)
		var chunk := PackedFloat32Array()
		chunk.resize(n)
		for i in range(n):
			chunk[i] = sin(phase) * AMPLITUDE
			phase += phase_inc
		analyzer.push_samples(chunk)
		fed += n

	var sequence: Sequence = analyzer.finalize()

	if sequence == null or sequence.notes.is_empty():
		_failures += 1
		printerr("[%s @ %.1f Hz] no notes produced" % [label, freq])
		return

	# Expect: at least one note whose ID corresponds to the played pitch
	# (within ±1 semitone, since interpolation + median filtering can shift
	# by one MIDI step at boundaries).
	var expected_id: int = clampi(expected_midi - 24, 36, 83)
	var best_id: int = sequence.notes[0].note
	var ok := false
	for n in sequence.notes:
		if absi(n.note - expected_id) <= 1:
			best_id = n.note
			ok = true
			break

	if ok:
		print("[%s @ %.1f Hz] OK (expected note_id %d, got %d, %d note(s))"
			% [label, freq, expected_id, best_id, sequence.notes.size()])
	else:
		_failures += 1
		var got_ids: Array = []
		for n in sequence.notes:
			got_ids.append(n.note)
		printerr("[%s @ %.1f Hz] expected note_id %d ±1, got %s"
			% [label, freq, expected_id, str(got_ids)])
