extends Node

# Section management constants
const SECTIONS_AMOUNT_MAX: int = 10
const SECTIONS_AMOUNT_INITIAL: int = 4
const SECTION_BUTTON_SIZE: int = 72

# Section state
var current_section_index: int = 0
var current_section: SectionData

# Section data — each entry is a SectionData instance
var sections: Array[SectionData] = []

var beats_amount: int = 16

# Clipboard for copy/paste
var clipboard_section: SectionData = null

var _sections_initialized: bool = false

func _ready() -> void:
	# Connect to EventBus
	EventBus.copy_requested.connect(_copy_section)
	EventBus.paste_requested.connect(_paste_section)
	EventBus.section_clear_requested.connect(clear_section)
	EventBus.add_section_requested.connect(_on_add_section_requested)
	EventBus.section_switch_requested.connect(switch_section)

func _process(_delta: float) -> void:
	spawn_initial_sections()

func spawn_initial_sections():
	"""Spawn the initial set of sections (data only)."""
	if _sections_initialized:
		return

	for i in range(SECTIONS_AMOUNT_INITIAL):
		add_section(i)

	switch_section_next_frame(0)
	_sections_initialized = true

func add_section(section: int, emoji: String = ""):
	"""Add a new section at the specified index"""
	if sections.size() == SECTIONS_AMOUNT_MAX:
		push_warning("Maximum sections reached, cannot add more.")
		return

	# Insert silence into active recordings for the new section
	_insert_silence_for_section(section)

	# Create a new SectionData instance
	var new_section: SectionData = SectionData.new(section, emoji)
	sections.insert(section, new_section)

	current_section_index = section
	current_section = new_section

	# Notify other managers about new section via EventBus
	print("Section added at index %d with emoji %s" % [section, emoji])
	SongState.sections = sections
	EventBus.section_added.emit(section, emoji)
	EventBus.section_switched.emit(current_section)

func _on_add_section_requested(emoji: String):
	add_section(sections.size(), emoji)

func remove_section(section: int):
	"""Remove a section at the specified index"""
	if sections.size() <= 1:
		return

	# Remove the section's audio segment from active recordings
	_remove_audio_for_section(section)

	sections.remove_at(section)
	
	# Notify other managers about removed section
	EventBus.section_removed.emit(section)
	SongState.sections = sections

	# If the deleted section was the current one, go to first section
	if section == current_section_index:
		switch_section(0)


func _copy_section():
	"""Copy the current section to the clipboard"""
	clipboard_section = current_section.duplicate_section()

func _paste_section():
	"""Paste the clipboard into the current section"""
	if clipboard_section == null:
		return
	
	# Copy beat and knob data from clipboard into current section
	current_section.set_beat_actives(clipboard_section.get_beat_actives())
	current_section.set_section_knob_positions(clipboard_section.get_section_knob_positions())
	for i in range(SectionData.TRACKS_PER_SECTION):
		current_section.tracks[i] = clipboard_section.tracks[i].duplicate_track()

func clear_section():
	"""Clear all beats from the current section"""
	var section = current_section_index
	if section < 0 or section >= sections.size():
		return
	
	sections[section].clear_beats()
	
	EventBus.section_cleared.emit()


func switch_section(section_index: int):
	"""Switch to a different section"""
	# Switch to new section
	current_section_index = section_index
	current_section = sections[current_section_index]
	EventBus.section_switched.emit(current_section)

func switch_section_next_frame(section_index: int):
	"""Switch to a different section on the next frame"""
	await get_tree().process_frame
	switch_section(section_index)

func next_section():
	"""Switch to the next section (or loop to first)"""
	if current_section_index == sections.size() - 1:
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
	_manipulate_recording(section, AudioSavingManager.insert_silent_layer_part_of_recordings)

func _remove_audio_for_section(section: int) -> void:
	_manipulate_recording(section, AudioSavingManager.remove_layer_part_of_recordings)

## Shared helper for insert/remove recording operations.
## `operation` must accept (recording, voice_over, section, total_beats, beat_duration)
## and return a result with `.recording` and `.voice_over` fields.
func _manipulate_recording(section: int, operation: Callable) -> void:
	var song_vo = get_node_or_null("%SongVoiceOver")
	if song_vo == null or song_vo.voice_over == null:
		return

	var rec_node = get_node_or_null("%RealTimeAudioRecording")
	if rec_node == null:
		return

	var result = operation.call(
		rec_node.recording_result, song_vo.voice_over,
		section, SongState.total_beats, GameState.beat_duration)

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
