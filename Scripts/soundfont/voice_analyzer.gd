class_name VoiceAnalyzer
extends RefCounted

## Incremental, single-threaded voice-to-notes analyzer using NSDF/MPM pitch
## detection. Designed for low-spec Chromebooks (2-core, 2 GB RAM).
##
## Usage:
##   var analyzer = VoiceAnalyzer.new()
##   analyzer.start(sample_rate, beats_per_section, beat_duration)
##   # Each frame during recording:
##   analyzer.push_samples(new_samples)
##   # When recording stops:
##   var sequence: Sequence = analyzer.finalize()

# ── Configuration ────────────────────────────────────────────────────────────

## Internal analysis sample rate (downsample to this from mic rate).
## 11025 Hz keeps the 60-1000 Hz vocal range fully resolvable while cutting
## the NSDF inner loop work ~4x versus 22050 Hz (lower-spec web target).
const ANALYSIS_RATE: float = 11025.0

## NSDF frame size in samples at ANALYSIS_RATE (~93 ms, resolves down to ~80 Hz).
const FRAME_SIZE: int = 1024

## Hop size in samples (half frame, ~46 ms).
const HOP_SIZE: int = 512

## Minimum fundamental frequency to search (Hz). Determines max lag.
## Bumped from 60 to 80 Hz since lowest assignable note is C3 (~131 Hz).
const MIN_FREQ: float = 80.0

## Maximum fundamental frequency to search (Hz). Determines min lag.
## Trimmed from 1000 to 900 Hz since highest assignable note is B5 (~988 Hz);
## the small reduction shortens the outer NSDF loop on the hot path.
const MAX_FREQ: float = 900.0

## RMS threshold below which a frame is considered silent.
const SILENCE_THRESHOLD: float = 0.015

## NSDF peak clarity threshold (0..1). Below this, pitch is unreliable.
const CLARITY_THRESHOLD: float = 0.25

## Note-on hysteresis: RMS must exceed this to start a note.
const ONSET_RMS_THRESHOLD: float = 0.02

## Note-off hysteresis: RMS must drop below this to end a note.
const OFFSET_RMS_THRESHOLD: float = 0.012

## Minimum note duration in seconds (debounce).
const MIN_NOTE_DURATION: float = 0.06

## Minimum silence duration in seconds before allowing new note.
const MIN_SILENCE_DURATION: float = 0.04

## Maximum pitch drift (in cents) before splitting into a new note.
const MAX_PITCH_DRIFT_CENTS: float = 80.0

## Number of consecutive drifted frames before splitting.
const DRIFT_FRAME_COUNT: int = 3

## Median filter window size for pitch smoothing.
const MEDIAN_WINDOW: int = 5

## One-pole smoothing factor for pitch (0 = no smoothing, 1 = full).
const PITCH_SMOOTH_ALPHA: float = 0.3

## Onset look-back compensation in seconds.
const ONSET_LOOKBACK: float = 0.025

## Octave range for MIDI note output (inclusive). Maps to note IDs.
const OCTAVE_MIN: int = 3
const OCTAVE_MAX: int = 5

## MIDI note range corresponding to octave 3..5 (C3=48, B5=83 in standard MIDI).
## In this project, note IDs start at 0 for C1, so octave 3 starts at ID 36.
const NOTE_ID_MIN: int = 36  # C3 in project's ID system (octave 3 * 12)
const NOTE_ID_MAX: int = 83  # B5 in project's ID system (octave 5 * 12 + 11)

# ── Internal state ───────────────────────────────────────────────────────────

var _source_rate: float = 44100.0
var _downsample_ratio: float = 2.0
var _beats_per_section: int = 16
var _beat_duration: float = 0.5
var _total_duration: float = 8.0

## Accumulated input samples (at source rate) awaiting downsampling.
var _input_buffer: PackedFloat32Array = PackedFloat32Array()

## Ring buffer of downsampled samples for NSDF analysis.
var _analysis_buffer: PackedFloat32Array = PackedFloat32Array()
var _analysis_write_pos: int = 0
var _analysis_total_samples: int = 0

