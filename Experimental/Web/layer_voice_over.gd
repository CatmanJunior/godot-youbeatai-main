extends Node

# Signals for recording state
signal started_recording
signal stopped_recording

# Storage of all layer recordings (ground truth)
var layers_voice_overs: Array[AudioStream] = []

# UI References
@export var texture_progress_bar: TextureProgressBar
@export var record_layer_button: Button
var bpm_up_button: Button
var bpm_down_button: Button

# Volume visualization lines
@export var small_line: Line2D
@export var big_line: Line2D
@export var big_line_base_dist: int = 280
@export var big_line_volume_dist: int = 28
@export var big_line_reversed: bool = false

# Recording state
var audio_player: AudioStreamPlayer
var audio_player_alt: AudioStreamPlayer
var should_record: bool = false
var recording: bool = false
var should_update_progress_bar: bool = false
var finished: bool = false
var recording_timer: float = 0.0

# Audio recording
var audio_effect_record: AudioEffectRecord
var should_measure_audio_delay: bool = false
var audio_delay_begin_ms: int = 0
var audio_delay_end_ms: int = 0
var audio_delay_total_seconds: float = 0.0

# State tracking
var should_update_lines: bool = false

# References to other managers
var game_manager: Node
var bpm_manager: Node
var layer_manager: Node
var song_voice_over: Node
var is_green_layer: bool = false # true for green, false for purple

func _ready():
	game_manager = %GameManager
	bpm_manager = %BpmManager
	layer_manager = %LayerManager
	song_voice_over = get_node_or_null("/root/SongVoiceOver")

	bpm_up_button = %UiManager.bpm_up_button
	bpm_down_button = %UiManager.bpm_down_button

	# Set up record button
	if record_layer_button:
		record_layer_button.pressed.connect(_on_record_button_pressed)
	
	# Create audio players
	audio_player = AudioStreamPlayer.new()
	audio_player_alt = AudioStreamPlayer.new()
	audio_player.stream = AudioStreamMicrophone.new()
	add_child(audio_player)
	add_child(audio_player_alt)
	
	# Set audio bus based on which layer this is
	if is_green_layer:
		audio_player.bus = "GreenVoice"
		audio_player_alt.bus = "Green_alt"
	else:
		audio_player.bus = "PurpleVoice"
		audio_player_alt.bus = "Purple_alt"
	
	# Setup recording effect
	var microphone_bus_index = AudioServer.get_bus_index("Microphone")
	if microphone_bus_index >= 0:
		audio_effect_record = AudioServer.get_bus_effect(microphone_bus_index, 1)
	
	# Setup play/pause button
	if game_manager:
		var play_pause_button = game_manager.get_node_or_null("%PlayPauseButton")
		if play_pause_button:
			play_pause_button.pressed.connect(_on_play_pause_pressed)
	
	# Setup volume lines
	if small_line:
		set_small_volume_line()
	if big_line:
		set_big_volume_line()

func _process(delta: float):
	# Measure audio delay if needed
	if should_measure_audio_delay and audio_player.get_playback_position() > 0:
		audio_delay_end_ms = Time.get_ticks_msec()
		audio_delay_total_seconds = float(audio_delay_end_ms - audio_delay_begin_ms) / 1000.0
		print("⚠️ audio delay is: " + str(audio_delay_total_seconds).pad_zeros(5))
		should_measure_audio_delay = false
	
	# Update recording timer
	if recording:
		recording_timer += delta
	else:
		recording_timer = 0.0
	
	# Update progress bar
	if bpm_manager:
		var current_beat = bpm_manager.current_beat
		var beat_timer = bpm_manager.beat_timer
		var time_per_beat = bpm_manager.time_per_beat
		var beats_amount = bpm_manager.beats_amount
		
		var progress = float(current_beat + (beat_timer / time_per_beat)) / beats_amount
		
		if should_update_progress_bar and texture_progress_bar:
			texture_progress_bar.value = progress
		elif texture_progress_bar:
			texture_progress_bar.value = 0.0
	
	# Update volume lines
	if should_update_lines:
		set_small_volume_line()
		set_big_volume_line()
		should_update_lines = false

