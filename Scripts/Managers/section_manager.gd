extends Node

# Section management constants
const SECTIONS_AMOUNT_MAX: int = 10
const SECTIONS_AMOUNT_INITIAL: int = 4
const SECTION_BUTTON_SIZE: int = 72

# Section state
var current_section_index: int = 0
var sections_amount: int = 0
var current_section: SectionData

# Section data — each entry is a SectionData instance
var sections: Array[SectionData] = []

# Section buttons
var section_buttons: Array[Button] = []

# UI references
var section_button_prefab: PackedScene
var section_buttons_container: HBoxContainer
var section_outline_holder: Node2D
var song_mode_back_panel: ProgressBar

# Color palette
var colors: Array[Color] = []

var beats_amount: int = 16

# Clipboard for copy/paste
var clipboard_section: SectionData = null

func _ready() -> void:
	section_button_prefab = %UiManager.layer_button_prefab
	section_buttons_container = %UiManager.layer_buttons_container
	section_outline_holder = %UiManager.layer_outline_holder
	song_mode_back_panel = %UiManager.real_time_audio_recording_progress_bar
	
	# Connect to EventBus
	EventBus.copy_requested.connect(_copy_section)
	EventBus.paste_requested.connect(_paste_section)
	EventBus.section_clear_requested.connect(clear_section)

	spawn_initial_section_buttons()


func spawn_initial_section_buttons():
	"""Spawn the initial set of section buttons"""
	for i in range(SECTIONS_AMOUNT_INITIAL):
		add_section(i)
	switch_section_next_frame(0)

func add_section(section: int, emoji: String = ""):
	"""Add a new section at the specified index"""
	if sections_amount == SECTIONS_AMOUNT_MAX:
		print("Maximum sections reached, cannot add more.")
		return

	# Insert silence into active recordings for the new section
	_insert_silence_for_section(section)

	sections_amount += 1
	_new_section_button(section, emoji)
	
	# Create a new SectionData instance
	var new_section := SectionData.new(beats_amount, Vector2.ZERO, emoji)
	sections.insert(section, new_section)
	
	current_section = new_section

	# Notify other managers about new section via EventBus
	EventBus.section_added.emit(section, emoji)
	
	sort_section_buttons_in_container()
	update_section_buttons_user_interface()


func remove_section(section: int):
	"""Remove a section at the specified index"""
	if sections_amount <= 1:
		return

	# Remove the section's audio segment from active recordings
	_remove_audio_for_section(section)

	_remove_section_button(section)
	await get_tree().process_frame
	
	sections.remove_at(section)
	
	# Notify other managers about removed section
	EventBus.section_removed.emit(section)

	sections_amount -= 1
	
	# If the deleted section was the current one, go to first section
	if section == current_section_index:
		switch_section(0)

func _new_section_button(section: int, emoji: String = "") -> Button:
	"""Create a new section button"""
	if not section_button_prefab:
		return null
	
	var section_button = section_button_prefab.instantiate() as Button
	section_buttons.insert(section, section_button)
	section_buttons_container.add_child(section_button)
	
	if emoji != "":
		section_button.text = emoji
	else:
		var options = ["🌱", "📜", "🤩", "🏁"]
		section_button.text = options[section % 4]
	
	section_button.pressed.connect(func():
		var section_index = section_buttons.find(section_button)
		switch_section(section_index)
	)
	
	return section_button

func _remove_section_button(section: int):
	"""Remove a section button"""
	if section < 0 or section >= section_buttons.size():
		return
	
	var button_to_remove = section_buttons[section]
	section_buttons_container.remove_child(button_to_remove)
	button_to_remove.queue_free()
	section_buttons.erase(button_to_remove)


func _copy_section():
	"""Copy the current section to the clipboard"""	
	clipboard_section = current_section.duplicate_section()

func _paste_section():
	"""Paste the clipboard into the current section"""
	if clipboard_section == null:
		return
	
	# Copy beat and knob data from clipboard into current section
	current_section.set_beat_actives(clipboard_section.get_beat_actives())
	current_section.set_sample_knob_positions(clipboard_section.get_sample_knob_positions())
	for i in range(SectionData.SYNTH_TRACKS_PER_SECTION):
		current_section.synth_tracks[i] = clipboard_section.synth_tracks[i].duplicate_track() as SynthTrackData
	
	EventBus.section_changed.emit(current_section)
	update_section_buttons_user_interface()

