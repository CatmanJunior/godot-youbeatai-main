class_name SynthTrackUISettings
extends TrackUISettingsBase

## Visual settings resource for a synth (voice-over) track.
## No beat ring textures — synth tracks don't show a beat grid.
## Includes select button textures and a background color for the synth button.

@export_group("Synth Button Appearance")
## Background color applied to the synth track button background rect
@export var button_background_color: Color = Color.WHITE