func _on_record_button_pressed():
	"""Handle record button press"""
	if not recording and not should_record:
		# Start recording session
		if game_manager:
			game_manager.layer_loop_toggle.button_pressed = false
		
		should_record = true
		
		# Disable buttons during recording
		if bpm_up_button:
			bpm_up_button.disabled = true
		if bpm_down_button:
			bpm_down_button.disabled = true
		if game_manager:
			game_manager.set_layer_switch_buttons_enabled(false)
			game_manager.play_pause_button.disabled = true
			if game_manager.has_method("show_count_down"):
				game_manager.show_count_down()
		if song_voice_over:
			song_voice_over.record_song_button.disabled = true
		
		# Enable metronome and start playback
		if game_manager:
			game_manager.metronome_toggle.button_pressed = true
		if bpm_manager:
			bpm_manager.current_beat = 0
			bpm_manager.playing = true
		
		# Play metronome sound
		if game_manager and game_manager.has_method("play_extra_sfx"):
			game_manager.play_extra_sfx(game_manager.metronome_sfx)
	
	elif not recording and should_record:
		# Cancel recording
		should_record = false
		
		# Re-enable buttons
		if bpm_up_button:
			bpm_up_button.disabled = false
		if bpm_down_button:
			bpm_down_button.disabled = false
		if game_manager:
			game_manager.set_layer_switch_buttons_enabled(true)
			game_manager.play_pause_button.disabled = false
			game_manager.metronome_toggle.button_pressed = false
			if game_manager.has_method("close_count_down"):
				game_manager.close_count_down()
		if song_voice_over:
			song_voice_over.record_song_button.disabled = false

func _on_play_pause_pressed():
	"""Handle play/pause button"""
	if layers_voice_overs.size() > get_current_layer_index():
		var current_audio = layers_voice_overs[get_current_layer_index()]
		if current_audio:
			if audio_player.playing:
				audio_player.stop()
				audio_player_alt.stop()
			else:
				audio_player.play()
				audio_player_alt.play()

func get_current_layer_index() -> int:
	"""Get current layer index from layer manager"""
	return layer_manager.current_layer_index

func set_current_layer_voice_over(voice_over: AudioStream):
	"""Set the current layer's voice over"""
	var current_index = get_current_layer_index()
	if current_index < layers_voice_overs.size():
		layers_voice_overs[current_index] = voice_over
		
		audio_player.stream = get_current_layer_voice_over()
		audio_player.stop()
		audio_player.play()
		should_update_lines = true

func get_current_layer_voice_over() -> AudioStream:
	"""Get the current layer's voice over"""
	var current_index = get_current_layer_index()
	if current_index < layers_voice_overs.size():
		return layers_voice_overs[current_index]
	return null

func on_top():
	"""Called when this layer comes to the top in playback"""
	if should_record and not recording:
		start_recording()
	elif recording:
		stop_recording()
	
	if not recording:
		audio_player_alt.stream = get_current_layer_voice_over()
		audio_player.stream = get_current_layer_voice_over()
		
		should_measure_audio_delay = true
		audio_delay_begin_ms = Time.get_ticks_msec()
	
	on_top_delayed()

func on_top_delayed():
	"""Delayed processing when layer comes to top"""
	if audio_player.playing:
		audio_player.stop()
		audio_player_alt.stop()
	
	if not recording:
		audio_player.play()
		audio_player_alt.play()

func start_recording():
	"""Start the recording process"""
	if game_manager:
		game_manager.metronome_toggle.button_pressed = false
	
	var delay = 0.5
	if game_manager and game_manager.has("recording_delay_slider"):
		delay = game_manager.recording_delay_slider.value
	
	await get_tree().create_timer(delay).timeout
	do_recording()
	
	# Reduce submix volume
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SubMaster"), linear_to_db(0.1))
	
	if game_manager and game_manager.has_method("close_count_down"):
		game_manager.close_count_down()

func do_recording():
	"""Actually start recording"""
	should_update_progress_bar = true
	if big_line:
		big_line.visible = false
	recording = true
	if audio_effect_record:
		audio_effect_record.set_recording_active(true)
	print("recording started")
	started_recording.emit()

