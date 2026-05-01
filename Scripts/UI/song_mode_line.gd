extends MeshInstance2D

func _process(_delta: float) -> void:
	if SongState.current_track != null:
		visible = SongState.current_track.track_type == TrackData.TrackType.SONG
	
