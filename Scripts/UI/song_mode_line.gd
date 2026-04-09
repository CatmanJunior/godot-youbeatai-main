extends MeshInstance2D

func _process(_delta: float) -> void:
	visible = SongState.current_track.track_type == TrackData.TrackType.SONG
