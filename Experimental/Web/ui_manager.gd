extends Node

# Switch layer buttons
@export var layer_button_prefab: PackedScene
@export var layer_buttons_container: HBoxContainer
@export var add_layer_button: Button
@export var clear_layer_button: Button
@export var save_layer_button: Button
@export var remove_layer_button: Button
@export var load_layer_button: Button


@export var play_pause_button: Button
@export var bpm_up_button: Button
@export var bpm_down_button: Button

# Song button
@export var song_select_button: Button

# Sample buttons (Sprite2D in C#, but might be buttons in Godot)
@export var instrument_buttons: Array[Sprite2D] = []
@export var record_sample_button0: Node
@export var record_sample_button1: Node
@export var record_sample_button2: Node
@export var record_sample_button3: Node

# Other interface elements
@export var corners: Array[Node2D] = []
@export var chaos_pad_triangle_sprite: Sprite2D
@export var nodes_that_can_be_unlocked: Array[Node2D] = []
@export var restart_button: Button
@export var mute_speach: CheckButton
@export var save_to_wav_button: Button
@export var cross: Node2D
@export var chosen_emoticons_label: Label
@export var metronome_toggle: CheckButton
@export var mic_meter: ProgressBar
@export var add_beats: CheckButton
@export var button_is_clap: CheckButton
@export var button_add_beats: CheckButton
@export var volume_threshold: Slider
@export var recording_delay_slider: Slider
@export var recording_delay_label: Label
@export var settings_panel: Panel
@export var settings_button: Button
@export var settings_back_button: Button
@export var skip_tutorial_button: Button
@export var progress_bar: ProgressBar
@export var pointer: Sprite2D
@export var metronome: Sprite2D
@export var metronome_bg: Sprite2D
@export var bpm_label: Label
@export var draganddropthing: Sprite2D
@export var swing_slider: Slider
@export var swing_label: Label
@export var clap_bias_slider: Slider
@export var achievements_panel: Panel
@export var layer_loop_toggle: CheckButton
@export var saving_label: Label
@export var instruction_label: Label
@export var all_layers_to_mp3: Button
@export var layer_outline: Sprite2D
@export var layer_outline_holder: Node2D
@export var real_time_audio_recording_progress_bar: ProgressBar
@export var activate_green_chaos_button: Sprite2D
@export var activate_purple_chaos_button: Sprite2D
@export var copy_paste_clear_buttons_holder: Node2D
@export var continue_button: Button
@export var klappy_continue: Button
@export var knob_area: Area2D
@export var amount_left: Label
@export var green_layer_record_button: Sprite2D
@export var bear_ring_pivot_point: Node2D

# Sprite/texture management
@export var sprite_prefab: PackedScene
@export var filled_beat_textures: Array[Texture2D]
@export var outline_beat_textures: Array[Texture2D]
@export var dotted_synth_textures: Array[Texture2D]
@export var outline_synth_textures: Array[Texture2D]
@export var filled_song_texture: Texture2D
@export var outline_song_texture: Texture2D
@export var dot_beat_texture: Texture2D

var colors: PackedColorArray
var colors_override: PackedColorArray = []
var beat_sprites: Array = [] # 2D array [ring][beat]
var template_sprites: Array = [] # 2D array [ring][beat]

# Beat sprite scale factors
var global_beat_sprite_scale_factor: float = 0.28
var beat_scale_32: float = 1.0
var beat_scale_16: float = 1.6
var beat_scale_8: float = 1.6

# State variables
var interface_set_to_default_state: bool = false
var saving_label_active: bool = false
var saving_label_timer: float = 0.0
var progress_bar_value: float = 25.0
var email_prompt_open: bool = false
var dragginganddropping: bool = false
var holding_for_ring: int = 0
var slow_beat_timer: float = 0.0
var copy_paste_clear_button_holder_time_since_activation: float = 0.0
var pressed_add_layer_once: bool = false
var added_layer: bool = false

