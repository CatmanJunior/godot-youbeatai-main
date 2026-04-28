class_name RecordingData
extends Resource

## Data class encapsulating a recorded audio stream and the TrackData it belongs to.
## Provides lazy-cached analysis utilities: PCM extraction, RMS/volume, FFT/spectrum,
## and waveform visualization helpers. Tracks recording state and section context.

enum State { NOT_STARTED, RECORDING, PROCESSING, RECORDING_DONE }

const Fft = preload("res://addons/fft/Fft.gd")

const DEFAULT_FFT_SIZE := 2048
const MAX_FFT_SIZE := 8192
const SILENCE_THRESHOLD := 0.01

@export var state: State = State.NOT_STARTED
@export var has_detected_sound: bool = false
@export var section_index: int = -1
## Back-reference to the owning TrackData. Not exported to avoid circular refs.
## Re-linked by TrackData after load via its recording_data setter.
@export var max_recording_length: float = 0.0
@export var actual_recording_length: float = 0.0
@export var length_since_detected_sound: float = 0.0
@export var audio_stream: AudioStreamWAV:
	set(value):
		audio_stream = value
		_invalidate_all()

var track_data: TrackData
var track_type: TrackData.TrackType:
	get():
		return track_data.track_type


# --- Lazy caches ---
var _samples_cache: PackedFloat32Array = []
var _samples_cached: bool = false

var _rms_cache: float = -1.0

var _spectrum_cache: Array = []
var _spectrum_cached: bool = false

var _magnitudes_cache: PackedFloat32Array = []
var _magnitudes_cached: bool = false

var _waveform_cache: PackedVector2Array = []
var _waveform_cache_resolution: int = -1


func _init(p_track_data: TrackData = null, p_audio_stream: AudioStreamWAV = null) -> void:
	track_data = p_track_data
	if p_track_data != null:
		section_index = p_track_data.section_index
	if p_audio_stream:
		audio_stream = p_audio_stream


# --- Cache invalidation ---

func _invalidate_all() -> void:
	_samples_cache = []
	_samples_cached = false
	_rms_cache = -1.0
	_spectrum_cache = []
	_spectrum_cached = false
	_magnitudes_cache = []
	_magnitudes_cached = false
	_waveform_cache = []
	_waveform_cache_resolution = -1


# =========================================================
# PCM extraction
# =========================================================

## Returns PCM samples as floats in [-1, 1]. Supports 8-bit/16-bit, mono/stereo.
func get_samples(downsample_factor: int = 1) -> PackedFloat32Array:
	if downsample_factor == 1 and _samples_cached:
		return _samples_cache

	if audio_stream == null or audio_stream.data.size() == 0:
		return PackedFloat32Array()

	var raw := audio_stream.data
	var channels := 2 if audio_stream.stereo else 1
	var is_16bit := audio_stream.format == AudioStreamWAV.FORMAT_16_BITS
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
			if i + 1 >= total_bytes:
				break
			value = raw.decode_s16(i) / 32768.0
		else:
			var v := raw[i] as int
			value = (v - 256 if v > 127 else v) / 128.0
		samples[out] = value
		out += 1
		i += byte_step
	samples.resize(out)

	if downsample_factor == 1:
		_samples_cache = samples
		_samples_cached = true

	return samples


func get_sample_count() -> int:
	return get_samples().size()


func get_sample_rate() -> float:
	if audio_stream == null:
		return 0.0
	return float(audio_stream.mix_rate)


func get_duration() -> float:
	if audio_stream == null:
		return 0.0
	return audio_stream.get_length()

func get_recording_progress() -> float:
	return actual_recording_length / max_recording_length if max_recording_length > 0 else 0.0
	

# =========================================================
# Volume / RMS
# =========================================================

## Pure static utility — usable without an instance.
static func compute_rms(chunk: PackedFloat32Array) -> float:
	if chunk.size() == 0:
		return 0.0
	var sum := 0.0
	for s in chunk:
		sum += s * s
	return sqrt(sum / chunk.size())


## Overall RMS of the entire recording (cached).
func get_rms_volume() -> float:
	if _rms_cache >= 0.0:
		return _rms_cache
	_rms_cache = compute_rms(get_samples())
	return _rms_cache


## RMS of a specific time range [start_time, end_time] in seconds.
func get_rms_volume_at_range(start_time: float, end_time: float) -> float:
	var rate := get_sample_rate()
	if rate == 0.0:
		return 0.0
	var samples := get_samples()
	var start_idx := int(start_time * rate)
	var end_idx := int(end_time * rate)
	start_idx = clampi(start_idx, 0, samples.size())
	end_idx = clampi(end_idx, 0, samples.size())
	if start_idx >= end_idx:
		return 0.0
	return compute_rms(samples.slice(start_idx, end_idx))


