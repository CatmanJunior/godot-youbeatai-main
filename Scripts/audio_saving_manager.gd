class_name AudioSavingManager
extends RefCounted
## Static utility class for audio export and WAV manipulation.
## All heavy-lifting is done on raw PCM data inside AudioStreamWAV,
## so no external libraries (NAudio, etc.) are needed.

# ── Constants ──────────────────────────────────────────────────────────────────
const _WAV_FORMAT_16BIT := 1  # AudioStreamWAV.FORMAT_16_BITS


# ══════════════════════════════════════════════════════════════════════════════
#  PUBLIC  –  High-level export helpers (mirrors C# AudioSaving)
# ══════════════════════════════════════════════════════════════════════════════

## Save the full real-time song recording (SubMaster + voice-over mixed) and
## return the absolute path to the resulting .wav, or "" on failure.
static func save_realtime_recorded_song_as_file(
		recording: AudioStreamWAV,
		voice_over: AudioStreamWAV,
		bpm: int) -> String:

	if recording == null:
		push_warning("AudioSavingManager: no recording to export")
		return ""

	var user_dir := ProjectSettings.globalize_path("user://")
	var sanitized_time := Time.get_time_string_from_system().replace(":", "_")
	var final_name := user_dir.path_join("export_%dbpm_%s" % [bpm, sanitized_time])

	# Mix master recording + voice-over into one stream
	var mixed := _mix_or_fallback(recording, voice_over)

	# Save final WAV
	var err := mixed.save_to_wav(final_name + ".wav")
	if err != OK:
		push_error("AudioSavingManager: save_to_wav failed (%d)" % err)
		return ""

	print("AudioSavingManager: saved song → %s.wav" % final_name)
	return final_name + ".wav"


## Save only the current layer/beat from the recording and return the path.
static func save_realtime_recorded_beat_as_file(
		recording: AudioStreamWAV,
		voice_over: AudioStreamWAV,
		bpm: int,
		layer_index: int,
		beats_amount: int,
		base_time_per_beat: float) -> String:

	if recording == null:
		push_warning("AudioSavingManager: no recording to export")
		return ""

	var user_dir := ProjectSettings.globalize_path("user://")
	var sanitized_time := Time.get_time_string_from_system().replace(":", "_")
	var final_name := user_dir.path_join("export_%dbpm_%s" % [bpm, sanitized_time])

	# Mix master recording + voice-over
	var mixed := _mix_or_fallback(recording, voice_over)

	# Trim to the current layer time range
	var time_per_layer := beats_amount * base_time_per_beat
	var start_time := layer_index * time_per_layer
	var end_time := start_time + time_per_layer
	var trimmed := trim_stream(mixed, start_time, end_time)

	var err := trimmed.save_to_wav(final_name + ".wav")
	if err != OK:
		push_error("AudioSavingManager: save_to_wav failed (%d)" % err)
		return ""

	print("AudioSavingManager: saved beat → %s.wav" % final_name)
	return final_name + ".wav"


## Remove a layer's time-slice from both recording streams IN-PLACE.
## Call this when a layer is deleted while a recording exists.
## Returns the modified streams as a Dictionary { "recording": …, "voice_over": … }.
static func remove_layer_part_of_recordings(
		recording: AudioStreamWAV,
		voice_over: AudioStreamWAV,
		layer: int,
		beats_amount: int,
		base_time_per_beat: float) -> Dictionary:

	var time_per_layer := beats_amount * base_time_per_beat
	var start_time := layer * time_per_layer
	var end_time := start_time + time_per_layer

	var new_rec := remove_segment(recording, start_time, end_time) if recording else null
	var new_vo := remove_segment(voice_over, start_time, end_time) if voice_over else null

	print("AudioSavingManager: removed layer %d (%.2fs–%.2fs)" % [layer, start_time, end_time])
	return { "recording": new_rec, "voice_over": new_vo }


## Insert silence for a new layer in both recording streams IN-PLACE.
## Call this when a layer is added while a recording exists.
## Returns the modified streams as a Dictionary { "recording": …, "voice_over": … }.
static func insert_silent_layer_part_of_recordings(
		recording: AudioStreamWAV,
		voice_over: AudioStreamWAV,
		layer: int,
		beats_amount: int,
		base_time_per_beat: float) -> Dictionary:

	var time_per_layer := beats_amount * base_time_per_beat
	var insert_time := layer * time_per_layer

	var new_rec := insert_silence(recording, insert_time, time_per_layer) if recording else null
	var new_vo := insert_silence(voice_over, insert_time, time_per_layer) if voice_over else null

	print("AudioSavingManager: inserted %.2fs silence at %.2fs for layer %d" % [time_per_layer, insert_time, layer])
	return { "recording": new_rec, "voice_over": new_vo }