var original_instrument_button_scales: Array[float] = []

enum ChaosPadMode {None, SampleMixing, SynthMixing}
var chaos_pad_mode = ChaosPadMode.None

# References to other managers
var layer_manager: Node

var emoji_buttons: Array = []
var emoji_prompt_cancel_button: Button

func _ready():
	colors = %Colors.colors.duplicate()
	colors_override = colors.duplicate()
	
	_instrument_buttons_default_scale()

	layer_manager = %LayerManager

	EventBus.layer_changed.connect(_on_switch_layer)

	init_button_actions()
	initialize_sprite_positions()
	

func _instrument_buttons_default_scale():
	original_instrument_button_scales = []
	for btn in instrument_buttons:
		original_instrument_button_scales.append(btn.scale.x)

func _process(delta: float) -> void:
	update_ui(delta)

func update_ui(delta: float):
	_update_interface_state()
	_update_saving_label(delta)
	_update_play_pause_button()
	_update_pointer()
	_update_metronome(delta)
	_update_ring_button_outlines()
	_update_synth_button_outlines()
	_update_progress_bar()
	_update_labels()
	_update_drag_and_drop()
	_update_mic_meter()
	_update_beat_sprites(delta)
	_update_layer_outline_sprite_rotation()
	_update_copy_paste_buttons(delta)


func init_button_actions():
	# Emoji buttons
	for button in emoji_buttons:
		button.button_up.connect(func():
			var current_layer_index = layer_manager.current_layer_index
			add_layer(current_layer_index + 1, button.text)
			close_emoji_prompt()
			added_layer = true
		)
	
	#TODO: Fix this
	# emoji_prompt_cancel_button.button_up.connect(close_emoji_prompt)
	
	# Save/export buttons
	all_layers_to_mp3.button_up.connect(func():
		_export_song_wav()
		settings_panel.visible = false
	)
	
	save_to_wav_button.pressed.connect(func():
		_export_beat_wav()
		settings_panel.visible = false
	)
	
	mute_speach.pressed.connect(DisplayServer.tts_stop)
	
	load_layer_button.pressed.connect(func():
		_paste_layer()
		_play_extra_sfx()
	)

	# Layer buttons
	save_layer_button.pressed.connect(func():
		_copy_layer()
		_play_extra_sfx()
	)
	
	clear_layer_button.pressed.connect(func():
		# Open confirmation prompt
		_clear_layer()
		_play_extra_sfx()
	)
	
	# Add layer button
	add_layer_button.button_up.connect(func():
		open_emoji_prompt()
		_play_extra_sfx()
		
		if not pressed_add_layer_once:
			# Show tooltip
			pressed_add_layer_once = true
	)
	
	# Restart button
	restart_button.pressed.connect(_on_restart_button)
	
	# Play/Pause button
	play_pause_button.button_up.connect(_on_play_pause)
	
	# BPM buttons
	bpm_up_button.pressed.connect(_on_bpm_up)
	bpm_down_button.pressed.connect(_on_bpm_down)
	
	# Tutorial skip
	skip_tutorial_button.pressed.connect(func():
		# Tutorial.tutorial_level = -1
		set_entire_interface_visibility(true)
		achievements_panel.visible = false
		if DisplayServer.tts_is_speaking():
			DisplayServer.tts_stop()
	)
	
	# Settings buttons
	settings_button.pressed.connect(func():
		settings_panel.visible = !settings_panel.visible
	)
	
	settings_back_button.pressed.connect(func():
		settings_panel.visible = !settings_panel.visible
	)
	
	# Song select button
	song_select_button.button_up.connect(func():
		layer_loop_toggle.button_pressed = !layer_loop_toggle.button_pressed
		# song_mixing_change_to_song_mixer()
	)
		
