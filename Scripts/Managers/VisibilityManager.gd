extends Node
class_name VisibilityManager

## Handles all UI element visibility changes via EventBus.
## Connect ui_visibility_requested(element, visible) from any system to show/hide elements.

enum UIElement {
	BEAT_RING,
	BEAT_POINTER,
	PLAY_PAUSE_BUTTON,
	KLAPPY_CONTINUE,
	CLAP_UI,
	STOMP_UI,
	SYNTH2_LAYER,
	MIC_RECORDER,
	CHAOS_PAD_TRIANGLE,
	ENTIRE_INTERFACE,
}

@export var beat_ring: CanvasItem
@export var beat_pointer: CanvasItem
@export var play_pause_button: CanvasItem
@export var klappy_continue: CanvasItem
@export var clap_ui: CanvasItem
@export var stomp_ui: CanvasItem
@export var synth2_layer: CanvasItem
@export var mic_recorder: CanvasItem
@export var chaos_pad_triangle: CanvasItem

## All nodes shown/hidden together when ENTIRE_INTERFACE is toggled.
@export var entire_interface_nodes: Array[CanvasItem] = []

func _ready() -> void:
	EventBus.ui_visibility_requested.connect(_on_ui_visibility_requested)

func _on_ui_visibility_requested(element: int, visible: bool) -> void:
	match element:
		UIElement.BEAT_RING:
			if beat_ring:
				beat_ring.visible = visible
		UIElement.BEAT_POINTER:
			if beat_pointer:
				beat_pointer.visible = visible
		UIElement.PLAY_PAUSE_BUTTON:
			if play_pause_button:
				play_pause_button.visible = visible
		UIElement.KLAPPY_CONTINUE:
			if klappy_continue:
				klappy_continue.visible = visible
		UIElement.CLAP_UI:
			if clap_ui:
				clap_ui.visible = visible
		UIElement.STOMP_UI:
			if stomp_ui:
				stomp_ui.visible = visible
		UIElement.SYNTH2_LAYER:
			if synth2_layer:
				synth2_layer.visible = visible
		UIElement.MIC_RECORDER:
			if mic_recorder:
				mic_recorder.visible = visible
		UIElement.CHAOS_PAD_TRIANGLE:
			if chaos_pad_triangle:
				chaos_pad_triangle.visible = visible
		UIElement.ENTIRE_INTERFACE:
			for node: CanvasItem in entire_interface_nodes:
				node.visible = visible