# ══════════════════════════════════════════════════════════════════════════════
#  PUBLIC  –  Low-level AudioStreamWAV manipulation
# ══════════════════════════════════════════════════════════════════════════════

## Convert a stereo AudioStreamWAV to mono by averaging L+R channels.
## Returns the original stream unchanged if it is already mono.
static func convert_stereo_to_mono(stream: AudioStreamWAV) -> AudioStreamWAV:
	if stream == null or not stream.stereo:
		return stream

	var src := stream.data
	var bps := 2 if stream.format == _WAV_FORMAT_16BIT else 1  # bytes per sample
	var frame := bps * 2  # stereo frame size
	var mono_size := src.size() / 2
	var dst := PackedByteArray()
	dst.resize(mono_size)

	var i := 0
	var o := 0
	if stream.format == _WAV_FORMAT_16BIT:
		while i + 3 < src.size():
			var left := src.decode_s16(i)
			var right := src.decode_s16(i + 2)
			@warning_ignore("integer_division")
			var mono_sample: int = (left + right) / 2
			dst.encode_s16(o, mono_sample)
			i += 4
			o += 2
	else:  # 8-bit
		while i + 1 < src.size():
			var left := src[i] - 128
			var right := src[i + 1] - 128
			@warning_ignore("integer_division")
			var mono_val: int = (left + right) / 2 + 128
			dst[o] = clampi(mono_val, 0, 255)
			i += 2
			o += 1

	var result := AudioStreamWAV.new()
	result.data = dst
	result.format = stream.format
	result.mix_rate = stream.mix_rate
	result.stereo = false
	return result


## Mix two AudioStreamWAV streams sample-by-sample (additive, clamped).
## Both are normalised to mono 16-bit at the mix_rate of the first stream.
static func mix_streams(a: AudioStreamWAV, b: AudioStreamWAV) -> AudioStreamWAV:
	if a == null:
		return b
	if b == null:
		return a

	# Normalise to mono
	var ma := convert_stereo_to_mono(a) if a.stereo else a
	var mb := convert_stereo_to_mono(b) if b.stereo else b

	# Ensure both 16-bit
	ma = _ensure_16bit(ma)
	mb = _ensure_16bit(mb)

	var ad := ma.data
	var bd := mb.data
	var max_len := maxi(ad.size(), bd.size())
	# Ensure even length for 16-bit
	if max_len % 2 != 0:
		max_len += 1

	var mixed := PackedByteArray()
	mixed.resize(max_len)
	mixed.fill(0)

	var i := 0
	while i + 1 < max_len:
		var sa: int = ad.decode_s16(i) if i + 1 < ad.size() else 0
		var sb: int = bd.decode_s16(i) if i + 1 < bd.size() else 0
		var sum := clampi(sa + sb, -32768, 32767)
		mixed.encode_s16(i, sum)
		i += 2

	var result := AudioStreamWAV.new()
	result.data = mixed
	result.format = AudioStreamWAV.FORMAT_16_BITS
	result.mix_rate = ma.mix_rate
	result.stereo = false
	return result


## Return a new AudioStreamWAV that contains only the samples between
## start_time and end_time (in seconds).
static func trim_stream(stream: AudioStreamWAV, start_time: float, end_time: float) -> AudioStreamWAV:
	if stream == null:
		return null

	var fs := _frame_size(stream)
	var bps_rate := _bytes_per_second(stream)

	var start_byte := _align(int(start_time * bps_rate), fs)
	var end_byte := _align(int(end_time * bps_rate), fs)

	start_byte = clampi(start_byte, 0, stream.data.size())
	end_byte = clampi(end_byte, 0, stream.data.size())

	var result := AudioStreamWAV.new()
	result.data = stream.data.slice(start_byte, end_byte)
	result.format = stream.format
	result.mix_rate = stream.mix_rate
	result.stereo = stream.stereo
	return result


