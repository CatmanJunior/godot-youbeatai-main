class_name SampleTrackPlayer
extends TrackPlayerBase

var BUS_SUFFIXES : Array[String] = ["Main", "Alt", "Rec"]

var BUS_PREFIX : String = "Track"

func _get_bus_suffixes() -> Array[String]:
	return BUS_SUFFIXES

func _get_bus_prefix() -> String:
	return BUS_PREFIX

# --- Public API ---

func set_streams(a: AudioStream, b: AudioStream, rec: AudioStream=null) -> void:
	players[0].stream = a
	players[1].stream = b
	if rec != null:
		set_recorded_stream(rec)



func set_recorded_stream(rec: AudioStream) -> void:
	players[2].stream = rec
	_has_recording = true
	set_weights(_weights) # update volumes to include recording bus

## Playback control (called by Section when starting/stopping playback)
## Offset: for starting in the middle of a track. Value is in seconds.
func play(offset: float = 0.0) -> void:
	players[0].play(offset)
	players[1].play(offset)
	if _has_recording:
		players[2].play(offset)
