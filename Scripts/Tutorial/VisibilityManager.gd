extends Node
class_name VisibilityManager

## Handles all UI element visibility changes via EventBus.
## Emit [signal EventBus.ui_visibility_requested] with a [enum UIElement] value and a bool
## to show or hide the corresponding node. Each element maps 1-to-1 to an @export var below.

enum UIElement {
	BEAT_RING,
	BEAT_POINTER,
	PLAY_PAUSE_BUTTON,
	KLAPPY_CONTINUE,
	CLAP_UI,
	STOMP_UI,
	SYNTH2_LAYER,
	MIC_RECORDER,
	CHAOS_PAD,
	CHAOS_PAD_TRIANGLE,
	ACHIEVEMENTS_PANEL,
	ENTIRE_INTERFACE,
}