## Max lag for NSDF (derived from MIN_FREQ).
var _max_lag: int = 0
## Min lag for NSDF (derived from MAX_FREQ).
var _min_lag: int = 0

## Reusable scratch arrays for NSDF computation.
var _nsdf_buffer: PackedFloat32Array = PackedFloat32Array()
## Prefix sum of squared samples, reused per NSDF call (size FRAME_SIZE + 1).
var _prefix_sq: PackedFloat32Array = PackedFloat32Array()
## Reusable scratch for median filter (size MEDIAN_WINDOW).
var _median_scratch: PackedFloat32Array = PackedFloat32Array()

## Per-hop analysis results.
var _frame_results: Array[Dictionary] = []

## Hop counter (how many hops have been fully processed).
var _hops_processed: int = 0

## Samples consumed so far for hop tracking.
var _samples_since_last_hop: int = 0

## Pitch median filter history.
var _pitch_history: PackedFloat32Array = PackedFloat32Array()

## One-pole smoothed pitch.
var _smoothed_pitch: float = 0.0

## Voicing state machine.
var _is_voiced: bool = false
var _silence_frames: int = 0
var _voiced_frames: int = 0

## Whether start() has been called and finalize() has not.
var _active: bool = false


# ── Public API ───────────────────────────────────────────────────────────────

## Initialize the analyzer for a new recording session.
func start(source_sample_rate: float, beats_per_section: int, beat_duration: float) -> void:
	_source_rate = source_sample_rate
	_downsample_ratio = _source_rate / ANALYSIS_RATE
	_beats_per_section = beats_per_section
	_beat_duration = beat_duration
	_total_duration = float(beats_per_section) * beat_duration

	_max_lag = int(ceil(ANALYSIS_RATE / MIN_FREQ))
	_min_lag = int(floor(ANALYSIS_RATE / MAX_FREQ))

	# Allocate analysis ring buffer (enough for full recording + margin).
	var max_analysis_samples := int(ceil(_total_duration * ANALYSIS_RATE * 1.3))
	_analysis_buffer = PackedFloat32Array()
	_analysis_buffer.resize(max_analysis_samples)
	_analysis_buffer.fill(0.0)
	_analysis_write_pos = 0
	_analysis_total_samples = 0

	# Scratch buffers.
	_nsdf_buffer = PackedFloat32Array()
	_nsdf_buffer.resize(_max_lag + 1)
	_prefix_sq = PackedFloat32Array()
	_prefix_sq.resize(FRAME_SIZE + 1)
	_median_scratch = PackedFloat32Array()
	_median_scratch.resize(MEDIAN_WINDOW)

	# Reset state.
	_input_buffer = PackedFloat32Array()
	_frame_results = []
	_hops_processed = 0
	_samples_since_last_hop = 0
	_pitch_history = PackedFloat32Array()
	_pitch_history.resize(MEDIAN_WINDOW)
	_pitch_history.fill(0.0)
	_smoothed_pitch = 0.0
	_is_voiced = false
	_silence_frames = 0
	_voiced_frames = 0
	_active = true


