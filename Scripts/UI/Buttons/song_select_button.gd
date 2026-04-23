extends TrackSelectButton
class_name SongSelectButton

@export var song_track_line_texture: MeshInstance2D
@export var song_section_progress_bar: ProgressBar

func set_button_selected(active: bool) -> void:
	super.set_button_selected(active)
	song_track_line_texture.visible = active
	song_section_progress_bar.visible = active
