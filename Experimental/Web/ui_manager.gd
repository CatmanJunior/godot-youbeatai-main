extends Node

# Switch layer buttons
@export var layer_button_prefab: PackedScene
@export var layer_buttons_container: HBoxContainer
@export var add_layer_button: Button

# Left buttons
@export var save_layout_button: Button
@export var load_layout_button: Button
@export var clear_layout_button: Button
@export var play_pause_button: Button
@export var bpm_up_button: Button
@export var bpm_down_button: Button

# Song button
@export var song_select_button: Button

# Sample buttons (Sprite2D in C#, but might be buttons in Godot)
@export var draganddrop_button0: Sprite2D
@export var draganddrop_button1: Sprite2D
@export var draganddrop_button2: Sprite2D
@export var draganddrop_button3: Sprite2D
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

var original_draganddrop_button0_scale: float
var original_draganddrop_button1_scale: float
var original_draganddrop_button2_scale: float
var original_draganddrop_button3_scale: float

enum ChaosPadMode {None, SampleMixing, SynthMixing}
var chaos_pad_mode = ChaosPadMode.None

# References to other managers
var layer_manager: Node

var emoji_buttons: Array = []
var emoji_prompt_cancel_button: Button

# Signals
signal layer_added(index: int, emoji: String)

func _ready():
	print("Colors at _ready: ", colors)
	colors = %Colors.colors.duplicate()
	colors_override = colors.duplicate()
	
	_instrument_buttons_default_scale()

	layer_manager = %LayerManager
	var keyboard = %KeyboardInput
	# Connect keyboard signals
	keyboard.bpm_up_pressed.connect(_on_bpm_up)
	keyboard.bpm_down_pressed.connect(_on_bpm_down)
	keyboard.play_pause_pressed.connect(_on_play_pause)
	keyboard.enter_pressed.connect(_on_enter_pressed)

func _instrument_buttons_default_scale():
	original_draganddrop_button0_scale = draganddrop_button0.scale.x
	original_draganddrop_button1_scale = draganddrop_button1.scale.x
	original_draganddrop_button2_scale = draganddrop_button2.scale.x
	original_draganddrop_button3_scale = draganddrop_button3.scale.x

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
			var current_layer_index = 0 # Get from layer manager
			add_layer(current_layer_index + 1, button.text)
			close_emoji_prompt()
			added_layer = true
		)
	
	if emoji_prompt_cancel_button:
		emoji_prompt_cancel_button.button_up.connect(close_emoji_prompt)
	
	# Save/export buttons
	if all_layers_to_mp3:
		all_layers_to_mp3.button_up.connect(func():
			#TODO: Export all layers to mp3
			if settings_panel:
				settings_panel.visible = false
		)
	
	if save_to_wav_button:
		save_to_wav_button.pressed.connect(func():
			#TODO: Open save to wav prompt
			if settings_panel:
				settings_panel.visible = false
		)
	
	if mute_speach:
		mute_speach.pressed.connect(DisplayServer.tts_stop)
	
	# Layout buttons
	if save_layout_button:
		save_layout_button.pressed.connect(func():
			copy_layer()
			play_extra_sfx()
		)
	
	if load_layout_button:
		load_layout_button.pressed.connect(func():
			paste_layer()
			play_extra_sfx()
		)
	
	if clear_layout_button:
		clear_layout_button.pressed.connect(func():
			# Open confirmation prompt
			clear_layer()
			play_extra_sfx()
		)
	
	# Add layer button
	if add_layer_button:
		add_layer_button.button_up.connect(func():
			open_emoji_prompt()
			play_extra_sfx()
			
			if not pressed_add_layer_once:
				# Show tooltip
				pressed_add_layer_once = true
		)
	
	# Restart button
	if restart_button:
		restart_button.pressed.connect(_on_restart_button)
	
	# Play/Pause button
	if play_pause_button:
		play_pause_button.button_up.connect(_on_play_pause)
	
	# BPM buttons
	if bpm_up_button:
		bpm_up_button.pressed.connect(_on_bpm_up)
	if bpm_down_button:
		bpm_down_button.pressed.connect(_on_bpm_down)
	
	# Tutorial skip
	if skip_tutorial_button:
		skip_tutorial_button.pressed.connect(func():
			# Tutorial.tutorial_level = -1
			set_entire_interface_visibility(true)
			if achievements_panel:
				achievements_panel.visible = false
			if DisplayServer.tts_is_speaking():
				DisplayServer.tts_stop()
		)
	
	# Settings buttons
	if settings_button:
		settings_button.pressed.connect(func():
			if settings_panel:
				settings_panel.visible = !settings_panel.visible
		)
	
	if settings_back_button:
		settings_back_button.pressed.connect(func():
			if settings_panel:
				settings_panel.visible = !settings_panel.visible
		)
	
	# Song select button
	if song_select_button:
		song_select_button.button_up.connect(func():
			if layer_loop_toggle:
				layer_loop_toggle.button_pressed = !layer_loop_toggle.button_pressed
			# song_mixing_change_to_song_mixer()
		)
		
