extends Node

# Layer management constants
const LAYERS_AMOUNT_MAX: int = 10
const LAYERS_AMOUNT_INITIAL: int = 4
const LAYERS_BUTTON_SIZE: int = 72

# Layer state
var current_layer_index: int = 0
var layers_amount: int = 0

# Layer data - array of beat actives for each layer [ring][beat]
var layers_beat_actives: Array = []

# Layer buttons
var layer_buttons: Array[Button] = []

# Layer voice overs
var layers_voice_overs_0: Array[AudioStream] = []
var layers_voice_overs_1: Array[AudioStream] = []

# UI references
var layer_button_prefab: PackedScene
var layer_buttons_container: HBoxContainer
var layer_outline_holder: Node2D
var song_mode_back_panel: ProgressBar

# Color palette
var colors: Array[Color] = []

var beats_amount: int = 16

# Clipboard for copy/paste
var clipboard_beat_actives: Array = []

func _ready() -> void:
	layer_button_prefab = %UiManager.layer_button_prefab
	layer_buttons_container = %UiManager.layer_buttons_container
	layer_outline_holder = %UiManager.layer_outline_holder
	song_mode_back_panel = %UiManager.real_time_audio_recording_progress_bar
	
	# Connect to EventBus
	EventBus.copy_requested.connect(copy_layer)
	EventBus.paste_requested.connect(paste_layer)
	EventBus.layer_clear_requested.connect(clear_layer)

	spawn_initial_layer_buttons()


func spawn_initial_layer_buttons():
	"""Spawn the initial set of layer buttons"""
	for i in range(LAYERS_AMOUNT_INITIAL):
		add_layer(i)
	switch_layer_next_frame(0)

func add_layer(layer: int, emoji: String = ""):
	"""Add a new layer at the specified index"""
	if layers_amount == LAYERS_AMOUNT_MAX:
		return

	# Insert silence into active recordings for the new layer
	_insert_silence_for_layer(layer)

	layers_amount += 1
	new_layer_button(layer, emoji)
	
	# Create new beat actives array for this layer [4 rings, beats_amount beats]
	var new_beat_actives = []
	for ring in range(4):
		var ring_beats = []
		for beat in range(beats_amount):
			ring_beats.append(false)
		new_beat_actives.append(ring_beats)
	
	layers_beat_actives.insert(layer, new_beat_actives)
	layers_voice_overs_0.insert(layer, null)
	layers_voice_overs_1.insert(layer, null)
	
	# Notify other managers about new layer via EventBus
	EventBus.layer_added.emit(layer, emoji)
	
	sort_layer_buttons_in_container()
	update_layer_buttons_user_interface()
	switch_layer_next_frame(layer)

func remove_layer(layer: int):
	"""Remove a layer at the specified index"""
	if layers_amount <= 1:
		return

	# Remove the layer's audio segment from active recordings
	_remove_audio_for_layer(layer)

	remove_layer_button(layer)
	await get_tree().process_frame
	
	layers_beat_actives.remove_at(layer)
	layers_voice_overs_0.remove_at(layer)
	layers_voice_overs_1.remove_at(layer)
	
	# Notify other managers about removed layer
	EventBus.layer_removed.emit(layer)

	layers_amount -= 1
	
	# If the deleted layer was the current one, go to first layer
	if layer == current_layer_index:
		switch_layer(0, false)

func new_layer_button(layer: int, emoji: String = "") -> Button:
	"""Create a new layer button"""
	if not layer_button_prefab:
		return null
	
	var layer_button = layer_button_prefab.instantiate() as Button
	layer_buttons.insert(layer, layer_button)
	layer_buttons_container.add_child(layer_button)
	
	if emoji != "":
		layer_button.text = emoji
	else:
		var options = ["🌱", "📜", "🤩", "🏁"]
		layer_button.text = options[layer % 4]
	
	layer_button.pressed.connect(func():
		var layer_index = layer_buttons.find(layer_button)
		switch_layer(layer_index)
	)
	
	return layer_button

func remove_layer_button(layer: int):
	"""Remove a layer button"""
	if layer < 0 or layer >= layer_buttons.size():
		return
	
	var button_to_remove = layer_buttons[layer]
	layer_buttons_container.remove_child(button_to_remove)
	button_to_remove.queue_free()
	layer_buttons.erase(button_to_remove)


func copy_layer():
	"""Copy the current layer's beat actives to the clipboard"""
	var layer = current_layer_index
	if layer < 0 or layer >= layers_beat_actives.size():
		return
	
	clipboard_beat_actives = []
	for ring in range(4):
		var ring_beats = []
		for beat in range(beats_amount):
			ring_beats.append(layers_beat_actives[layer][ring][beat])
		clipboard_beat_actives.append(ring_beats)

func paste_layer():
	"""Paste the clipboard's beat actives into the current layer"""
	if clipboard_beat_actives.is_empty():
		return
	
	var layer = current_layer_index
	if layer < 0 or layer >= layers_beat_actives.size():
		return
	
	for ring in range(4):
		for beat in range(beats_amount):
			layers_beat_actives[layer][ring][beat] = clipboard_beat_actives[ring][beat]
	
	EventBus.layer_changed.emit(current_layer_index, get_current_layer())
	update_layer_buttons_user_interface()

func clear_layer():
	"""Clear all beats from a layer"""
	var layer = current_layer_index
	if layer < 0 or layer >= layers_beat_actives.size():
		return
	
	for ring in range(4):
		for beat in range(beats_amount):
			layers_beat_actives[layer][ring][beat] = false
	
	EventBus.layer_cleared.emit()

