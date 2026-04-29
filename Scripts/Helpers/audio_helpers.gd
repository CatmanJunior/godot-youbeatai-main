class_name AudioHelpers

## Caps an AudioStreamWAV to a maximum duration in seconds by truncating trailing data.
static func cap_audio_duration(original: AudioStream, max_duration: float) -> AudioStream:
	if original == null or max_duration <= 0.0:
		return original

	var current_length: float = original.get_length()
	if current_length <= max_duration:
		return original

	var is_stereo: bool = original.stereo
	var fmt: int = original.format
	var channels: int = 2 if is_stereo else 1
	var bytes_per_sample: int = 2 if fmt == 1 else 1
	var frame_size: int = channels * bytes_per_sample

	var max_frames: int = int(max_duration * float(original.mix_rate))
	var max_bytes: int = max_frames * frame_size
	max_bytes = mini(max_bytes, original.data.size())

	var capped: AudioStreamWAV = AudioStreamWAV.new()
	capped.data = original.data.slice(0, max_bytes)
	capped.mix_rate = original.mix_rate
	capped.stereo = original.stereo
	capped.format = original.format
	return capped


## Trims a precise leading segment of known duration from an AudioStreamWAV.
## Use this when you already know the silent lead time (e.g. from recording timestamps).
static func trim_audio_by_time_offset(original: AudioStream, offset_seconds: float) -> AudioStream:
	if original == null or offset_seconds <= 0.0:
		return original

	var is_stereo: bool = original.stereo
	var fmt: int = original.format
	var channels: int = 2 if is_stereo else 1
	var bytes_per_sample: int = 2 if fmt == 1 else 1
	var frame_size: int = channels * bytes_per_sample

	var offset_bytes: int = int(offset_seconds * float(original.mix_rate)) * frame_size
	offset_bytes = mini(offset_bytes, original.data.size())

	if offset_bytes <= 0:
		return original

	print("Trim by time offset: skipping %.3f s (%d bytes)" % [offset_seconds, offset_bytes])

	var trimmed: AudioStreamWAV = AudioStreamWAV.new()
	trimmed.data = original.data.slice(offset_bytes)
	trimmed.mix_rate = original.mix_rate
	trimmed.stereo = original.stereo
	trimmed.format = original.format
	return trimmed


## Combined trim for sample recordings: uses the known silent lead time to jump
## close to the sound onset, backs off by a small safety buffer, then amplitude-scans
## the remaining short window to find the exact attack without cutting into it.
## silence_threshold is a normalised PCM amplitude (0.0–1.0).
static func trim_sample_smart(
		original: AudioStream,
		silent_lead_time: float,
		silence_threshold: float = 0.01,
		safety_buffer_seconds: float = 0.05) -> AudioStream:
	if original == null:
		return original

	# Back off by the safety buffer so we don't skip over the very start of the attack.
	var coarse_offset: float = maxf(0.0, silent_lead_time - safety_buffer_seconds)
	var working: AudioStream = trim_audio_by_time_offset(original, coarse_offset)

	# Fine-trim the remaining small window with an amplitude scan.
	return trim_audio_stream(working, silence_threshold)


## Trims leading silence from an AudioStreamWAV by scanning the raw sample data.
## silence_threshold: normalised amplitude (0.0–1.0) below which a frame counts as silent.
static func trim_audio_stream(original: AudioStream, silence_threshold: float = 0.01) -> AudioStream:
	var original_data: PackedByteArray = original.data
	if original_data.size() == 0:
		return original

	var is_stereo: bool = original.stereo
	var fmt: int = original.format          # 0 = 8-bit, 1 = 16-bit
	var channels: int = 2 if is_stereo else 1
	var bytes_per_sample: int = 2 if fmt == 1 else 1
	var frame_size: int = channels * bytes_per_sample
	@warning_ignore("integer_division")
	var total_frames: int = original_data.size() / frame_size

	# Scan for the first frame whose peak amplitude exceeds the threshold
	var first_sound_frame: int = total_frames
	for i in range(total_frames):
		var offset: int = i * frame_size
		var frame_peak: float = 0.0
		for ch in range(channels):
			var s_off: int = offset + ch * bytes_per_sample
			var amplitude: float
			if fmt == 1: # 16-bit signed little-endian
				var raw: int = original_data[s_off] | (original_data[s_off + 1] << 8)
				if raw >= 32768:
					raw -= 65536
				amplitude = absf(float(raw) / 32768.0)
			else: # 8-bit unsigned
				amplitude = absf(float(original_data[s_off] - 128) / 128.0)
			frame_peak = maxf(frame_peak, amplitude)
		if frame_peak > silence_threshold:
			first_sound_frame = i
			break

	if first_sound_frame <= 0 or first_sound_frame >= total_frames:
		return original

	var trim_bytes: int = first_sound_frame * frame_size
	print("Auto-trim: skipped %d silent frames (%d bytes)" % [first_sound_frame, trim_bytes])

	var trimmed_data: PackedByteArray = original_data.slice(trim_bytes)

	var trimmed: AudioStreamWAV = AudioStreamWAV.new()
	trimmed.data = trimmed_data
	trimmed.mix_rate = original.mix_rate
	trimmed.stereo = original.stereo
	trimmed.format = original.format

	return trimmed
