class_name VoiceProcessor

const Fft = preload("res://addons/fft/Fft.gd")

const combine_threshold: float = -1 # -1 is off
const octaveRange: Vector2i = Vector2i(3, 5) # inclusive
const silence_threshold: float = 0.01  # RMS below this = silence/rest
const MAX_FFT_SIZE := 2048 * 4

## Extract PCM samples from an AudioStreamWAV as floats in [-1, 1].
static func get_samples(audio: AudioStreamWAV, downsample_factor: int = 1) -> PackedFloat32Array:
	var raw := audio.data
	var channels := 2 if audio.stereo else 1
	var is_16bit := audio.format == AudioStreamWAV.FORMAT_16_BITS
	var byte_step := (2 if is_16bit else 1) * channels * downsample_factor

	var total_bytes := raw.size()
	@warning_ignore("integer_division")
	var num_samples := total_bytes / byte_step
	var samples := PackedFloat32Array()
	samples.resize(num_samples)

	var i := 0
	var out := 0
	while i < total_bytes and out < num_samples:
		var value := 0.0
		if is_16bit:
			if i + 1 >= total_bytes: break
			value = raw.decode_s16(i) / 32768.0
		else:
			var v := raw[i] as int
			value = (v - 256 if v > 127 else v) / 128.0
		samples[out] = value
		out += 1
		i += byte_step
	samples.resize(out)
	return samples


## Compute RMS of a chunk of samples.
static func compute_rms(chunk: PackedFloat32Array) -> float:
	if chunk.size() == 0:
		return 0.0
	var sum := 0.0
	for s in chunk:
		sum += s * s
	return sqrt(sum / chunk.size())


## Peak absolute amplitude across an array of samples.
static func compute_peak(samples: PackedFloat32Array) -> float:
	var peak := 0.0
	for s in samples:
		var a := absf(s)
		if a > peak:
			peak = a
	return peak


## Convert RMS to dB relative to full scale (-80 for silence).
static func rms_to_db(rms: float) -> float:
	if rms < 0.00001:
		return -80.0
	return 20.0 * log(rms) / log(10.0)


## Per-window RMS envelope across the full sample array.
static func compute_volume_envelope(samples: PackedFloat32Array, window_count: int = 64) -> PackedFloat32Array:
	if samples.size() == 0:
		return PackedFloat32Array()
	@warning_ignore("integer_division")
	var window_size := samples.size() / window_count
	if window_size == 0:
		window_size = 1
	var result := PackedFloat32Array()
	result.resize(window_count)
	for i in range(window_count):
		var start := i * window_size
		var end := mini(start + window_size, samples.size())
		result[i] = compute_rms(samples.slice(start, end))
	return result


## Per-beat analysis: Vector3(freq, vol, time). Silent beats get freq = -1.
static func analyze_beats(samples: PackedFloat32Array, sample_rate: float, duration: float, beat_count: int) -> PackedVector3Array:
	if samples.size() == 0 or beat_count <= 0:
		return PackedVector3Array()
	@warning_ignore("integer_division")
	var samples_per_beat := samples.size() / beat_count
	if samples_per_beat == 0:
		return PackedVector3Array()
	var beat_duration := duration / float(beat_count)
	var result := PackedVector3Array()
	for i in range(beat_count):
		var start_idx := i * samples_per_beat
		var end_idx := mini((i + 1) * samples_per_beat, samples.size())
		var chunk := samples.slice(start_idx, end_idx)
		var vol := compute_rms(chunk)
		var time := float(i) * beat_duration
		if vol < silence_threshold:
			result.push_back(Vector3(-1.0, 0.0, time))
		else:
			var freq := dominant_frequency(chunk, sample_rate)
			result.push_back(Vector3(freq, vol, time))
	return result


## RMS for a time range [start_time, end_time] within a sample array.
static func compute_rms_at_range(samples: PackedFloat32Array, sample_rate: float, start_time: float, end_time: float) -> float:
	if sample_rate == 0.0:
		return 0.0
	var start_idx := clampi(int(start_time * sample_rate), 0, samples.size())
	var end_idx := clampi(int(end_time * sample_rate), 0, samples.size())
	if start_idx >= end_idx:
		return 0.0
	return compute_rms(samples.slice(start_idx, end_idx))


## Dominant frequency for a time range within a sample array.
static func dominant_frequency_at_range(samples: PackedFloat32Array, sample_rate: float, start_time: float, end_time: float) -> float:
	if sample_rate == 0.0:
		return 0.0
	var start_idx := clampi(int(start_time * sample_rate), 0, samples.size())
	var end_idx := clampi(int(end_time * sample_rate), 0, samples.size())
	if start_idx >= end_idx:
		return 0.0
	return dominant_frequency(samples.slice(start_idx, end_idx), sample_rate)


## Positive-frequency magnitudes for a time range within a sample array.
static func compute_magnitudes_at_range(samples: PackedFloat32Array, sample_rate: float, start_time: float, end_time: float) -> PackedFloat32Array:
	if sample_rate == 0.0:
		return PackedFloat32Array()
	var start_idx := clampi(int(start_time * sample_rate), 0, samples.size())
	var end_idx := clampi(int(end_time * sample_rate), 0, samples.size())
	if start_idx >= end_idx:
		return PackedFloat32Array()
	return compute_magnitudes(samples.slice(start_idx, end_idx))


