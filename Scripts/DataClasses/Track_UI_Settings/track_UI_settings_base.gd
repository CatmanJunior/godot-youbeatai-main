@abstract
extends Resource
class_name TrackUISettingsBase

## Base resource for per-track visual settings shared across all track types.
## Subclassed by SampleTrackUISettings, SynthTrackUISettings, and SongTrackUISettings.

@export_group("Track Select Button Textures")
## The icon displayed on the track select button (normal state)
@export var button_icon_texture: Texture2D
## The outline ring shown around the button when NOT selected
@export var button_outline_texture: Texture2D
## The filled ring shown around the button when selected / progress indicator
@export var button_filled_texture: Texture2D

@export_group("Chaos Pad Icons")
## The primary icon shown on the chaos pad triangle corner (main/left vertex)
@export var chaos_pad_main_icon: Texture2D
## The alternate icon shown on the chaos pad triangle corner (alt/right vertex)
@export var chaos_pad_alt_icon: Texture2D

@export_group("Track Color")
## The tint color used for this track's beat ring sprites and UI highlights
@export var track_color: Color = Color.WHITE