## Return a new AudioStreamWAV with the segment [start_time … end_time]
## removed, making the total length shorter.
static func remove_segment(stream: AudioStreamWAV, start_time: float, end_time: float) -> AudioStreamWAV:
	if stream == null:
		return null

	var fs := _frame_size(stream)
	var bps_rate := _bytes_per_second(stream)

	var start_byte := _align(int(start_time * bps_rate), fs)
	var end_byte := _align(int(end_time * bps_rate), fs)
	start_byte = clampi(start_byte, 0, stream.data.size())
	end_byte = clampi(end_byte, 0, stream.data.size())

	var before := stream.data.slice(0, start_byte)
	var after := stream.data.slice(end_byte)

	var new_data := PackedByteArray()
	new_data.append_array(before)
	new_data.append_array(after)

	var result := AudioStreamWAV.new()
	result.data = new_data
	result.format = stream.format
	result.mix_rate = stream.mix_rate
	result.stereo = stream.stereo
	return result


## Return a new AudioStreamWAV with `duration` seconds of silence inserted
## at `insert_time`.
static func insert_silence(stream: AudioStreamWAV, insert_time: float, duration: float) -> AudioStreamWAV:
	if stream == null:
		return null

	var fs := _frame_size(stream)
	var bps_rate := _bytes_per_second(stream)

	var insert_byte := _align(int(insert_time * bps_rate), fs)
	insert_byte = clampi(insert_byte, 0, stream.data.size())

	var silence_bytes := _align(int(duration * bps_rate), fs)

	var before := stream.data.slice(0, insert_byte)
	var silence := PackedByteArray()
	silence.resize(silence_bytes)
	silence.fill(0)
	var after := stream.data.slice(insert_byte)

	var new_data := PackedByteArray()
	new_data.append_array(before)
	new_data.append_array(silence)
	new_data.append_array(after)

	var result := AudioStreamWAV.new()
	result.data = new_data
	result.format = stream.format
	result.mix_rate = stream.mix_rate
	result.stereo = stream.stereo
	return result


## Concatenate two AudioStreamWAV streams sequentially.
static func combine_streams(a: AudioStreamWAV, b: AudioStreamWAV) -> AudioStreamWAV:
	if a == null:
		return b
	if b == null:
		return a

	var new_data := PackedByteArray()
	new_data.append_array(a.data)
	new_data.append_array(b.data)

	var result := AudioStreamWAV.new()
	result.data = new_data
	result.format = a.format
	result.mix_rate = a.mix_rate
	result.stereo = a.stereo
	return result


# ══════════════════════════════════════════════════════════════════════════════
#  PRIVATE  –  Internal helpers
# ══════════════════════════════════════════════════════════════════════════════

## Mix helper — returns mixed stream, or the recording alone when voice_over is null.
static func _mix_or_fallback(recording: AudioStreamWAV, voice_over: AudioStreamWAV) -> AudioStreamWAV:
	if voice_over != null and voice_over.data.size() > 0:
		return mix_streams(recording, voice_over)
	return recording


## Bytes per single sample frame (all channels).
static func _frame_size(stream: AudioStreamWAV) -> int:
	var bps := 2 if stream.format == _WAV_FORMAT_16BIT else 1
	var ch := 2 if stream.stereo else 1
	return bps * ch


## Bytes per second of audio.
static func _bytes_per_second(stream: AudioStreamWAV) -> int:
	return stream.mix_rate * _frame_size(stream)


## Round `value` DOWN to the nearest multiple of `alignment`.
static func _align(value: int, alignment: int) -> int:
	if alignment <= 0:
		return value
	@warning_ignore("integer_division")
	return (value / alignment) * alignment


## Promote an 8-bit AudioStreamWAV to 16-bit so mixing always works in 16-bit.
static func _ensure_16bit(stream: AudioStreamWAV) -> AudioStreamWAV:
	if stream.format == _WAV_FORMAT_16BIT:
		return stream

	# 8-bit unsigned → 16-bit signed
	var src := stream.data
	var dst := PackedByteArray()
	dst.resize(src.size() * 2)
	for i in src.size():
		var sample_16: int = (src[i] - 128) * 256
		dst.encode_s16(i * 2, sample_16)

	var result := AudioStreamWAV.new()
	result.data = dst
	result.format = AudioStreamWAV.FORMAT_16_BITS
	result.mix_rate = stream.mix_rate
	result.stereo = stream.stereo
	return result