## Feed new audio samples (at source sample rate, mono float32).
## Call this every _process frame with samples from AudioEffectCapture.
## `max_hops` bounds how many NSDF hops are processed in this call (negative
## = unbounded). Capping per-frame work keeps long sessions jank-free; any
## leftover hops sit in the analysis buffer and are drained on later calls,
## with finalize() processing whatever remains in one go.
## Returns the number of new hops processed this call.
func push_samples(samples: PackedFloat32Array, max_hops: int = -1) -> int:
	if not _active:
		return 0

	# Append to input buffer for downsampling.
	_input_buffer.append_array(samples)

	# Downsample and write into analysis buffer.
	var new_hops := 0
	var ds_ratio := _downsample_ratio
	var available := int(float(_input_buffer.size()) / ds_ratio)

	if available <= 0:
		return 0

	# Downsample directly into the analysis buffer (linear interpolation),
	# avoiding an intermediate array and a second copy loop. The actual number
	# of samples written may be less than `available` if the analysis buffer
	# filled up, so use the returned count to stay in sync.
	var written := _downsample_into(_input_buffer, ds_ratio, available)

	if written <= 0:
		return 0

	# Remove consumed input samples (only those actually downsampled).
	var consumed_input := int(float(written) * ds_ratio)
	if consumed_input >= _input_buffer.size():
		_input_buffer = PackedFloat32Array()
	else:
		_input_buffer = _input_buffer.slice(consumed_input)

	# Process any complete hops.
	_samples_since_last_hop += written
	while _samples_since_last_hop >= HOP_SIZE:
		if max_hops >= 0 and new_hops >= max_hops:
			# Cap reached. Leave the leftover hops (and their samples) queued
			# in _samples_since_last_hop / _analysis_buffer; subsequent calls
			# or finalize() will drain them.
			break
		var hop_start := _hops_processed * HOP_SIZE
		if hop_start + FRAME_SIZE <= _analysis_total_samples:
			_process_frame(hop_start)
			_hops_processed += 1
			new_hops += 1
		_samples_since_last_hop -= HOP_SIZE

	return new_hops


## Finalize analysis and return the Sequence. Call after recording stops.
## Performs final smoothing, segmentation, and beat quantization.
func finalize() -> Sequence:
	if not _active:
		return Sequence.new([])
	_active = false

	# Process any remaining unprocessed hops.
	var hop_start := _hops_processed * HOP_SIZE
	while hop_start + FRAME_SIZE <= _analysis_total_samples:
		_process_frame(hop_start)
		_hops_processed += 1
		hop_start = _hops_processed * HOP_SIZE

	# Build note segments from frame results.
	var notes := _segment_notes()

	# Quantize to beat grid.
	var sequence_notes := _quantize_to_beats(notes)

	return Sequence.new(sequence_notes)


## Returns true if the analyzer is currently active (between start/finalize).
func is_active() -> bool:
	return _active


# ── Frame Processing (called per hop) ───────────────────────────────────────

func _process_frame(start_sample: int) -> void:
	# Slice the frame into a contiguous local buffer once per hop. Indexing a
	# local PackedFloat32Array is significantly cheaper in GDScript than
	# repeated global property + offset accesses inside the inner NSDF loop.
	var frame := _analysis_buffer.slice(start_sample, start_sample + FRAME_SIZE)

	# Compute RMS for voicing decision.
	var rms := _compute_rms(frame, FRAME_SIZE)

	# Detect pitch using NSDF/MPM.
	var pitch := 0.0
	var clarity := 0.0

	if rms >= SILENCE_THRESHOLD:
		var result := _nsdf_pitch(frame, FRAME_SIZE)
		pitch = result.x  # Hz
		clarity = result.y  # 0..1

	# Apply median filter to pitch.
	var filtered_pitch := _median_filter_pitch(pitch if clarity >= CLARITY_THRESHOLD else 0.0)

	# One-pole smooth.
	if filtered_pitch > 0.0 and _smoothed_pitch > 0.0:
		_smoothed_pitch = _smoothed_pitch + PITCH_SMOOTH_ALPHA * (filtered_pitch - _smoothed_pitch)
	elif filtered_pitch > 0.0:
		_smoothed_pitch = filtered_pitch
	# If filtered_pitch is 0, keep previous smoothed value (will be marked unvoiced).

	# Voicing state machine with hysteresis.
	var frame_voiced := false
	if not _is_voiced:
		if rms >= ONSET_RMS_THRESHOLD and clarity >= CLARITY_THRESHOLD and filtered_pitch > 0.0:
			_voiced_frames += 1
			_silence_frames = 0
			if _voiced_frames >= 2:  # Require 2 consecutive voiced frames.
				_is_voiced = true
				frame_voiced = true
		else:
			_voiced_frames = 0
			_silence_frames += 1
	else:
		if rms < OFFSET_RMS_THRESHOLD or clarity < CLARITY_THRESHOLD * 0.7:
			_silence_frames += 1
			_voiced_frames = 0
			var silence_duration_s := float(_silence_frames) * (float(HOP_SIZE) / ANALYSIS_RATE)
			if silence_duration_s >= MIN_SILENCE_DURATION:
				_is_voiced = false
		else:
			_silence_frames = 0
			_voiced_frames += 1
			frame_voiced = true

	# Store frame result.
	var time_s := float(start_sample) / ANALYSIS_RATE
	_frame_results.append({
		"time": time_s,
		"pitch": _smoothed_pitch if frame_voiced else 0.0,
		"rms": rms,
		"clarity": clarity,
		"voiced": frame_voiced,
	})