func sprite_placement():
	if not bear_ring_pivot_point:
		push_warning("bear_ring_pivot_point not assigned")
		return
	
	var beats_amount = 16 # Get from BpmManager
	if %BpmManager:
		beats_amount = %BpmManager.beats_amount
	
	# Spawn beat sprites
	beat_sprites = []
	for ring in range(4):
		beat_sprites.append([])
		for beat in range(beats_amount):
			var sprite = create_sprite(beat, ring, beats_amount)
			if sprite and bear_ring_pivot_point:
				bear_ring_pivot_point.add_child(sprite)
				beat_sprites[ring].append(sprite)
	
	# Spawn template sprites
	template_sprites = []
	for ring in range(4):
		template_sprites.append([])
		for beat in range(beats_amount):
			var sprite = create_template_sprite(beat, ring, beats_amount)
			if sprite and bear_ring_pivot_point:
				bear_ring_pivot_point.add_child(sprite)
				template_sprites[ring].append(sprite)
	
	# Set initial colors and positions
	if activate_green_chaos_button and colors.size() > 4:
		activate_green_chaos_button.self_modulate = colors[4]
	if activate_purple_chaos_button and colors.size() > 5:
		activate_purple_chaos_button.self_modulate = colors[5]
	
	if activate_green_chaos_button:
		var green_back = activate_green_chaos_button.find_child("BackSprite") as Sprite2D
		if green_back and colors.size() > 4:
			green_back.self_modulate = colors[4]
	
	if activate_purple_chaos_button:
		var purple_back = activate_purple_chaos_button.find_child("BackSprite") as Sprite2D
		if purple_back and colors.size() > 5:
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
	if not sprite_prefab:
		return null
	
	var sprite = sprite_prefab.instantiate() as Sprite2D
	if not sprite:
		return null
	
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
	# Update drag and drop button sprite scale
	if draganddrop_button0 and draganddrop_button0.scale.x > original_draganddrop_button0_scale:
		draganddrop_button0.scale -= Vector2.ONE * delta * 2
	if draganddrop_button1 and draganddrop_button1.scale.x > original_draganddrop_button1_scale:
		draganddrop_button1.scale -= Vector2.ONE * delta * 2
	if draganddrop_button2 and draganddrop_button2.scale.x > original_draganddrop_button2_scale:
		draganddrop_button2.scale -= Vector2.ONE * delta * 2
	if draganddrop_button3 and draganddrop_button3.scale.x > original_draganddrop_button3_scale:
		draganddrop_button3.scale -= Vector2.ONE * delta * 2
	
	if not %BpmManager:
		return
	
	var beats_amount = %BpmManager.beats_amount
	var current_beat = %BpmManager.current_beat
	
	# Update beat sprites

	for ring in range(min(4, beat_sprites.size())):
		if ring >= beat_sprites.size():
			continue
		for beat in range(min(beats_amount, beat_sprites[ring].size())):
			if beat >= beat_sprites[ring].size():
				continue
			
			var sprite = beat_sprites[ring][beat] as Sprite2D
			if not sprite:
				continue
			
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
		if ring >= template_sprites.size():
			continue
		for beat in range(min(beats_amount, template_sprites[ring].size())):
			if beat >= template_sprites[ring].size():
				continue
			
			var sprite = template_sprites[ring][beat] as Sprite2D
			if not sprite:
				continue
			
			var template_active = get_template_active(ring, beat)
			sprite.modulate = Color(0, 0, 0, 0)
			if template_active and show_template:
				sprite.modulate = Color(0, 0, 0, 1)

func _update_layer_outline_sprite_rotation():
	if not layer_outline or not %BpmManager:
		return
	
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
	if not copy_paste_clear_buttons_holder:
		return
	
	var any_layer_button_pressed = false # Get from layer manager
	if layer_manager and layer_manager.has_method("get_any_layer_button_pressed"):
		any_layer_button_pressed = layer_manager.get_any_layer_button_pressed()
	
	if copy_paste_clear_button_holder_time_since_activation >= 3.5:
		set_copy_paste_clear_buttons_active(false)
	elif any_layer_button_pressed:
		copy_paste_clear_button_holder_time_since_activation += delta

func update_layer_switch_buttons_colors():
	if not layer_manager:
		return
	
	# Get layer buttons from layer manager
	var layer_buttons = []
	layer_buttons = layer_manager.get_layer_buttons()
	
	for i in range(layer_buttons.size()):
		var button = layer_buttons[i]
		if not button:
			continue
		
		button.modulate = Color(1, 1, 1, 1)
		
		# Check if layer has beats
		var has_beats = layer_has_beats(i)
		if not has_beats:
			button.modulate = button.modulate.darkened(0.5)

func _update_interface_state():
	if not interface_set_to_default_state:
		set_entire_interface_visibility(true)
		if achievements_panel:
			achievements_panel.visible = false
		interface_set_to_default_state = true