## Peak absolute amplitude across the entire recording.
func get_peak_volume() -> float:
	var samples := get_samples()
	var peak := 0.0
	for s in samples:
		var a : float = abs(s)
		if a > peak:
			peak = a
	return peak


## dB relative to full scale (-80 for silence).
func get_volume_db() -> float:
	var rms := get_rms_volume()
	if rms < 0.00001:
		return -80.0
	return 20.0 * log(rms) / log(10.0)


## Returns true when the overall RMS is below SILENCE_THRESHOLD.
func is_silent() -> bool:
	return get_rms_volume() < SILENCE_THRESHOLD


## Array of per-window RMS values across the full recording.
func get_volume_envelope(window_count: int = 64) -> PackedFloat32Array:
	var samples := get_samples()
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


# =========================================================
# FFT / Spectrum
# =========================================================

## Full FFT spectrum of the entire recording (cached).
func get_spectrum() -> Array:
	if _spectrum_cached:
		return _spectrum_cache
	_spectrum_cache = _compute_full_spectrum()
	_spectrum_cached = true
	return _spectrum_cache


## Positive-frequency magnitudes from the cached spectrum (cached).
func get_spectrum_magnitudes() -> PackedFloat32Array:
	if _magnitudes_cached:
		return _magnitudes_cache
	var samples := get_samples()
	_magnitudes_cache = _compute_magnitudes(samples)
	_magnitudes_cached = true
	return _magnitudes_cache


## Dominant frequency across the entire recording.
func get_dominant_frequency() -> float:
	var samples := get_samples()
	return _dominant_frequency_from_chunk(samples, get_sample_rate())


## Dominant frequency within a specific time range.
func get_dominant_frequency_at_range(start_time: float, end_time: float) -> float:
	var rate := get_sample_rate()
	if rate == 0.0:
		return 0.0
	var samples := get_samples()
	var start_idx := clampi(int(start_time * rate), 0, samples.size())
	var end_idx := clampi(int(end_time * rate), 0, samples.size())
	if start_idx >= end_idx:
		return 0.0
	return _dominant_frequency_from_chunk(samples.slice(start_idx, end_idx), rate)


## Positive-frequency magnitudes for a specific time range.
func get_spectrum_magnitudes_at_range(start_time: float, end_time: float) -> PackedFloat32Array:
	var rate := get_sample_rate()
	if rate == 0.0:
		return PackedFloat32Array()
	var samples := get_samples()
	var start_idx := clampi(int(start_time * rate), 0, samples.size())
	var end_idx := clampi(int(end_time * rate), 0, samples.size())
	if start_idx >= end_idx:
		return PackedFloat32Array()
	return _compute_magnitudes(samples.slice(start_idx, end_idx))


## Per-beat analysis: returns PackedVector3Array of Vector3(freq, vol, time).
## Silent beats get freq = -1.
func get_per_beat_analysis(beat_count: int) -> PackedVector3Array:
	var samples := get_samples()
	var rate := get_sample_rate()
	if samples.size() == 0 or beat_count <= 0:
		return PackedVector3Array()

	@warning_ignore("integer_division")
	var samples_per_beat := samples.size() / beat_count
	if samples_per_beat == 0:
		return PackedVector3Array()

	var beat_duration := get_duration() / float(beat_count)
	var result := PackedVector3Array()

	for i in range(beat_count):
		var start_idx := i * samples_per_beat
		var end_idx := mini((i + 1) * samples_per_beat, samples.size())
		var chunk := samples.slice(start_idx, end_idx)
		var vol := compute_rms(chunk)
		var time := float(i) * beat_duration

		if vol < SILENCE_THRESHOLD:
			result.push_back(Vector3(-1.0, 0.0, time))
		else:
			var freq := _dominant_frequency_from_chunk(chunk, rate)
			result.push_back(Vector3(freq, vol, time))

	return result


# --- Private FFT helpers ---

func _compute_full_spectrum() -> Array:
	var samples := get_samples()
	if samples.size() == 0:
		return []
	var n := mini(_next_power_of_2(samples.size()), MAX_FFT_SIZE)
	var fft_input: Array = []
	fft_input.resize(n)
	var step := float(samples.size()) / float(n)
	for i in range(n):
		fft_input[i] = float(samples[int(i * step)])
	return Fft.fft(fft_input)


func _compute_magnitudes(chunk: PackedFloat32Array) -> PackedFloat32Array:
	if chunk.size() == 0:
		return PackedFloat32Array()
	var n := mini(_next_power_of_2(chunk.size()), MAX_FFT_SIZE)
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