# ── NSDF / MPM Pitch Detection ──────────────────────────────────────────────

## Returns Vector2(frequency_hz, clarity) using Normalized Square Difference
## Function (McLeod Pitch Method).
func _nsdf_pitch(frame: PackedFloat32Array, length: int) -> Vector2:
	var n := length
	var max_lag := mini(_max_lag, n - 1)
	var min_lag := _min_lag

	# Compute NSDF for each lag.
	# NSDF(tau) = 2 * r(tau) / m(tau)
	# where r(tau) = autocorrelation, m(tau) = energy normalization term.
	_nsdf_buffer.fill(0.0)

	# Prefix sum of squared samples so m_left/m_right become O(1) per tau.
	# prefix_sq[k] = sum_{i=0..k-1} frame[i]^2, length n+1. Reused across calls.
	var prefix_sq := _prefix_sq
	var nsdf_buf := _nsdf_buffer
	prefix_sq[0] = 0.0
	var running := 0.0
	var i := 0
	while i < n:
		var s := frame[i]
		running += s * s
		prefix_sq[i + 1] = running
		i += 1

	var total_energy := prefix_sq[n]
	var tau := min_lag
	while tau <= max_lag:
		var limit := n - tau
		# Autocorrelation at lag tau — tight while-loop on a local array.
		var acf := 0.0
		var j := 0
		while j < limit:
			acf += frame[j] * frame[j + tau]
			j += 1

		# m_left = sum frame[i]^2 for i in [0, limit-1]
		# m_right = sum frame[i]^2 for i in [tau, n-1]
		var m := prefix_sq[limit] + total_energy - prefix_sq[tau]

		if m > 0.0:
			nsdf_buf[tau] = 2.0 * acf / m
		else:
			nsdf_buf[tau] = 0.0
		tau += 1

	# Find the highest positive NSDF peak above threshold using MPM peak picking.
	var best_lag := 0
	var best_val := -1.0

	# Find peaks: look for positive zero crossings then local maxima.
	var in_positive := nsdf_buf[min_lag] > 0.0
	var peak_lag := min_lag
	var peak_val := nsdf_buf[min_lag]

	var t := min_lag + 1
	while t <= max_lag:
		var val := nsdf_buf[t]
		if not in_positive:
			if val > 0.0:
				in_positive = true
				peak_lag = t
				peak_val = val
		else:
			if val > peak_val:
				peak_lag = t
				peak_val = val
			elif val < 0.0:
				# Crossed back to negative — end of this peak region.
				if peak_val > best_val:
					best_val = peak_val
					best_lag = peak_lag
				in_positive = false
				peak_val = 0.0
		t += 1

	# Check the last positive region.
	if in_positive and peak_val > best_val:
		best_val = peak_val
		best_lag = peak_lag

	if best_lag <= 0 or best_val < CLARITY_THRESHOLD:
		return Vector2(0.0, 0.0)

	# Parabolic interpolation around best_lag for sub-sample accuracy.
	var refined_lag := float(best_lag)
	if best_lag > min_lag and best_lag < max_lag:
		var y_minus := _nsdf_buffer[best_lag - 1]
		var y_zero := _nsdf_buffer[best_lag]
		var y_plus := _nsdf_buffer[best_lag + 1]
		var denom := 2.0 * y_zero - y_minus - y_plus
		if abs(denom) > 1e-10:
			refined_lag = float(best_lag) + (y_minus - y_plus) / (2.0 * denom)

	var frequency := ANALYSIS_RATE / refined_lag
	var clarity := clampf(best_val, 0.0, 1.0)
	return Vector2(frequency, clarity)


