class_name SynthWaveform
extends RefCounted
## Draws a circular waveform line from AudioStreamWAV data onto a Line2D node.

var line: Line2D
var points: int
var base_dist: int
var volume_dist: int
var reversed: bool
var offsets: Array = []

func _init(p_line: Line2D, p_points: int = 100, p_base_dist: int = 280, p_volume_dist: int = 28, p_reversed: bool = false):
	line = p_line
	points = p_points
	base_dist = p_base_dist
	volume_dist = p_volume_dist
	reversed = p_reversed


func update_line(audio: AudioStream) -> void:
	if not line:
		return
	offsets = _calculate_volume_offsets(audio, points, base_dist, volume_dist, reversed)
	_apply_offsets(offsets)


func update_line_from_recording(rec_data: RecordingData) -> void:
	if not line:
		return
	if rec_data == null:
		return
	offsets = rec_data.get_circular_waveform_offsets(points, base_dist, volume_dist, reversed)
	_apply_offsets(offsets)


func _apply_offsets(new_offsets) -> void:
	line.clear_points()
	for offset in new_offsets:
		line.add_point(offset)


func _calculate_volume_offsets(audio: AudioStream, points: int, base_dist: int, volume_dist: int, reversed: bool) -> Array:
	var new_offsets: Array = []

	for i in range(points):
		var volume_offset := 0.0

		if audio and audio is AudioStreamWAV:
			var wav := audio as AudioStreamWAV
			var length := wav.get_length()
			var percentage := float(i) / points
			volume_offset = get_volume_at_time(wav, percentage * length) * volume_dist

		var angle := -PI / 2.0 + TAU * i / points
		var final_dist := (base_dist - volume_offset) if reversed else (base_dist + volume_offset)

		new_offsets.append(Vector2(cos(angle), sin(angle)) * final_dist)

	return new_offsets


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