func initialize_sprite_positions():
	var beats_amount = %BpmManager.beats_amount
	
	# Spawn beat sprites
	beat_sprites = []
	for ring in range(4):
		beat_sprites.append([])
		for beat in range(beats_amount):
			var sprite = create_sprite(beat, ring, beats_amount)
			bear_ring_pivot_point.add_child(sprite)
			beat_sprites[ring].append(sprite)
	
	# Spawn template sprites
	template_sprites = []
	for ring in range(4):
		template_sprites.append([])
		for beat in range(beats_amount):
			var sprite = create_template_sprite(beat, ring, beats_amount)
			bear_ring_pivot_point.add_child(sprite)
			template_sprites[ring].append(sprite)
	
	# Set initial colors and positions
	activate_green_chaos_button.self_modulate = colors[4]
	activate_purple_chaos_button.self_modulate = colors[5]
	
	var green_back = activate_green_chaos_button.find_child("BackSprite") as Sprite2D
	green_back.self_modulate = colors[4]
	
	var purple_back = activate_purple_chaos_button.find_child("BackSprite") as Sprite2D
	purple_back.self_modulate = colors[5]

func sprite_position(beat: int, ring: int, beats_amount: int) -> Vector2:
	var angle = PI * 2.0 * beat / beats_amount - PI / 2.0
	var distance = 0.0
	
	if beats_amount == 32:
		distance = (4 - ring) * 30 + 110
	elif beats_amount == 16:
		distance = (4 - ring) * 45 + 56
	elif beats_amount == 8:
		distance = (4 - ring) * 45 + 56
	
	return Vector2(cos(angle), sin(angle)) * distance

func sprite_rotation(beat: int, _ring: int, beats_amount: int) -> float:
	return PI * 2.0 * beat / beats_amount

func create_sprite(beat: int, ring: int, beats_amount: int) -> Sprite2D:
	var sprite = sprite_prefab.instantiate() as Sprite2D
	sprite.position = sprite_position(beat, ring, beats_amount)
	sprite.rotation = sprite_rotation(beat, ring, beats_amount)
	
	sprite.set_sprite_index(beat)
	sprite.set_ring(ring)
	
	var scale_factor = 1.0
	if beats_amount == 32:
		scale_factor = beat_scale_32
	elif beats_amount == 16:
		scale_factor = beat_scale_16
	elif beats_amount == 8:
		scale_factor = beat_scale_8
	
	sprite.scale = Vector2.ONE * scale_factor * global_beat_sprite_scale_factor
	
	if ring < filled_beat_textures.size():
		sprite.texture = filled_beat_textures[ring]
	
	return sprite

func create_template_sprite(beat: int, ring: int, beats_amount: int) -> Sprite2D:
	var sprite = Sprite2D.new()
	sprite.position = sprite_position(beat, ring, beats_amount)
	sprite.rotation = sprite_rotation(beat, ring, beats_amount)
	sprite.texture = dot_beat_texture
	sprite.modulate = Color(0, 0, 0, 1)
	return sprite

func _update_beat_sprites(delta: float):
	# Update instrument button sprite scale
	for i in range(instrument_buttons.size()):
		if instrument_buttons[i].scale.x > original_instrument_button_scales[i]:
			instrument_buttons[i].scale -= Vector2.ONE * delta * 2
	
	var beats_amount = %BpmManager.beats_amount
	var current_beat = %BpmManager.current_beat
	
	# Update beat sprites

	for ring in range(min(4, beat_sprites.size())):
		for beat in range(min(beats_amount, beat_sprites[ring].size())):
			var sprite = beat_sprites[ring][beat] as Sprite2D
			
			var active = get_beat_active(ring, beat)
			
			if ring < filled_beat_textures.size() and ring < outline_beat_textures.size():
				sprite.texture = filled_beat_textures[ring] if active else outline_beat_textures[ring]
			
			var color = Color(1, 1, 1, 1)
			if beat == current_beat and active:
				color = color.lightened(0.75)
			sprite.modulate = color
			
			var scale_factor = 1.0
			if beats_amount == 32:
				scale_factor = beat_scale_32
			elif beats_amount == 16:
				scale_factor = beat_scale_16
			elif beats_amount == 8:
				scale_factor = beat_scale_8
			
			if sprite.scale.x > scale_factor * global_beat_sprite_scale_factor:
				sprite.scale -= Vector2.ONE * delta * 0.3
	
	# Update template sprites
	var show_template = false # Get from template manager
	for ring in range(min(4, template_sprites.size())):
		for beat in range(min(beats_amount, template_sprites[ring].size())):
			var sprite = template_sprites[ring][beat] as Sprite2D
			
			var template_active = get_template_active(ring, beat)
			sprite.modulate = Color(0, 0, 0, 0)
			if template_active and show_template:
				sprite.modulate = Color(0, 0, 0, 1)

