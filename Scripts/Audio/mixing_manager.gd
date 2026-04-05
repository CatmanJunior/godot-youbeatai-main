extends Node

enum ChaosPadMode {
	SAMPLE_MIXING,
	SYNTH_MIXING,
	SONG_MIXING
}

# Mixing state
var weights: Vector3 = Vector3.ZERO
var chaos_pad_mode: ChaosPadMode = ChaosPadMode.SAMPLE_MIXING



# Song mixing (global, not per-layer)
var song_mixing_knob_position: Vector2

@export var chaos_pad_ui: ChaosPadUI

func _ready():
	song_mixing_knob_position = chaos_pad_ui.chaos_pad_triangle_sprite.position

	EventBus.track_selected.connect(_change_active_track)
	EventBus.section_switched.connect(_on_section_changed)

func _on_section_changed(old_section_data: SectionData, _new_section_data: SectionData):
	"""Store current knob, switch section, retrieve new knob"""
	if old_section_data != null:
		_store_active_knob(old_section_data)
	
	_apply_stored_volumes(old_section_data)


func _change_active_track(new_index: int = 0):
	mixing_change_track(new_index)

func _store_active_knob(new_section_data: SectionData):
	new_section_data.set_track_knob_position(GameState.selected_track_index, chaos_pad_ui.knob.position)

func _retrieve_knob(section_data: SectionData) -> Vector2:
	return section_data.get_track_knob_position(GameState.selected_track_index)	

func _apply_stored_volumes(old_section_data: SectionData):
	"""Re-apply remembered mixing volumes for all tracks"""
	if old_section_data == null:
		return
	for track_index in range(SectionData.TRACKS_PER_SECTION):
		var old_track = old_section_data.tracks[track_index]
		GameState.current_section.tracks[track_index].master_volume = old_track.master_volume
		GameState.current_section.tracks[track_index].weights = old_track.weights
		
func mixing_change_track(new_track_index: int):
	if GameState.current_section == null:
		return
	_store_active_knob(GameState.current_section)

	var pos = _retrieve_knob(GameState.current_section)
	chaos_pad_ui.knob.position = pos

	chaos_pad_ui.start_triangle_color_change(new_track_index, 0.2)
	
	# Update icons
	chaos_pad_ui.update_track_icons(new_track_index)
	
	# Set chaos pad mode
	if new_track_index < SectionData.SAMPLE_TRACKS_PER_SECTION:
		chaos_pad_mode = ChaosPadMode.SAMPLE_MIXING
	else:
		chaos_pad_mode = ChaosPadMode.SYNTH_MIXING

	

# UTILITY ==================================================================