func clear_section():
	"""Clear all beats from the current section"""
	var section = current_section_index
	if section < 0 or section >= sections.size():
		return
	
	sections[section].clear_beats()
	
	EventBus.section_cleared.emit()

func sort_section_buttons_in_container():
	"""Sort section buttons in the container based on their index"""
	var buttons: Array[Button] = []
	for child in section_buttons_container.get_children():
		if child is Button:
			buttons.append(child)
	
	# Sort buttons based on their index in section_buttons array
	buttons.sort_custom(func(a, b): return section_buttons.find(a) < section_buttons.find(b))
	
	# Move children to correct order
	for i in range(buttons.size()):
		section_buttons_container.move_child(buttons[i], i)

func update_section_buttons_user_interface():
	"""Update the visual appearance of section buttons"""
	if not section_buttons_container:
		return
	
	# Transform container
	section_buttons_container.size = Vector2(section_buttons_container.get_child_count() * SECTION_BUTTON_SIZE, SECTION_BUTTON_SIZE)
	section_buttons_container.position.x = - section_buttons_container.size.x / 2
	
	# Transform outline holder
	if section_outline_holder and current_section_index < section_buttons.size():
		section_outline_holder.global_position = section_buttons[current_section_index].global_position + Vector2(SECTION_BUTTON_SIZE, SECTION_BUTTON_SIZE) / 2
	
	# Transform song mode back panel
	if song_mode_back_panel:
		var back_panel_over_size = Vector2(16, 8)
		song_mode_back_panel.size = section_buttons_container.size + back_panel_over_size
		song_mode_back_panel.position = section_buttons_container.position - back_panel_over_size / 2
	
	# Set proper color of section buttons
	if colors.size() > 6:
		for button in section_buttons:
			button.self_modulate = colors[6]

func update_section_buttons_user_interface_delayed():
	"""Update section buttons UI after a short delay"""
	await get_tree().create_timer(0.2).timeout
	update_section_buttons_user_interface()

func switch_section(section_index: int):
	"""Switch to a different section"""
	print("Switching to section " + str(section_index)) # Debug print
	
	# Switch to new section
	current_section_index = section_index
	current_section = sections[current_section_index]
	EventBus.section_changed.emit(current_section)
	
	update_section_buttons_user_interface()

func switch_section_next_frame(section_index: int):
	"""Switch to a different section on the next frame"""
	await get_tree().process_frame
	switch_section(section_index)

func next_section():
	"""Switch to the next section (or loop to first)"""
	if current_section_index == sections_amount - 1:
		switch_section(0)
	else:
		switch_section(current_section_index + 1)

func get_current_section_data() -> SectionData:
	"""Get the SectionData for the current section"""
	return sections[current_section_index]

func set_current_section(value: Array):
	"""Set the beat actives for the current section"""
	if current_section_index < sections.size():
		sections[current_section_index].set_beat_actives(value)

func section_has_beats(section: int) -> bool:
	"""Check if a section has any active beats"""
	if section < 0 or section >= sections.size():
		return false
	return sections[section].has_active_beats()


# ── Audio recording manipulation when sections change ────────────────────

func _insert_silence_for_section(section: int) -> void:
	var song_vo = get_node_or_null("%SongVoiceOver")
	if song_vo == null or song_vo.voice_over == null:
		return # No active recording, nothing to do

	var rec_node = get_node_or_null("%RealTimeAudioRecording")
	var bpm_node = get_node_or_null("%BpmManager")
	if rec_node == null or bpm_node == null:
		return

	var result := AudioSavingManager.insert_silent_layer_part_of_recordings(
		rec_node.recording_result, song_vo.voice_over,
		section, bpm_node.beats_amount, bpm_node.base_time_per_beat)

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


func _remove_audio_for_section(section: int) -> void:
	var song_vo = get_node_or_null("%SongVoiceOver")
	if song_vo == null or song_vo.voice_over == null:
		return

	var rec_node = get_node_or_null("%RealTimeAudioRecording")
	var bpm_node = get_node_or_null("%BpmManager")
	if rec_node == null or bpm_node == null:
		return

	var result := AudioSavingManager.remove_layer_part_of_recordings(
		rec_node.recording_result, song_vo.voice_over,
		section, bpm_node.beats_amount, bpm_node.base_time_per_beat)

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
