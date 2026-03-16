class_name AudioHelpers


static func trim_audio_stream(original: AudioStream, seconds_to_trim: float) -> AudioStream:
	var original_data: PackedByteArray = original.data
	var audio_length: float = original.get_length()

	if audio_length <= 0.0:
		print("Invalid audio length.")
		return original

	var bytes_per_second: float = float(original_data.size()) / audio_length
	var frame_size: int = (2 if original.get("stereo") else 1) * \
		(2 if original.get("format") == 1 else 1)
	var raw_trim_bytes: int = int(seconds_to_trim * bytes_per_second)
	@warning_ignore("integer_division")
	var aligned_trim_bytes: int = (raw_trim_bytes / frame_size) * frame_size

	print("Trim %s seconds → %s bytes" % [seconds_to_trim, aligned_trim_bytes])

	if aligned_trim_bytes >= original_data.size():
		print("Trim amount exceeds or matches original audio length.")
		return original

	var trimmed_data: PackedByteArray = original_data.slice(aligned_trim_bytes)

	var trimmed: AudioStreamWAV = AudioStreamWAV.new()
	trimmed.data = trimmed_data
	trimmed.mix_rate = original.mix_rate
	trimmed.stereo = original.stereo
	trimmed.format = original.format

	return trimmed
