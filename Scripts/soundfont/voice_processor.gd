class_name VoiceProcessor

const Fft = preload("res://fft/Fft.gd")

const combine_threshold: float = -1 # -1 is off
const octaveRange: Vector2i = Vector2i(3, 5) # inclusive
const silence_threshold: float = 0.01  # RMS below this = silence/rest

## Extract PCM samples from an AudioStreamWAV as an Array of floats in [-1, 1].
static func _get_samples(audio: AudioStreamWAV, downsample_factor: int = 1) -> PackedFloat32Array:
	var raw := audio.data
	var channels := 2 if audio.stereo else 1
	var is_16bit := audio.format == AudioStreamWAV.FORMAT_16_BITS
	var byte_step := (2 if is_16bit else 1) * channels * downsample_factor

	var total_bytes := raw.size()
	@warning_ignore("integer_division")
	var num_samples := total_bytes / byte_step
	var samples := PackedFloat32Array()
	samples.resize(num_samples)  # pre-allocate!

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


## Compute RMS volume of a chunk of samples.
static func _rms(chunk: PackedFloat32Array) -> float:
	if chunk.size() == 0:
		return 0.0
	var sum := 0.0
	for s in chunk:
		sum += s * s
	return sqrt(sum / chunk.size())


## Round up to the next power of 2.
static func _next_power_of_2(n: int) -> int:
	var p := 1
	while p < n:
		p *= 2
	return p


## Find the dominant frequency in a chunk of samples using FFT.
static func _dominant_frequency(chunk: PackedFloat32Array, sample_rate: float) -> float:
	const MAX_FFT_SIZE := 2048*4
	var n := mini(_next_power_of_2(chunk.size()), MAX_FFT_SIZE)
	var fft_input: Array = []
	fft_input.resize(n)
	# Downsample: take evenly-spaced samples from the chunk
	var step: float = float(chunk.size()) / float(n)
	for i in range(n):
		fft_input[i] = float(chunk[int(i * step)])

	var spectrum: Array = Fft.fft(fft_input)

	# Only look at the first half (positive frequencies)
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
	var samples: PackedFloat32Array = _get_samples(wav)
	if samples.size() == 0:
		printerr("no sample data in audio stream")
		return null

	var sample_rate := float(wav.mix_rate)

	var length: int = int(GameState.total_beats)

	if length <= 0:
		printerr("invalid beat length")
		return null
	@warning_ignore("integer_division")
	var samples_per_beat := int(samples.size() / length)
	if samples_per_beat == 0:
		printerr("not enough samples received, got: %d" % samples.size())
		return null

	const MAX_SUBDIVISIONS := 4
	@warning_ignore("integer_division")
	var samples_per_sub := int(samples_per_beat / MAX_SUBDIVISIONS)
	# If the beat is too short to subdivide, fall back to 1 subdivision
	var subdivisions := MAX_SUBDIVISIONS if samples_per_sub > 0 else 1
	if subdivisions == 1:
		samples_per_sub = samples_per_beat

	# Analyze each beat window with subdivisions
	var sequence_notes: Array[SequenceNote] = []

	for beat_idx in range(length):
		var beat_start := beat_idx * samples_per_beat

		for sub in range(subdivisions):
			var start_idx := beat_start + sub * samples_per_sub
			var end_idx := mini(start_idx + samples_per_sub, samples.size())
			if start_idx >= samples.size():
				break
			var chunk := samples.slice(start_idx, end_idx)

			var freq := _dominant_frequency(chunk, sample_rate)
			var vol := _rms(chunk)

			# Skip silent sub-beats
			if vol < silence_threshold:
				continue

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

			# Combine with previous sub-beat if same note, same beat, and combining is enabled
			var combined := false
			if combine_threshold >= 0 and sequence_notes.size() > 0:
				var last := sequence_notes.back() as SequenceNote
				if last.beat == beat_idx and abs(last.note - closest.id) <= combine_threshold:
					combined = true

			if not combined:
				var sn := SequenceNote.new()
				sn.beat = beat_idx
				sn.sub_beat = sub
				sn.note = closest.id
				sn.duration = 1
				sn.velocity = vol
				sequence_notes.append(sn)

	for sn in sequence_notes:
		print("beat: %d, sub: %d, note: %d, vel: %.3f" % [sn.beat, sn.sub_beat, sn.note, sn.velocity])

	var sequence = Sequence.new(sequence_notes)
	return sequence