func sort_layer_buttons_in_container():
	"""Sort layer buttons in the container based on their index"""
	var buttons: Array[Button] = []
	for child in layer_buttons_container.get_children():
		if child is Button:
			buttons.append(child)
	
	# Sort buttons based on their index in layer_buttons array
	buttons.sort_custom(func(a, b): return layer_buttons.find(a) < layer_buttons.find(b))
	
	# Move children to correct order
	for i in range(buttons.size()):
		layer_buttons_container.move_child(buttons[i], i)

func update_layer_buttons_user_interface():
	"""Update the visual appearance of layer buttons"""
	if not layer_buttons_container:
		return
	
	# Transform container
	layer_buttons_container.size = Vector2(layer_buttons_container.get_child_count() * LAYERS_BUTTON_SIZE, LAYERS_BUTTON_SIZE)
	layer_buttons_container.position.x = - layer_buttons_container.size.x / 2
	
	# Transform outline holder
	if layer_outline_holder and current_layer_index < layer_buttons.size():
		layer_outline_holder.global_position = layer_buttons[current_layer_index].global_position + Vector2(LAYERS_BUTTON_SIZE, LAYERS_BUTTON_SIZE) / 2
	
	# Transform song mode back panel
	if song_mode_back_panel:
		var back_panel_over_size = Vector2(16, 8)
		song_mode_back_panel.size = layer_buttons_container.size + back_panel_over_size
		song_mode_back_panel.position = layer_buttons_container.position - back_panel_over_size / 2
	
	# Set proper color of layer buttons
	if colors.size() > 6:
		for button in layer_buttons:
			button.self_modulate = colors[6]

func update_layer_buttons_user_interface_delayed():
	"""Update layer buttons UI after a short delay"""
	await get_tree().create_timer(0.2).timeout
	update_layer_buttons_user_interface()

func switch_layer(layer_index: int, save_layer_first: bool = true):
	"""Switch to a different layer"""
	# Save current layer first if needed
	print("Switching to layer " + str(layer_index) + ", save current layer first: " + str(save_layer_first))
	if save_layer_first:
		set_current_layer(%BeatManager.beat_actives)
	
	# Switch to new layer
	current_layer_index = layer_index
	
	var new_beat_actives = get_current_layer()
	
	EventBus.layer_changed.emit(current_layer_index, new_beat_actives)
	
	update_layer_buttons_user_interface()

func switch_layer_next_frame(layer_index: int, save_layer_first: bool = true):
	"""Switch to a different layer on the next frame"""
	await get_tree().process_frame
	switch_layer(layer_index, save_layer_first)

func next_layer():
	"""Switch to the next layer (or loop to first)"""
	if current_layer_index == layers_amount - 1:
		switch_layer(0)
	else:
		switch_layer(current_layer_index + 1)

func get_current_layer() -> Array:
	"""Get the beat actives for the current layer"""
	return layers_beat_actives[current_layer_index]

func set_current_layer(value: Array):
	"""Set the beat actives for the current layer"""
	if current_layer_index < layers_beat_actives.size():
		layers_beat_actives[current_layer_index] = value

func layer_has_beats(layer: int) -> bool:
	"""Check if a layer has any active beats"""
	if layer < 0 or layer >= layers_beat_actives.size():
		return false
	var layer_beats = layers_beat_actives[layer]
	for ring in range(4):
		for beat in range(beats_amount):
			if layer_beats[ring][beat]:
				return true
	return false


# ── Audio recording manipulation when layers change ──────────────────────────

func _insert_silence_for_layer(layer: int) -> void:
	var song_vo = get_node_or_null("%SongVoiceOver")
	if song_vo == null or song_vo.voice_over == null:
		return # No active recording, nothing to do

	var rec_node = get_node_or_null("%RealTimeAudioRecording")
	var bpm_node = get_node_or_null("%BpmManager")
	if rec_node == null or bpm_node == null:
		return

	var result := AudioSavingManager.insert_silent_layer_part_of_recordings(
		rec_node.recording_result, song_vo.voice_over,
		layer, bpm_node.beats_amount, bpm_node.base_time_per_beat)

	if result.recording:
		rec_node.recording_result = result.recording
		rec_node.recording_length = float(result.recording.get_length())
	if result.voice_over:
		var was_playing: bool = song_vo.audio_player.playing if song_vo.audio_player else false
		song_vo.voice_over = result.voice_over
		if song_vo.audio_player:
			song_vo.audio_player.stream = song_vo.voice_over
			if was_playing:
				song_vo.audio_player.play()
		song_vo.recording_length = float(result.voice_over.get_length())


func _remove_audio_for_layer(layer: int) -> void:
	var song_vo = get_node_or_null("%SongVoiceOver")
	if song_vo == null or song_vo.voice_over == null:
		return

	var rec_node = get_node_or_null("%RealTimeAudioRecording")
	var bpm_node = get_node_or_null("%BpmManager")
	if rec_node == null or bpm_node == null:
		return

	var result := AudioSavingManager.remove_layer_part_of_recordings(
		rec_node.recording_result, song_vo.voice_over,
		layer, bpm_node.beats_amount, bpm_node.base_time_per_beat)

	if result.recording:
		rec_node.recording_result = result.recording
		rec_node.recording_length = float(result.recording.get_length())
	if result.voice_over:
		var was_playing: bool = song_vo.audio_player.playing if song_vo.audio_player else false
		song_vo.voice_over = result.voice_over
		if song_vo.audio_player:
			song_vo.audio_player.stream = song_vo.voice_over
			if was_playing:
				song_vo.audio_player.play()
		song_vo.recording_length = float(result.voice_over.get_length())
