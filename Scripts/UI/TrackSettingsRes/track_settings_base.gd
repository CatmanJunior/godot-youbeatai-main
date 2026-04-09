extends Resource
class_name TrackSettingsBase

## Base resource for per-track visual settings shared across all track types.
## Subclassed by SampleTrackSettings, SynthTrackSettings, and SongTrackSettings.

@export_group("Chaos Pad Icons")
## The primary icon shown on the chaos pad triangle corner (main/left vertex)
@export var chaos_pad_main_icon: Texture2D
## The alternate icon shown on the chaos pad triangle corner (alt/right vertex)
@export var chaos_pad_alt_icon: Texture2D

@export_group("Track Color")
## The tint color used for this track's beat ring sprites and UI highlights
@export var track_color: Color = Color.WHITE