func _dominant_frequency_from_chunk(chunk: PackedFloat32Array, rate: float) -> float:
	if chunk.size() == 0 or rate == 0.0:
		return 0.0
	var n := mini(_next_power_of_2(chunk.size()), MAX_FFT_SIZE)
	var fft_input: Array = []
	fft_input.resize(n)
	var step := float(chunk.size()) / float(n)
	for i in range(n):
		fft_input[i] = float(chunk[int(i * step)])
	var spectrum: Array = Fft.fft(fft_input)
	@warning_ignore("integer_division")
	var half := n / 2
	var max_mag := 0.0
	var max_bin := 0
	for i in range(1, half):
		var re: float = spectrum[i].re
		var im: float = spectrum[i].im
		var mag := sqrt(re * re + im * im)
		if mag > max_mag:
			max_mag = mag
			max_bin = i
	return float(max_bin) * rate / float(n)


func _next_power_of_2(n: int) -> int:
	var p := 1
	while p < n:
		p *= 2
	return p


# =========================================================
# Waveform visualization
# =========================================================

## Points suitable for a Line2D, x in [0,1], y in [-1,1].
func get_waveform_points(resolution: int = 128) -> PackedVector2Array:
	if _waveform_cache_resolution == resolution and _waveform_cache.size() > 0:
		return _waveform_cache

	var samples := get_samples()
	if samples.size() == 0:
		return PackedVector2Array()

	@warning_ignore("integer_division")
	var window := samples.size() / resolution
	if window == 0:
		window = 1

	var pts := PackedVector2Array()
	pts.resize(resolution)
	for i in range(resolution):
		var start := i * window
		var end := mini(start + window, samples.size())
		var chunk := samples.slice(start, end)
		var avg := 0.0
		for s in chunk:
			avg += s
		avg /= float(chunk.size())
		pts[i] = Vector2(float(i) / float(max(resolution - 1, 1)), avg)

	_waveform_cache = pts
	_waveform_cache_resolution = resolution
	return pts


## Circular waveform offsets for Line2D drawing, replicating SynthWaveform logic
## but operating from cached PCM samples.
func get_circular_waveform_offsets(point_count: int, base_dist: int, volume_dist: int, reversed: bool) -> PackedVector2Array:
	var samples := get_samples()
	var rate := get_sample_rate()
	var length := get_duration()

	var offsets := PackedVector2Array()
	offsets.resize(point_count)

	for i in range(point_count):
		var volume_offset := 0.0
		if samples.size() > 0 and length > 0.0:
			var percentage := float(i) / float(point_count)
			var sample_idx := int(percentage * length * rate)
			sample_idx = clampi(sample_idx, 0, samples.size() - 1)
			volume_offset = abs(samples[sample_idx]) * volume_dist

		var angle := -PI / 2.0 + TAU * float(i) / float(point_count)
		var final_dist := (base_dist - volume_offset) if reversed else (base_dist + volume_offset)
		offsets[i] = Vector2(cos(angle), sin(angle)) * final_dist

	return offsets


## Min/max per window for DAW-style waveform bars.
func get_waveform_minmax(resolution: int = 128) -> Array[Vector2]:
	var samples := get_samples()
	if samples.size() == 0:
		return []

	@warning_ignore("integer_division")
	var window := samples.size() / resolution
	if window == 0:
		window = 1

	var result: Array[Vector2] = []
	result.resize(resolution)
	for i in range(resolution):
		var start := i * window
		var end := mini(start + window, samples.size())
		var mn := samples[start]
		var mx := samples[start]
		for j in range(start + 1, end):
			if samples[j] < mn:
				mn = samples[j]
			if samples[j] > mx:
				mx = samples[j]
		result[i] = Vector2(mn, mx)
	return result


# =========================================================
# Duplication
# =========================================================

## Returns a new RecordingData with the same state, section context, and a
## deep-copied AudioStreamWAV so the clone is fully independent.
## The caller is responsible for assigning the correct TrackData reference if
## it differs from the original (e.g. when attaching to a different track).
func duplicate_data(p_track_data: TrackData = null) -> RecordingData:
	var target_track: TrackData = p_track_data if p_track_data != null else track_data
	var copy := RecordingData.new(target_track)
	copy.state = state
	copy.has_detected_sound = has_detected_sound
	copy.section_index = section_index
	copy.max_recording_length = max_recording_length
	copy.actual_recording_length = actual_recording_length
	copy.length_since_detected_sound = length_since_detected_sound
	if audio_stream != null:
		var wav := AudioStreamWAV.new()
		wav.data = audio_stream.data.duplicate()
		wav.format = audio_stream.format
		wav.loop_mode = audio_stream.loop_mode
		wav.loop_begin = audio_stream.loop_begin
		wav.loop_end = audio_stream.loop_end
		wav.mix_rate = audio_stream.mix_rate
		wav.stereo = audio_stream.stereo
		copy.audio_stream = wav
	return copy
