class_name WaveformVisualizer

## Draws circular waveform lines from AudioStreamWAV data onto Line2D nodes.

var small_line: Line2D
var big_line: Line2D
var big_line_base_dist: int
var big_line_volume_dist: int
var big_line_reversed: bool


func _init(p_small_line: Line2D, p_big_line: Line2D, p_base_dist: int = 280, p_volume_dist: int = 28, p_reversed: bool = false):
	small_line = p_small_line
	big_line = p_big_line
	big_line_base_dist = p_base_dist
	big_line_volume_dist = p_volume_dist
	big_line_reversed = p_reversed


func update_lines(audio: AudioStream) -> void:
	_set_small_volume_line(audio)
	_set_big_volume_line(audio)


func _set_small_volume_line(audio: AudioStream) -> void:
	_set_volume_line(small_line, audio, 40, 15, 15)


func _set_big_volume_line(audio: AudioStream) -> void:
	_set_volume_line(big_line, audio, 100, big_line_base_dist, big_line_volume_dist, big_line_reversed)


func _set_volume_line(line: Line2D, audio: AudioStream, points: int, base_dist: int, volume_dist: int, reversed: bool = false) -> void:
	if not line:
		return

	var offsets = _calculate_volume_offsets(audio, points, base_dist, volume_dist, reversed)

	line.clear_points()
	for offset in offsets:
		line.add_point(offset)


func _calculate_volume_offsets(audio: AudioStream, points: int, base_dist: int, volume_dist: int, reversed: bool) -> Array:
	var offsets: Array = []

	for i in range(points):
		var volume_offset := 0.0

		if audio and audio is AudioStreamWAV:
			var wav := audio as AudioStreamWAV
			var length := wav.get_length()
			var percentage := float(i) / points
			volume_offset = get_volume_at_time(wav, percentage * length) * volume_dist

		var angle := -PI / 2.0 + TAU * i / points
		var final_dist := (base_dist - volume_offset) if reversed else (base_dist + volume_offset)

		offsets.append(Vector2(cos(angle), sin(angle)) * final_dist)

	return offsets


static func get_volume_at_time(audio: AudioStreamWAV, time: float) -> float:
	if not audio or audio.data.size() == 0:
		push_error("Invalid audio stream")
		return 0.0

	var sample_rate := audio.mix_rate
	var channels := 2 if audio.stereo else 1
	var format_size := 2 if audio.format == AudioStreamWAV.FORMAT_16_BITS else 1

	var sample_index := int(time * sample_rate) * channels
	var byte_index := sample_index * format_size

	if byte_index >= audio.data.size() - format_size:
		push_error("Time exceeds sample length")
		return 0.0

	var volume := 0.0
	if audio.format == AudioStreamWAV.FORMAT_16_BITS:
		var bytes := audio.data.slice(byte_index, byte_index + 2)
		var value := bytes.decode_s16(0)
		volume = abs(value / 32768.0)
	else:
		var value := audio.data[byte_index] as int
		if value > 127:
			value -= 256
		volume = abs(value / 128.0)

	return volume
