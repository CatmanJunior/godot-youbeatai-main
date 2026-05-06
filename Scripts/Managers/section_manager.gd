extends Node


# Section management constants
const SECTIONS_AMOUNT_MAX: int = 8
const SECTIONS_AMOUNT_INITIAL: int = 4

# Section state
var current_section_index: int:
	get: return SongState.current_section_index

var current_section: SectionData:
	get: return SongState.current_section

var sections: Array[SectionData]:
	get: return SongState.sections
	set(value): SongState.sections = value

var beats_amount:
	get: return SongState.beats_per_section
	set(value): SongState.beats_per_section = value

# Clipboard for copy/paste
var clipboard_section: SectionData = null
var _sections_initialized: bool = false
var loop_cursor: int = 0

@export var initial_sections: Array[Texture2D]
## Used to resolve section texture → chord progression mapping.
## Per-soundbank overrides live in ChordSettings.tex_lookup; this is the global fallback.
@export var chord_player_settings: ChordPlayerSettings

func _ready() -> void:
	# Connect to EventBus
	EventBus.section_copy_requested.connect(_copy_section)
	EventBus.section_paste_requested.connect(_paste_section)
	EventBus.section_clear_requested.connect(clear_section)
	EventBus.add_section_requested.connect(_on_add_section_requested)
	EventBus.section_switch_requested.connect(switch_section)
	EventBus.section_remove_requested.connect(remove_section)
	EventBus.section_next_requested.connect(next_section)
	EventBus.set_loop_count_requested.connect(_set_loop_count_requested)
	call_deferred("spawn_initial_sections")
		

func spawn_initial_sections():
	"""Spawn the initial set of sections (data only)."""
	if _sections_initialized:
		return

	for i in range(len(initial_sections)):
		var tex = initial_sections[i]
		add_section(i, tex)

	switch_section_next_frame(0)
	_sections_initialized = true

func add_section(section_index: int, tex: Texture2D) -> void:
	"""Add a new section at the specified index"""
	if sections.size() == SECTIONS_AMOUNT_MAX:
		push_warning("Maximum sections reached, cannot add more.")
		return

	# Create a new SectionData instance and populate its default tracks
	var new_section: SectionData = SectionData.new(tex, section_index)
	new_section.create_default_tracks()
	_resolve_section_progression(new_section, tex)
	sections.insert(section_index, new_section)

	SongState.sections = sections
	EventBus.section_added.emit(section_index, tex)
	if _sections_initialized:
		EventBus.section_switched.emit(SongState.get_section(section_index))

func _on_add_section_requested(tex: Texture2D) -> void:
	add_section(sections.size(), tex)
	GameState.added_layer = true

func _resolve_section_progression(section: SectionData, tex: Texture2D) -> void:
	"""Populate section.progression and section.progression_offset from the active soundbank."""
	var soundbank: SoundBank = SongState.selected_soundbank
	if soundbank == null or chord_player_settings == null:
		return

	# Prefer per-soundbank tex_lookup; fall back to the global ChordPlayerSettings mapping.
	var tex_lookup: Dictionary
	if not soundbank.chord_progressions.tex_lookup.is_empty():
		tex_lookup = soundbank.chord_progressions.tex_lookup
	else:
		tex_lookup = chord_player_settings.tex_lookup

	if tex_lookup.is_empty():
		return

	var lookup_tex: Texture2D = tex
	if lookup_tex not in tex_lookup:
		push_warning("SectionManager: unknown section texture, falling back to first key for progression lookup.")
		lookup_tex = tex_lookup.keys()[0]

	var progression_offset: ProgressionOffset = tex_lookup[lookup_tex]
	var progressions: Array[ChordProgression] = soundbank.chord_progressions.progressions
	if progression_offset.progression >= progressions.size():
		push_warning("SectionManager: progression index %d out of bounds." % progression_offset.progression)
		return

	section.progression = progressions[progression_offset.progression]
	section.progression_offset = progression_offset

func remove_section(section_index: int):
	"""Remove a section at the specified index"""
	if sections.size() <= 1:
		return

	sections.remove_at(section_index)
	
	# If the deleted section was the current one, go to first section
	if section_index == current_section_index:
		switch_section(0)

	# Notify other managers about removed section
	EventBus.section_removed.emit(section_index)


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
	EventBus.template_set.emit(current_section.get_beat_actives())
	

func clear_section():
	"""Clear all beats from the current section"""
	var section = current_section_index
	if section < 0 or section >= sections.size():
		return
	
	sections[section].clear_beats()
	
	EventBus.section_cleared.emit()

func _set_loop_count_requested(section_index: int, loop_count: int):
	#TODO: catch invalid options?

	sections[section_index].loop_count = loop_count
	EventBus.on_set_loop_count.emit(section_index, loop_count)


##Switch to a different section
func switch_section(section_index: int):
	# Switch to new section
	if section_index < 0 or section_index >= sections.size():
		push_warning("Invalid section index %d, cannot switch." % section_index)
		return

	loop_cursor = 0
	EventBus.section_switched.emit(SongState.get_section(section_index))

func switch_section_next_frame(section_index: int):
	"""Switch to a different section on the next frame"""
	await get_tree().process_frame
	switch_section(section_index)

func next_section():
	# Loop current section
	loop_cursor += 1
	if loop_cursor < current_section.loop_count:
		print("loop")
		EventBus.section_loop.emit(current_section_index, loop_cursor)
		return

	"""Switch to the next section (or loop to first)"""
	if current_section_index == sections.size() - 1:
		switch_section(0)
	else:
		switch_section(current_section_index + 1)

func section_has_beats(section: int) -> bool:
	"""Check if a section has any active beats"""
	if section < 0 or section >= sections.size():
		return false
	return sections[section].has_active_beats()
