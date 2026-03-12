extends Node

## Coordinates voice-over recording, playback, and waveform visualization
## for a single synth slot. Delegates recording to VoiceRecorder and
## waveform drawing to WaveformVisualizer.

# Which synth slot this voice-over node controls (0 = green, 1 = purple)
@export var synth_index: int = 0

# UI References
@export var texture_progress_bar: TextureProgressBar
@export var record_layer_button: Button
@export var small_line: Line2D
@export var big_line: Line2D
@export var big_line_base_dist: int = 280
@export var big_line_volume_dist: int = 28
@export var big_line_reversed: bool = false

var bpm_up_button: Button
var bpm_down_button: Button

# Sub-components
var recorder: VoiceRecorder
var waveform: WaveformVisualizer

# Progress bar state
var should_update_progress_bar: bool = false

# Audio delay measurement
var should_measure_audio_delay: bool = false
var audio_delay_begin_ms: int = 0
var audio_delay_end_ms: int = 0
var audio_delay_total_seconds: float = 0.0

# Backward-compatible accessors — external code reads these directly
var recording: bool:
	get: return recorder.recording if recorder else false
var should_record: bool:
	get: return recorder.should_record if recorder else false
var finished: bool:
	get: return recorder.finished if recorder else false

# References
var gameManager: Node
var bpmManager: Node
var layerManager: Node
var songVoiceOver: Node
var uiManager: Node
var audioPlayerManager: Node


func _ready():
	gameManager = %GameManager
	bpmManager = %BpmManager
	layerManager = %LayerManager
	songVoiceOver = %SongVoiceOver
	uiManager = %UiManager
	audioPlayerManager = %AudioPlayerManager
	bpm_up_button = uiManager.bpm_up_button
	bpm_down_button = uiManager.bpm_down_button

	# Initialize sub-components
	recorder = VoiceRecorder.new(get_tree(), func(): return uiManager.recording_delay_slider.value, %MicrophoneCapture)
	recorder.recording_started.connect(_on_recording_started)
	recorder.recording_stopped.connect(_on_recording_stopped)

	waveform = WaveformVisualizer.new(small_line, big_line, big_line_base_dist, big_line_volume_dist, big_line_reversed)

	# Set up record button
	if record_layer_button:
		record_layer_button.pressed.connect(_on_record_button_pressed)

	EventBus.play_pause_toggled.connect(_on_play_pause_pressed)

	# Initial waveform draw
	waveform.update_lines(get_current_layer_voice_over())


func _process(_delta: float):
	# Measure audio delay if needed
	if should_measure_audio_delay and audioPlayerManager.get_voice_playback_position(synth_index) > 0:
		audio_delay_end_ms = Time.get_ticks_msec()
		audio_delay_total_seconds = float(audio_delay_end_ms - audio_delay_begin_ms) / 1000.0
		print("⚠️ audio delay is: " + str(audio_delay_total_seconds).pad_zeros(5))
		should_measure_audio_delay = false

	# Update progress bar
	if bpmManager:
		var current_beat = bpmManager.current_beat
		var beat_timer = bpmManager.beat_timer
		var time_per_beat = bpmManager.time_per_beat
		var beats_amount = bpmManager.beats_amount

		var progress = float(current_beat + (beat_timer / time_per_beat)) / beats_amount

		if should_update_progress_bar and texture_progress_bar:
			texture_progress_bar.value = progress
		elif texture_progress_bar:
			texture_progress_bar.value = 0.0


# -- Record button handling ---------------------------------------------------

func _on_record_button_pressed():
	if not recording and not should_record:
		# Arm recording
		uiManager.layer_loop_toggle.button_pressed = false
		recorder.arm()
		_toggle_buttons(false)

		EventBus.countdown_show_requested.emit()

		# Start playback with metronome
		bpmManager.current_beat = 0
		bpmManager.playing = true
		audioPlayerManager.play_sfx(audioPlayerManager.metronome_sfx)

		recorder.start()

	elif not recording and should_record:
		# Cancel armed recording
		recorder.cancel()
		_toggle_buttons(true)
		EventBus.countdown_close_requested.emit()


# -- Recorder signal handlers -------------------------------------------------

func _on_recording_started():
	should_update_progress_bar = true
	if big_line:
		big_line.visible = false
	EventBus.countdown_close_requested.emit()
	EventBus.recording_started.emit()


func _on_recording_stopped(recorded_audio: AudioStream):
	should_update_progress_bar = false
	if big_line:
		big_line.visible = true
	_toggle_buttons(true)

	if recorded_audio:
		set_current_layer_voice_over(recorded_audio)
	waveform.update_lines(get_current_layer_voice_over())
	EventBus.recording_stopped.emit(recorded_audio)


# -- Play / pause -------------------------------------------------------------

func _on_play_pause_pressed():
	var current_audio = get_current_layer_voice_over()
	if current_audio:
		if audioPlayerManager.is_voice_playing(synth_index):
			audioPlayerManager.stop_voice(synth_index)
		else:
			audioPlayerManager.play_voice(synth_index)


# -- Layer data access ---------------------------------------------------------

func get_current_layer_index() -> int:
	return layerManager.current_layer_index


func set_current_layer_voice_over(voice_over: AudioStream):
	var current_index = get_current_layer_index()
	if current_index >= 0 and current_index < layerManager.layers.size():
		var layer: LayerData = layerManager.layers[current_index]
		if synth_index < layer.synths.size():
			layer.synths[synth_index].layer_voice_over = voice_over

		audioPlayerManager.set_voice_stream(synth_index, voice_over)
		audioPlayerManager.stop_voice(synth_index)
		audioPlayerManager.play_voice(synth_index)


func get_current_layer_voice_over() -> AudioStream:
	var current_index = get_current_layer_index()
	if current_index >= 0 and current_index < layerManager.layers.size():
		var layer: LayerData = layerManager.layers[current_index]
		if synth_index < layer.synths.size():
			return layer.synths[synth_index].layer_voice_over
	return null


# -- Loop top handling ---------------------------------------------------------

func on_top():
	if should_record and not recording:
		recorder.start()
	elif recording:
		recorder.stop()

	if not recording:
		audioPlayerManager.set_voice_stream(synth_index, get_current_layer_voice_over())
		should_measure_audio_delay = true
		audio_delay_begin_ms = Time.get_ticks_msec()

	on_top_delayed()


func on_top_delayed():
	if audioPlayerManager.is_voice_playing(synth_index):
		audioPlayerManager.stop_voice(synth_index)

	if not recording:
		audioPlayerManager.play_voice(synth_index)


# -- UI helpers ----------------------------------------------------------------

func _toggle_buttons(enabled: bool):
	bpm_up_button.disabled = not enabled
	bpm_down_button.disabled = not enabled
	uiManager.play_pause_button.disabled = not enabled
	uiManager.metronome_toggle.disabled = not enabled