# ── Helpers ──────────────────────────────────────────────────────────────────

func _compute_rms(frame: PackedFloat32Array, length: int) -> float:
	var sum := 0.0
	var i := 0
	while i < length:
		var s := frame[i]
		sum += s * s
		i += 1
	return sqrt(sum / float(length))


## Downsample `output_count` samples from `input` (linear interpolation) directly
## into the analysis ring buffer at the current write position. Samples past the
## buffer end are dropped (matching the prior bounds-checked behavior).
## Returns the number of samples actually written to the analysis buffer, which
## may be less than `output_count` if the buffer filled up.
func _downsample_into(input: PackedFloat32Array, ratio: float, output_count: int) -> int:
	var buf_size := _analysis_buffer.size()
	var input_size := input.size()
	var written := 0
	for i in range(output_count):
		if _analysis_write_pos >= buf_size:
			break
		var src_pos := float(i) * ratio
		var idx := int(src_pos)
		var frac := src_pos - float(idx)
		var sample := 0.0
		if idx + 1 < input_size:
			sample = input[idx] * (1.0 - frac) + input[idx + 1] * frac
		elif idx < input_size:
			sample = input[idx]
		_analysis_buffer[_analysis_write_pos] = sample
		_analysis_write_pos += 1
		_analysis_total_samples += 1
		written += 1
	return written


func _median_filter_pitch(pitch: float) -> float:
	# Shift history and insert new value.
	for i in range(MEDIAN_WINDOW - 1):
		_pitch_history[i] = _pitch_history[i + 1]
	_pitch_history[MEDIAN_WINDOW - 1] = pitch

	# Insertion-sort non-zero values into reusable scratch (no allocation).
	var count := 0
	for i in range(MEDIAN_WINDOW):
		var v := _pitch_history[i]
		if v > 0.0:
			var j := count - 1
			while j >= 0 and _median_scratch[j] > v:
				_median_scratch[j + 1] = _median_scratch[j]
				j -= 1
			_median_scratch[j + 1] = v
			count += 1

	if count == 0:
		return 0.0

	# Return median (same index as the previous sort-based implementation).
	@warning_ignore("integer_division")
	return _median_scratch[count / 2]


## Convert frequency to MIDI note number (A4 = 69 = 440 Hz).
static func _freq_to_midi(freq: float) -> float:
	if freq <= 0.0:
		return 0.0
	return 69.0 + 12.0 * log(freq / 440.0) / log(2.0)


## Convert MIDI note number to frequency.
static func _midi_to_freq(midi: float) -> float:
	return 440.0 * pow(2.0, (midi - 69.0) / 12.0)


## Convert MIDI note to this project's note ID system.
## Project uses: C1=0, so note_id = midi_note - 24 (since MIDI C1 = 24).
static func _midi_to_note_id(midi_note: int) -> int:
	return clampi(midi_note - 24, NOTE_ID_MIN, NOTE_ID_MAX)


## Cent difference between two frequencies.
static func _cent_diff(f1: float, f2: float) -> float:
	if f1 <= 0.0 or f2 <= 0.0:
		return 99999.0
	return absf(1200.0 * log(f1 / f2) / log(2.0))


# ── Note Segmentation ────────────────────────────────────────────────────────

## Internal note candidate before beat quantization.
class _NoteCandidate:
	var start_time: float = 0.0
	var end_time: float = 0.0
	var pitches: PackedFloat32Array = PackedFloat32Array()
	var rms_values: PackedFloat32Array = PackedFloat32Array()

	func avg_pitch() -> float:
		if pitches.size() == 0:
			return 0.0
		var sum := 0.0
		for p in pitches:
			sum += p
		return sum / float(pitches.size())

	func avg_rms() -> float:
		if rms_values.size() == 0:
			return 0.0
		var sum := 0.0
		for r in rms_values:
			sum += r
		return sum / float(rms_values.size())

	func duration() -> float:
		return end_time - start_time