func do_stop_recording():
	"""Actually stop recording"""
	if audio_effect_record:
		audio_effect_record.set_recording_active(false)
		set_current_layer_voice_over(audio_effect_record.get_recording())
	
	print("recording stopped")
	recording = false
	should_record = false
	finished = true
	should_update_lines = true
	
	if game_manager and game_manager.has("recording_delay_slider"):
		print(str(game_manager.recording_delay_slider.value) + " seconds delay")
	
	stopped_recording.emit()

func stop_recording():
	"""Stop recording (with delay)"""
	should_update_progress_bar = false
	if big_line:
		big_line.visible = true
	
	var delay = 0.5
	if game_manager and game_manager.has("recording_delay_slider"):
		delay = game_manager.recording_delay_slider.value
	
	await get_tree().create_timer(delay).timeout
	do_stop_recording()
	
	# Re-enable buttons
	if bpm_up_button:
		bpm_up_button.disabled = false
	if bpm_down_button:
		bpm_down_button.disabled = false
	if game_manager:
		game_manager.set_layer_switch_buttons_enabled(true)
		game_manager.play_pause_button.disabled = false
		game_manager.metronome_toggle.button_pressed = false
	if song_voice_over:
		song_voice_over.record_song_button.disabled = false
	
	# Restore submix volume
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SubMaster"), 0.0)

func set_volume_line(line: Line2D, audio: AudioStream, points: int, base_dist: int, volume_dist: int, reversed: bool = false):
	"""Set volume visualization line"""
	if not line:
		return
	
	var offsets = _calculate_volume_offsets(audio, points, base_dist, volume_dist, reversed)
	
	line.clear_points()
	for offset in offsets:
		line.add_point(offset)

func _calculate_volume_offsets(_audio: AudioStream, points: int, base_dist: int, volume_dist: int, reversed: bool) -> Array:
	"""Calculate volume offsets for visualization"""
	var offsets = []
	var current_index = get_current_layer_index()
	
	for i in range(points):
		var volume_offset = 0.0
		
		if current_index < layers_voice_overs.size() and layers_voice_overs[current_index]:
			var audio_stream = layers_voice_overs[current_index]
			if audio_stream is AudioStreamWAV:
				var length = audio_stream.get_length()
				var percentage = float(i) / points
				var volume = get_volume_at_time(audio_stream, percentage * length)
				volume_offset = volume * volume_dist
		
		var angle = - PI / 2.0 + TAU * i / points
		var final_dist = base_dist - volume_offset if reversed else base_dist + volume_offset
		
		var offset = Vector2(cos(angle), sin(angle)) * final_dist
		offsets.append(offset)
	
	return offsets

func set_small_volume_line():
	"""Set small volume visualization line"""
	set_volume_line(small_line, get_current_layer_voice_over(), 40, 15, 15)

func set_big_volume_line():
	"""Set big volume visualization line"""
	set_volume_line(big_line, get_current_layer_voice_over(), 100, big_line_base_dist, big_line_volume_dist, big_line_reversed)

func get_volume_at_time(audio: AudioStreamWAV, time: float) -> float:
	"""Get volume at a specific time in the audio"""
	if not audio or audio.data.size() == 0:
		push_error("Invalid audio stream")
		return 0.0
	
	var sample_rate = audio.mix_rate
	var channels = 2 if audio.stereo else 1
	var format_size = 2 if audio.format == AudioStreamWAV.FORMAT_16_BITS else 1
	
	var sample_index = int(time * sample_rate) * channels
	var byte_index = sample_index * format_size
	
	if byte_index >= audio.data.size() - format_size:
		push_error("Time exceeds sample length")
		return 0.0
	
	# Read sample based on format
	var volume = 0.0
	if audio.format == AudioStreamWAV.FORMAT_16_BITS:
		# Read 16-bit sample
		var bytes = audio.data.slice(byte_index, byte_index + 2)
		var value = bytes.decode_s16(0)
		volume = abs(value / 32768.0)
	else:
		# Read 8-bit sample
		var value = audio.data[byte_index] as int
		if value > 127:
			value -= 256
		volume = abs(value / 128.0)
	
	return volume
