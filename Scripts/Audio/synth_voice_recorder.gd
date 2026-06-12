extends Node

## Handles the voice analysis pipeline for SYNTH track recordings.
## Listens to EventBus.recording_started / recording_stopped and emits
## EventBus.sequence_ready when pitch analysis is complete.
## Add this as a sibling of TrackRecorder under Managers/AudioManagers.

## Maximum NSDF hops processed per _process() frame to keep frame time bounded.
## At ANALYSIS_RATE=11025 / HOP_SIZE=512 each hop ~46 ms of audio, so 2 hops/frame
## keeps up with real-time at any frame rate >= ~22 Hz while leaving slack for
## render work. Backlog can also drain after recording when processing is deferred.
const MAX_HOPS_PER_FRAME: int = 2

const NOTES: Notes = preload("res://Experimental/VoiceToSynth/notes.tres")

## When true, use the offline FFT-based VoiceProcessor (processes once on stop).
## When false, use the streaming NSDF-based VoiceAnalyzer.
@export var use_voice_processor: bool = false

## When true, analyze microphone samples while recording. When false, capture
## during recording and spread all VoiceAnalyzer work over frames after stop.
@export var process_during_recording: bool = true

## Maximum VoiceAnalyzer hops processed per frame after recording stops.
@export var post_stop_hops_per_frame: int = MAX_HOPS_PER_FRAME

var _voice_analyzer: VoiceAnalyzer = null
var _audio_capture: AudioEffectCapture = null
var _mic_bus_index: int = -1
var _post_stop_processing_active: bool = false
var _pending_recording_data: RecordingData = null

func _ready() -> void:
	EventBus.recording_started.connect(_on_recording_started)
	EventBus.recording_stopped.connect(_on_recording_stopped)
	_init_audio_capture()

func _process(_delta: float) -> void:
	if _post_stop_processing_active:
		_continue_post_stop_processing()
		return
	if use_voice_processor:
		return
	if _voice_analyzer and _voice_analyzer.is_active() and _audio_capture:
		_feed_voice_analyzer()

# ── Event Handlers ────────────────────────────────────────────────────────────

func _on_recording_started(recording_data: RecordingData) -> void:
	if recording_data.track_type != TrackData.TrackType.SYNTH:
		return
	if use_voice_processor:
		return
	if _post_stop_processing_active:
		_complete_post_stop_processing()
	_start_voice_analyzer()

func _on_recording_stopped(recording_data: RecordingData) -> void:
	if recording_data.track_type != TrackData.TrackType.SYNTH:
		return
	if use_voice_processor:
		_run_voice_processor(recording_data)
		return
	_finalize_voice_analysis(recording_data)

# ── Voice Processor (offline) ────────────────────────────────────────────────

func _run_voice_processor(recording_data: RecordingData) -> void:
	var sequence: Sequence = VoiceProcessor.process_audio(recording_data.audio_stream, NOTES)
	if sequence == null:
		sequence = Sequence.new([])
	EventBus.sequence_ready.emit(sequence, recording_data.track_data)

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
		print("SynthVoiceRecorder: Detected web platform, using input mix rate of %d Hz for voice analysis." % int(sample_rate))
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
	var max_hops: int = MAX_HOPS_PER_FRAME if process_during_recording else 0
	_voice_analyzer.push_samples(mono, max_hops)

func _finalize_voice_analysis(recording_data: RecordingData) -> void:
	if _voice_analyzer and _voice_analyzer.is_active():
		var drain_hops: int = -1 if process_during_recording else 0
		_drain_audio_capture(drain_hops)
		if not process_during_recording:
			_start_post_stop_processing(recording_data)
			return
		var sequence: Sequence = _voice_analyzer.finalize()
		_emit_sequence_ready(sequence, recording_data)
	else:
		var sequence := Sequence.new([])
		_emit_sequence_ready(sequence, recording_data)


func _drain_audio_capture(max_hops: int) -> void:
	if _audio_capture == null or _voice_analyzer == null:
		return
	var remaining := _audio_capture.get_frames_available()
	if remaining > 0:
		var buf := _audio_capture.get_buffer(remaining)
		var mono := _stereo_to_mono(buf)
		_voice_analyzer.push_samples(mono, max_hops)
	_audio_capture.clear_buffer()


func _start_post_stop_processing(recording_data: RecordingData) -> void:
	_pending_recording_data = recording_data
	_post_stop_processing_active = true
	_voice_analyzer.begin_staged_finalize()
	_set_microphone_capture_enabled(false)


func _continue_post_stop_processing() -> void:
	if _voice_analyzer == null or _pending_recording_data == null:
		var sequence := Sequence.new([])
		_emit_sequence_ready(sequence, _pending_recording_data)
		return
	var done := _voice_analyzer.process_finalize_step(post_stop_hops_per_frame)
	if done:
		_complete_post_stop_processing()


func _complete_post_stop_processing() -> void:
	if _voice_analyzer == null or _pending_recording_data == null:
		_cleanup_voice_analyzer()
		return
	while _voice_analyzer.is_staged_finalizing():
		_voice_analyzer.process_finalize_step()
	var sequence: Sequence = _voice_analyzer.get_staged_sequence()
	_emit_sequence_ready(sequence, _pending_recording_data)


func _emit_sequence_ready(sequence: Sequence, recording_data: RecordingData) -> void:
	if recording_data != null:
		EventBus.sequence_ready.emit(sequence, recording_data.track_data)
	_cleanup_voice_analyzer()


func _cleanup_voice_analyzer() -> void:
	_voice_analyzer = null
	_pending_recording_data = null
	_post_stop_processing_active = false
	_set_microphone_capture_enabled(false)


func _set_microphone_capture_enabled(enabled: bool) -> void:
	if _mic_bus_index >= 0:
		AudioServer.set_bus_effect_enabled(_mic_bus_index, 0, enabled)

func _stereo_to_mono(stereo: PackedVector2Array) -> PackedFloat32Array:
	var mono := PackedFloat32Array()
	mono.resize(stereo.size())
	for i in range(stereo.size()):
		mono[i] = (stereo[i].x + stereo[i].y) * 0.5
	return mono