func _update_saving_label(delta: float):
	if saving_label_active and saving_label_timer < 4:
		saving_label_timer += delta
	else:
		saving_label_active = false
	if saving_label:
		saving_label.visible = saving_label_active

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
	var outlines = [
		draganddrop_button0.find_child("OutlineSprite") as Sprite2D,
		draganddrop_button1.find_child("OutlineSprite") as Sprite2D,
		draganddrop_button2.find_child("OutlineSprite") as Sprite2D,
		draganddrop_button3.find_child("OutlineSprite") as Sprite2D
	]
	
	if chaos_pad_mode == ChaosPadMode.SampleMixing:
		var mixing_manager = get_parent().get_node_or_null("MixingManager")
		if mixing_manager:
			var active_ring = mixing_manager.samples_mixing_active_ring
			for i in range(4):
				if i < outlines.size() and outlines[i] and i < filled_beat_textures.size() and i < outline_beat_textures.size():
					outlines[i].texture = filled_beat_textures[i] if active_ring == i else outline_beat_textures[i]
	else:
		for i in range(4):
			if i < outlines.size() and outlines[i] and i < outline_beat_textures.size():
				outlines[i].texture = outline_beat_textures[i]

func _update_synth_button_outlines():
	if not activate_green_chaos_button or not activate_purple_chaos_button or not %BpmManager:
		return
	
	var progression = float(%BpmManager.current_beat + (%BpmManager.beat_timer / %BpmManager.time_per_beat)) / float(%BpmManager.beats_amount)
	if is_nan(progression):
		progression = 0.0
	
	var green_back = activate_green_chaos_button.find_child("BackSprite") as Sprite2D
	var green_outline = activate_green_chaos_button.find_child("OutlineSprite") as Sprite2D
	var purple_back = activate_purple_chaos_button.find_child("BackSprite") as Sprite2D
	var purple_outline = activate_purple_chaos_button.find_child("OutlineSprite") as Sprite2D
	
	if not green_back or not green_outline or not purple_back or not purple_outline:
		return
	
	if chaos_pad_mode == ChaosPadMode.SynthMixing:
		var mixing_manager = get_parent().get_node_or_null("MixingManager")
		if mixing_manager:
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
	if progress_bar:
		progress_bar_value = clamp(progress_bar_value, 0.0, 100.0)
		progress_bar.value = progress_bar_value

func _update_labels():
	if %BpmManager:
		if bpm_label:
			bpm_label.text = str(%BpmManager.bpm)
		if recording_delay_label and recording_delay_slider:
			recording_delay_label.text = "%.2fs" % recording_delay_slider.value
		if swing_slider:
			%BpmManager.swing = swing_slider.value
		if real_time_audio_recording_progress_bar and layer_loop_toggle:
			real_time_audio_recording_progress_bar.visible = layer_loop_toggle.button_pressed

func _update_drag_and_drop():
	if not draganddropthing:
		return
	if dragginganddropping and holding_for_ring < colors.size():
		draganddropthing.modulate = colors[holding_for_ring]
		draganddropthing.position = get_viewport().get_mouse_position() - Vector2(1280, 720) / 2.0
	else:
		draganddropthing.modulate = Color(1, 1, 1, 0)

func _update_mic_meter():
	if mic_meter and has_node("/root/MicrophoneCapture"):
		var mic_capture = get_node("/root/MicrophoneCapture")
		if mic_capture and mic_capture.has_method("get") and "volume" in mic_capture:
			mic_meter.value = mic_capture.volume

func update_layer_buttons_delayed():
	# Implementation - update layer button UI
	pass

func set_entire_interface_visibility(visible: bool):
	# Show/hide all interface elements
	for node in nodes_that_can_be_unlocked:
		if node:
			node.visible = visible

func set_copy_paste_clear_buttons_active(active: bool):
	if not copy_paste_clear_buttons_holder:
		return
	
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
	# Get from template manager
	return false

func layer_has_beats(layer_index: int) -> bool:
	# Check if layer has any beats
	if layer_manager and layer_manager.has_method("layer_has_beats"):
		return layer_manager.layer_has_beats(layer_index)
	return false

func add_layer(index: int, emoji: String):
	layer_added.emit(index, emoji)
	if layer_manager and layer_manager.has_method("add_layer"):
		layer_manager.add_layer(index, emoji)

func open_emoji_prompt():
	# Show emoji selection prompt
	pass

func close_emoji_prompt():
	# Hide emoji selection prompt
	pass

func copy_layer():
	# Save current layer state
	layer_manager.copy_layer()

func paste_layer():
	# Restore saved layer state
	layer_manager.paste_layer()

func clear_layer():
	# Clear current layer
	layer_manager.clear_layer()

func play_extra_sfx():
	# Play UI sound effect
	pass


#signal handlers
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
	if %BpmManager:
		%BpmManager.bpm += 1

func _on_bpm_down():
	if %BpmManager:
		%BpmManager.bpm -= 1

func _on_play_pause():
	if play_pause_button and not play_pause_button.disabled:
		%BpmManager.playing = !%BpmManager.playing

func _on_enter_pressed():
	pass
