extends Node

## Handles the voice analysis pipeline for SYNTH track recordings.
## Listens to EventBus.recording_started / recording_stopped and emits
## EventBus.sequence_ready when pitch analysis is complete.
## Add this as a sibling of TrackRecorder under Managers/AudioManagers.

var _voice_analyzer: VoiceAnalyzer = null
var _audio_capture: AudioEffectCapture = null
var _mic_bus_index: int = -1

# Web-only sample-rate calibration. On HTML5 the rate AudioServer.get_mix_rate()
# reports can differ from the real rate at which the browser's mic worklet
# delivers frames; that disagreement is what makes recordings sound pitched
# up. We measure the actual rate from the number of frames pushed in the
# first ~250 ms of capture and re-tell the analyzer the true source rate.
var _is_web: bool = false
var _capture_start_msec: int = -1
var _frames_pushed: int = 0
var _rate_calibrated: bool = false
const _CALIBRATION_MIN_MSEC: int = 250
const _MIN_PLAUSIBLE_RATE: float = 8000.0
const _MAX_PLAUSIBLE_RATE: float = 96000.0

func _ready() -> void:
	_is_web = OS.has_feature("web")
	EventBus.recording_started.connect(_on_recording_started)
	EventBus.recording_stopped.connect(_on_recording_stopped)
	_init_audio_capture()

func _process(_delta: float) -> void:
	if _voice_analyzer and _voice_analyzer.is_active() and _audio_capture:
		_feed_voice_analyzer()

# ── Event Handlers ────────────────────────────────────────────────────────────

func _on_recording_started(recording_data: RecordingData) -> void:
	if recording_data.track_type != TrackData.TrackType.SYNTH:
		return
	_start_voice_analyzer()

func _on_recording_stopped(recording_data: RecordingData) -> void:
	if recording_data.track_type != TrackData.TrackType.SYNTH:
		return
	_finalize_voice_analysis(recording_data)

# ── Voice Analyzer ────────────────────────────────────────────────────────────

func _init_audio_capture() -> void:
	_mic_bus_index = AudioServer.get_bus_index(BusNames.MICROPHONE_BUS)
	if _mic_bus_index < 0:
		push_warning("SynthVoiceRecorder: Microphone bus not found.")
		return
	var effect := AudioServer.get_bus_effect(_mic_bus_index, 0)
	if effect is AudioEffectCapture:
		_audio_capture = effect as AudioEffectCapture
	else:
		push_warning("SynthVoiceRecorder: AudioEffectCapture not found at index 0 on Microphone bus.")

func _start_voice_analyzer() -> void:
	_voice_analyzer = VoiceAnalyzer.new()
	var sample_rate := float(AudioServer.get_mix_rate())
	_voice_analyzer.start(sample_rate, SongState.beats_per_section, SongState.beat_duration)
	_capture_start_msec = Time.get_ticks_msec()
	_frames_pushed = 0
	_rate_calibrated = false
	if _audio_capture:
		AudioServer.set_bus_effect_enabled(_mic_bus_index, 0, true)
		_audio_capture.clear_buffer()
	else:
		push_warning("SynthVoiceRecorder: No AudioEffectCapture available for streaming voice analysis.")

func _feed_voice_analyzer() -> void:
	if _audio_capture == null or _voice_analyzer == null:
		return
	var frames_available := _audio_capture.get_frames_available()
	if frames_available <= 0:
		return
	var stereo_buf := _audio_capture.get_buffer(frames_available)
	var mono := _stereo_to_mono(stereo_buf)
	_voice_analyzer.push_samples(mono)
	_frames_pushed += mono.size()
	_maybe_calibrate_source_rate()

# On web, after we've seen at least ~250 ms of mic data, recompute the actual
# rate the browser is feeding us (frames pushed / wall-clock elapsed) and
# tell the analyzer if it differs meaningfully from AudioServer.get_mix_rate().
# Done once per recording. No-op on non-web targets, where AudioServer's
# reported rate matches the driver exactly.
func _maybe_calibrate_source_rate() -> void:
	if _rate_calibrated or not _is_web or _voice_analyzer == null:
		return
	if _capture_start_msec < 0 or _frames_pushed <= 0:
		return
	var elapsed_msec: int = Time.get_ticks_msec() - _capture_start_msec
	if elapsed_msec < _CALIBRATION_MIN_MSEC:
		return
	var measured_rate: float = float(_frames_pushed) / (float(elapsed_msec) / 1000.0)
	if measured_rate < _MIN_PLAUSIBLE_RATE or measured_rate > _MAX_PLAUSIBLE_RATE:
		_rate_calibrated = true
		return
	var reported_rate: float = float(AudioServer.get_mix_rate())
	# Only correct if the discrepancy is large enough to matter (>1%).
	if absf(measured_rate - reported_rate) / reported_rate > 0.01:
		print("SynthVoiceRecorder: recalibrating analyzer source rate from %.1f to %.1f Hz"
			% [reported_rate, measured_rate])
		_voice_analyzer.update_source_rate(measured_rate)
	_rate_calibrated = true

func _finalize_voice_analysis(recording_data: RecordingData) -> void:
	if _voice_analyzer and _voice_analyzer.is_active():
		if _audio_capture:
			var remaining := _audio_capture.get_frames_available()
			if remaining > 0:
				var buf := _audio_capture.get_buffer(remaining)
				var mono := _stereo_to_mono(buf)
				_voice_analyzer.push_samples(mono)
			_audio_capture.clear_buffer()
		var sequence: Sequence = _voice_analyzer.finalize()
		_voice_analyzer = null
		EventBus.sequence_ready.emit(sequence, recording_data.track_data)
	else:
		var sequence := Sequence.new([])
		EventBus.sequence_ready.emit(sequence, recording_data.track_data)
	if _mic_bus_index >= 0:
		AudioServer.set_bus_effect_enabled(_mic_bus_index, 0, false)
	_capture_start_msec = -1
	_frames_pushed = 0
	_rate_calibrated = false

func _stereo_to_mono(stereo: PackedVector2Array) -> PackedFloat32Array:
	var mono := PackedFloat32Array()
	mono.resize(stereo.size())
	for i in range(stereo.size()):
		mono[i] = (stereo[i].x + stereo[i].y) * 0.5
	return mono