func _update_layer_outline_sprite_rotation():
	var time_per_beat = %BpmManager.time_per_beat
	var current_beat = %BpmManager.current_beat
	var beat_timer = %BpmManager.beat_timer
	var beats_amount = %BpmManager.beats_amount
	
	var clock_rot = 0.0
	if time_per_beat != 0:
		clock_rot = float(current_beat + (beat_timer / time_per_beat)) / float(beats_amount)
	else:
		clock_rot = float(current_beat) / float(beats_amount)
	
	layer_outline.rotation_degrees = clock_rot * 360.0 - 7.0

func _update_copy_paste_buttons(delta: float):
	#TODO handle showing/hiding copy/paste/clear buttons when layer buttons are pressed, and hiding them after a few seconds of inactivity
	var any_layer_button_pressed = false
	
	if copy_paste_clear_button_holder_time_since_activation >= 3.5:
		set_copy_paste_clear_buttons_active(false)
	elif not any_layer_button_pressed:
		copy_paste_clear_button_holder_time_since_activation += delta

func update_layer_switch_buttons_colors():
	# Get layer buttons from layer manager
	var layer_buttons = []
	layer_buttons = layer_manager.layer_buttons
	
	for i in range(layer_buttons.size()):
		var button = layer_buttons[i]
		
		button.modulate = Color(1, 1, 1, 1)
		
		# Check if layer has beats
		var has_beats = layer_has_beats(i)
		if not has_beats:
			button.modulate = button.modulate.darkened(0.5)

func _update_interface_state():
	if not interface_set_to_default_state:
		set_entire_interface_visibility(true)
		achievements_panel.visible = false
		interface_set_to_default_state = true

func show_saving_label(path: String) -> void:
	if saving_label:
		saving_label.text = "Saved to: " + path.get_file()
		saving_label_active = true
		saving_label_timer = 0.0

func _update_saving_label(delta: float):
	if saving_label_active and saving_label_timer < 4:
		saving_label_timer += delta
	else:
		saving_label_active = false
	saving_label.visible = saving_label_active

# ── Audio export helpers ──────────────────────────────────────────────────────

func _export_song_wav() -> void:
	var recording: AudioStreamWAV = %RealTimeAudioRecording.recording_result
	var voice_over: AudioStreamWAV = %SongVoiceOver.voice_over
	var bpm: int = %BpmManager.bpm

	var path: String = AudioSavingManager.save_realtime_recorded_song_as_file(
		recording, voice_over, bpm)
	if path != "":
		show_saving_label(path)

func _export_beat_wav() -> void:
	var recording: AudioStreamWAV = %RealTimeAudioRecording.recording_result
	var voice_over: AudioStreamWAV = %SongVoiceOver.voice_over
	var bpm: int = %BpmManager.bpm
	var layer_index: int = %LayerManager.current_layer_index
	var beats_amount: int = %BpmManager.beats_amount
	var base_time_per_beat: float = %BpmManager.base_time_per_beat

	var path: String = AudioSavingManager.save_realtime_recorded_beat_as_file(
		recording, voice_over, bpm, layer_index, beats_amount, base_time_per_beat)
	if path != "":
		show_saving_label(path)

