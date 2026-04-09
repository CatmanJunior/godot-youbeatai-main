class_name SynthTrackSettings
extends TrackSettingsBase

## Visual settings resource for a synth (voice-over) track.
## No beat ring textures — synth tracks don't show a beat grid.
## Includes select button textures and a background color for the synth button.

@export_group("Track Select Button Textures")
## The icon displayed on the synth track select button (normal state)
@export var button_icon_texture: Texture2D
## The outline ring shown around the button when NOT selected
@export var button_outline_texture: Texture2D
## The filled ring shown around the button when selected / progress indicator
@export var button_filled_texture: Texture2D

@export_group("Synth Button Appearance")
## Background color applied to the synth track button background rect
@export var button_background_color: Color = Color.WHITE