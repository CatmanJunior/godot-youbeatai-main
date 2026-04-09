class_name SampleTrackUISettings
extends TrackUISettingsBase

## Visual settings resource for a sample-based track (rings 0–3).
## Includes beat button textures for the beat ring UI, and
## select button textures for the track select button container.

@export_group("Beat Ring Textures")
## Texture shown on a beat button when the beat is INACTIVE (outline style)
@export var beat_outline_texture: Texture2D
## Texture shown on a beat button when the beat is ACTIVE (filled style)
@export var beat_filled_texture: Texture2D

