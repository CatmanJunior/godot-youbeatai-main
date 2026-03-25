class_name SampleTrackSettings
extends TrackSettingsBase

## Visual settings resource for a sample-based track (rings 0–3).
## Includes beat button textures for the beat ring UI, and
## select button textures for the track select button container.

@export_group("Beat Ring Textures")
## Texture shown on a beat button when the beat is INACTIVE (outline style)
@export var beat_outline_texture: Texture2D
## Texture shown on a beat button when the beat is ACTIVE (filled style)
@export var beat_filled_texture: Texture2D

@export_group("Track Select Button Textures")
## The icon displayed on the track select button (normal state)
@export var button_icon_texture: Texture2D
## The outline ring shown around the button when NOT selected
@export var button_outline_texture: Texture2D
## The filled ring shown around the button when selected / progress indicator
@export var button_filled_texture: Texture2D