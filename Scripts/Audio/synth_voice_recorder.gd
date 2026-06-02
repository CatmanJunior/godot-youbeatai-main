extends Node

## Handles the voice analysis pipeline for SYNTH track recordings.
## Listens to EventBus.recording_started / recording_stopped and emits
## EventBus.sequence_ready when pitch analysis is complete.
## Add this as a sibling of TrackRecorder under Managers/AudioManagers.

## Maximum NSDF hops processed per _process() frame to keep frame time bounded.
## At ANALYSIS_RATE=11025 / HOP_SIZE=512 each hop ~46 ms of audio, so 2 hops/frame
## keeps up with real-time at any frame rate >= ~22 Hz while leaving slack for
## render work. Backlog drains naturally; finalize() processes any tail in one go.
const MAX_HOPS_PER_FRAME: int = 2

var _voice_analyzer: VoiceAnalyzer = null
var _audio_capture: AudioEffectCapture = null
var _mic_bus_index: int = -1

func _ready() -> void:
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
	# On Web, AudioEffectCapture delivers samples at the browser input AudioContext
	# rate (not the engine's mix rate). Use input_mix_rate so the downsampler is
	# correctly calibrated; falls back to mix rate on desktop/mobile.
	var sample_rate := float(AudioServer.get_mix_rate())
	if OS.has_feature("web"):
		sample_rate = float(AudioServer.get_input_mix_rate())
	_voice_analyzer.start(sample_rate, SongState.beats_per_section, SongState.beat_duration)
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
	_voice_analyzer.push_samples(mono, MAX_HOPS_PER_FRAME)

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

func _stereo_to_mono(stereo: PackedVector2Array) -> PackedFloat32Array:
	var mono := PackedFloat32Array()
	mono.resize(stereo.size())
	for i in range(stereo.size()):
		mono[i] = (stereo[i].x + stereo[i].y) * 0.5
	return mono