func _segment_notes() -> Array[_NoteCandidate]:
	var notes: Array[_NoteCandidate] = []
	var current_note: _NoteCandidate = null
	var drift_count := 0

	for frame in _frame_results:
		var time: float = frame["time"]
		var pitch: float = frame["pitch"]
		var rms: float = frame["rms"]
		var voiced: bool = frame["voiced"]

		if not voiced or pitch <= 0.0:
			# End current note if it meets minimum duration.
			if current_note != null:
				current_note.end_time = time
				if current_note.duration() >= MIN_NOTE_DURATION:
					notes.append(current_note)
				current_note = null
			drift_count = 0
			continue

		if current_note == null:
			# Start new note.
			current_note = _NoteCandidate.new()
			current_note.start_time = time
			current_note.end_time = time + float(HOP_SIZE) / ANALYSIS_RATE
			current_note.pitches.append(pitch)
			current_note.rms_values.append(rms)
			drift_count = 0
		else:
			# Check if pitch has drifted too far from current note's average.
			var cents := _cent_diff(pitch, current_note.avg_pitch())
			if cents > MAX_PITCH_DRIFT_CENTS:
				drift_count += 1
				if drift_count >= DRIFT_FRAME_COUNT:
					# Split: end current note, start new one.
					current_note.end_time = time
					if current_note.duration() >= MIN_NOTE_DURATION:
						notes.append(current_note)
					current_note = _NoteCandidate.new()
					current_note.start_time = time
					current_note.end_time = time + float(HOP_SIZE) / ANALYSIS_RATE
					current_note.pitches.append(pitch)
					current_note.rms_values.append(rms)
					drift_count = 0
			else:
				drift_count = 0
				current_note.end_time = time + float(HOP_SIZE) / ANALYSIS_RATE
				current_note.pitches.append(pitch)
				current_note.rms_values.append(rms)

	# Close last note.
	if current_note != null and current_note.duration() >= MIN_NOTE_DURATION:
		notes.append(current_note)

	return notes


# ── Beat Quantization ────────────────────────────────────────────────────────

func _quantize_to_beats(candidates: Array[_NoteCandidate]) -> Array[SequenceNote]:
	var sequence_notes: Array[SequenceNote] = []

	if candidates.size() == 0 or _beat_duration <= 0.0:
		return sequence_notes

	for candidate in candidates:
		# Apply onset look-back compensation.
		var onset_time := maxf(0.0, candidate.start_time - ONSET_LOOKBACK)
		var offset_time := candidate.end_time

		# Convert times to beat positions.
		var start_beat := int(round(onset_time / _beat_duration))
		var end_beat := int(round(offset_time / _beat_duration))

		# Clamp to valid range.
		start_beat = clampi(start_beat, 0, _beats_per_section - 1)
		end_beat = clampi(end_beat, start_beat + 1, _beats_per_section)

		var duration := end_beat - start_beat
		if duration < 1:
			duration = 1

		# Convert average pitch to MIDI note, then to project note ID.
		var avg_freq := candidate.avg_pitch()
		var midi_float := _freq_to_midi(avg_freq)
		var midi_note := int(round(midi_float))

		# Clamp to octave range (MIDI 48=C3 to 83=B5).
		midi_note = clampi(midi_note, 48, 83)
		var note_id := _midi_to_note_id(midi_note)

		# Velocity from RMS (normalize to 0..1 range).
		var velocity := clampf(candidate.avg_rms() * 10.0, 0.1, 1.0)

		# Check for overlapping existing notes at same beat.
		var overlap := false
		for existing in sequence_notes:
			if existing.beat == start_beat:
				overlap = true
				break

		if not overlap:
			var seq_note := SequenceNote.new()
			seq_note.note = note_id
			seq_note.beat = start_beat
			seq_note.duration = duration
			seq_note.velocity = velocity
			sequence_notes.append(seq_note)

	return sequence_notes
