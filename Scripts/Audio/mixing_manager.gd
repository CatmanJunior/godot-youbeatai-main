extends Node

func _ready():
	EventBus.section_switched.connect(_on_section_changed)

func _on_section_changed(new_section_data: SectionData):
	_apply_stored_volumes(new_section_data)

func _retrieve_knob(section_data: SectionData) -> Vector2:
	return section_data.get_track_knob_position(SongState.selected_track_index)	

func _apply_stored_volumes(new_section_data: SectionData):
	"""Re-apply remembered mixing volumes for all tracks"""
	for track_index in range(new_section_data.tracks.size()):
		var track_data : TrackData = new_section_data.tracks[track_index]
		EventBus.set_track_volume_requested.emit(track_index, track_data.master_volume, track_data.weights)