## Round up to the next power of 2.
static func next_power_of_2(n: int) -> int:
	var p := 1
	while p < n:
		p *= 2
	return p


## Full FFT spectrum of a chunk of samples.
static func compute_spectrum(chunk: PackedFloat32Array) -> Array:
	if chunk.size() == 0:
		return []
	var n := mini(next_power_of_2(chunk.size()), MAX_FFT_SIZE)
	var fft_input: Array = []
	fft_input.resize(n)
	var step := float(chunk.size()) / float(n)
	for i in range(n):
		fft_input[i] = float(chunk[int(i * step)])
	return Fft.fft(fft_input)


## Positive-frequency magnitudes from a chunk of samples.
static func compute_magnitudes(chunk: PackedFloat32Array) -> PackedFloat32Array:
	if chunk.size() == 0:
		return PackedFloat32Array()
	var n := mini(next_power_of_2(chunk.size()), MAX_FFT_SIZE)
	var fft_input: Array = []
	fft_input.resize(n)
	var step := float(chunk.size()) / float(n)
	for i in range(n):
		fft_input[i] = float(chunk[int(i * step)])
	var spectrum: Array = Fft.fft(fft_input)
	@warning_ignore("integer_division")
	var half := n / 2
	var mags := PackedFloat32Array()
	mags.resize(half)
	for i in range(half):
		var re: float = spectrum[i].re
		var im: float = spectrum[i].im
		mags[i] = sqrt(re * re + im * im)
	return mags


## Find the dominant frequency in a chunk of samples using FFT.
static func dominant_frequency(chunk: PackedFloat32Array, sample_rate: float) -> float:
	var n := mini(next_power_of_2(chunk.size()), MAX_FFT_SIZE)
	var fft_input: Array = []
	fft_input.resize(n)
	var step: float = float(chunk.size()) / float(n)
	for i in range(n):
		fft_input[i] = float(chunk[int(i * step)])
	var spectrum: Array = Fft.fft(fft_input)
	@warning_ignore("integer_division")
	var half := n / 2
	var max_magnitude := 0.0
	var max_bin := 0
	for i in range(1, half): # skip DC bin (i=0)
		var re: float = spectrum[i].re
		var im: float = spectrum[i].im
		var magnitude := sqrt(re * re + im * im)
		if magnitude > max_magnitude:
			max_magnitude = magnitude
			max_bin = i
	return float(max_bin) * sample_rate / float(n)


static func process_audio(audio: AudioStream, notes: Notes) -> Sequence:
	if audio == null or not audio is AudioStreamWAV:
		printerr("VoiceProcessor: expected AudioStreamWAV, got %s" % str(type_string(typeof(audio))))
		return null

	var wav := audio as AudioStreamWAV
	var samples: PackedFloat32Array = get_samples(wav)
	if samples.size() == 0:
		printerr("no sample data in audio stream")
		return null

	var sample_rate := float(wav.mix_rate)

	var length: int = int(SongState.total_beats)

	if length <= 0:
		printerr("invalid beat length")
		return null
	@warning_ignore("integer_division")
	var samples_per_beat := int(samples.size() / length)
	if samples_per_beat == 0:
		printerr("not enough samples received, got: %d" % samples.size())
		return null

	# Analyze each beat window: extract dominant frequency and volume
	var result: PackedVector3Array = []
	for i in range(length):
		var start_idx := i * samples_per_beat
		var end_idx := mini((i + 1) * samples_per_beat, samples.size())
		var chunk := samples.slice(start_idx, end_idx)

		var freq := dominant_frequency(chunk, sample_rate)
		var vol := compute_rms(chunk)

		# Skip silent beats — push a sentinel with note id -1
		if vol < silence_threshold:
			result.push_back(Vector3(-1, 0.0, float(i) * GameState.beat_duration))
			continue

		var time := float(i) * GameState.beat_duration

		# Clamp frequency to closest note in octave range
		var closest_diff: float = 9999
		var closest: Note = notes.get_octave(octaveRange.x).notes[0]

		for octaveNumber in range(octaveRange.x, octaveRange.y + 1):
			var octave = notes.get_octave(octaveNumber)
			for note in octave.notes:
				var diff: float = abs(freq - note.frequency)
				if diff < closest_diff:
					closest_diff = diff
					closest = note

		result.push_back(Vector3(closest.id, vol, time))

	# Build sequence notes with optional combining
	var sequence_notes: Array[SequenceNote] = []
	for i in range(len(result)):
		var current = result[i]
		var last: SequenceNote = null

		if len(sequence_notes) > 0:
			last = sequence_notes.back()

		if last == null or abs(last.note - current.x) > combine_threshold:
			last = SequenceNote.new()
			last.beat = i
			last.note = current.x
			last.duration = 1
			last.velocity = current.y
			sequence_notes.append(last)
		else:
			last.duration += 1

	for index in range(len(sequence_notes)):
		print("beat: %d, note: %d, duration: %d" % [sequence_notes[index].beat, sequence_notes[index].note, sequence_notes[index].duration])

	var sequence = Sequence.new(sequence_notes)
	return sequence