func _update_play_pause_button():
	play_pause_button.text = "⏸️" if %BpmManager.playing else "▶️"

func _update_pointer():
	if %BpmManager.playing:
		var progression = float(%BpmManager.current_beat + (%BpmManager.beat_timer / %BpmManager.time_per_beat)) / float(%BpmManager.beats_amount)
		pointer.rotation_degrees = progression * 360.0 - 7.0

func _update_metronome(delta: float):
	if %BpmManager.playing:
		slow_beat_timer += delta / 4.0
		if slow_beat_timer > %BpmManager.time_per_beat:
			slow_beat_timer -= %BpmManager.time_per_beat
		var beat_progress = slow_beat_timer / %BpmManager.time_per_beat
		metronome.position.y = lerp(-0.4, 0.4, beat_progress)

func _update_ring_button_outlines():
	var outlines: Array[Sprite2D] = []
	for btn in instrument_buttons:
		outlines.append(btn.find_child("OutlineSprite") as Sprite2D)
	
	if chaos_pad_mode == ChaosPadMode.SampleMixing:
		var mixing_manager = get_parent().get_node("MixingManager")
		var active_ring = mixing_manager.samples_mixing_active_ring
		for i in range(4):
			outlines[i].texture = filled_beat_textures[i] if active_ring == i else outline_beat_textures[i]
	else:
		for i in range(4):
			outlines[i].texture = outline_beat_textures[i]

func _update_synth_button_outlines():
	var progression = float(%BpmManager.current_beat + (%BpmManager.beat_timer / %BpmManager.time_per_beat)) / float(%BpmManager.beats_amount)
	if is_nan(progression):
		progression = 0.0
	
	var green_back = activate_green_chaos_button.find_child("BackSprite") as Sprite2D
	var green_outline = activate_green_chaos_button.find_child("OutlineSprite") as Sprite2D
	var purple_back = activate_purple_chaos_button.find_child("BackSprite") as Sprite2D
	var purple_outline = activate_purple_chaos_button.find_child("OutlineSprite") as Sprite2D
	
	if chaos_pad_mode == ChaosPadMode.SynthMixing:
		var mixing_manager = get_parent().get_node("MixingManager")
		var active_synth = mixing_manager.synth_mixing_active_synth
		
		if active_synth == 0 and outline_synth_textures.size() > 0:
			green_back.visible = true
			green_outline.texture = outline_synth_textures[0]
			green_outline.rotation_degrees = progression * 360.0 + 30.0
		else:
			green_back.visible = false
			if dotted_synth_textures.size() > 0:
				green_outline.texture = dotted_synth_textures[0]
		
		if active_synth == 1 and outline_synth_textures.size() > 1:
			purple_back.visible = true
			purple_outline.texture = outline_synth_textures[1]
			purple_outline.rotation_degrees = progression * 360.0 + 30.0
		else:
			purple_back.visible = false
			if dotted_synth_textures.size() > 1:
				purple_outline.texture = dotted_synth_textures[1]
	else:
		green_back.visible = false
		purple_back.visible = false
		if dotted_synth_textures.size() > 0:
			green_outline.texture = dotted_synth_textures[0]
		if dotted_synth_textures.size() > 1:
			purple_outline.texture = dotted_synth_textures[1]
		green_outline.rotation_degrees = 30.0
		purple_outline.rotation_degrees = 30.0

func _update_progress_bar():
	progress_bar_value = clamp(progress_bar_value, 0.0, 100.0)
	progress_bar.value = progress_bar_value

func _update_labels():
	bpm_label.text = str(%BpmManager.bpm)
	recording_delay_label.text = "%.2fs" % recording_delay_slider.value
	%BpmManager.swing = swing_slider.value
	real_time_audio_recording_progress_bar.visible = layer_loop_toggle.button_pressed

