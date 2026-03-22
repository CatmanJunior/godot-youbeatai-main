class_name SynthTrackPlayer
extends TrackPlayerBase

var BUS_SUFFIXES : Array[String] = ["Dry", "Alt1", "Alt2"]

var BUS_PREFIX : String = "Track"

func _get_bus_suffixes() -> Array[String]:
	return BUS_SUFFIXES

func _get_bus_prefix() -> String:
	return BUS_PREFIX

# --- Public API ---

func set_recorded_stream(stream: AudioStream) -> void:
	for p in players:
		p.stream = stream # all layers share the same recording
	_has_recording = true
	set_weights(_weights) # reapply weights now that streams are loaded

## Playback control
func play(offset: float = 0.0) -> void:
	if not _has_recording:
		return
	for p in players:
		p.play(offset) # same frame → phase-locked across all effect layers