func _update_drag_and_drop():
	if dragginganddropping and holding_for_ring < colors.size():
		draganddropthing.modulate = colors[holding_for_ring]
		draganddropthing.position = get_viewport().get_mouse_position() - Vector2(1280, 720) / 2.0
	else:
		draganddropthing.modulate = Color(1, 1, 1, 0)

func _update_mic_meter():
		mic_meter.value = %MicrophoneCapture.volume

func update_layer_buttons_delayed():
	# Implementation - update layer button UI
	pass

func set_entire_interface_visibility(visible: bool):
	# Show/hide all interface elements
	if nodes_that_can_be_unlocked.size() == 0:
		return
	for node in nodes_that_can_be_unlocked:
		node.visible = visible

func set_copy_paste_clear_buttons_active(active: bool):
	copy_paste_clear_buttons_holder.visible = active
	if active:
		copy_paste_clear_buttons_holder.position = Vector2.ZERO
	else:
		copy_paste_clear_buttons_holder.position += Vector2(0, 20000)
	copy_paste_clear_button_holder_time_since_activation = 0

# Helper methods that need implementation from other managers
func get_beat_active(ring: int, beat: int) -> bool:
	return %BeatManager.get_beat(ring, beat)

func get_template_active(ring: int, beat: int) -> bool:
	var current_actives = %TemplateManager.get_current_actives()
	if ring >= 0 and ring < current_actives.size():
		var row = current_actives[ring]
		if beat >= 0 and beat < row.size():
			return row[beat]
	return false

func layer_has_beats(layer_index: int) -> bool:
	# Check if layer has any beats
	return layer_manager.layer_has_beats(layer_index)

func add_layer(index: int, emoji: String):
	EventBus.layer_added.emit(index, emoji)

func open_emoji_prompt():
	# Show emoji selection prompt
	pass

func close_emoji_prompt():
	# Hide emoji selection prompt
	pass

func _copy_layer():
	# Save current layer state via EventBus
	EventBus.copy_requested.emit()

func _paste_layer():
	# Restore saved layer state via EventBus
	EventBus.paste_requested.emit()

func _clear_layer():
	# Clear current layer via EventBus
	EventBus.layer_clear_requested.emit()

func _play_extra_sfx():
	# Play UI sound effect
	pass


#signal handlers
func _on_switch_layer(_layer_index: int, _new_layer_beats: Array):
	update_layer_switch_buttons_colors()
	set_copy_paste_clear_buttons_active(true)
	print("Layer switched to index: " + str(_layer_index))
	# Reset beat sprite scales so the new layer's visuals refresh immediately
	var beats_amount = %BpmManager.beats_amount
	for ring in range(min(4, beat_sprites.size())):
		for beat in range(min(beats_amount, beat_sprites[ring].size())):
			var sprite = beat_sprites[ring][beat] as Sprite2D
			var scale_factor = 1.0
			if beats_amount == 32:
				scale_factor = beat_scale_32
			elif beats_amount == 16:
				scale_factor = beat_scale_16
			elif beats_amount == 8:
				scale_factor = beat_scale_8
			sprite.scale = Vector2.ONE * scale_factor * global_beat_sprite_scale_factor

func _on_restart_button():
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
	
	var user_path = ProjectSettings.globalize_path("user://")
	var files_to_reset = [
		user_path + "/chosen_emoticons.json",
		user_path + "/chosen_soundbank.json",
		user_path + "/beats_amount.txt",
		user_path + "/use_tutorial.txt",
		user_path + "/use_achievements.txt"
	]
	
	for file_path in files_to_reset:
		if FileAccess.file_exists(file_path):
			DirAccess.remove_absolute(file_path)

func _on_bpm_up():
	EventBus.bpm_up_requested.emit(5)

func _on_bpm_down():
	EventBus.bpm_down_requested.emit(5)

func _on_play_pause():
	if not play_pause_button.disabled:
		EventBus.play_pause_toggled.emit()

func _on_enter_pressed():
	pass
