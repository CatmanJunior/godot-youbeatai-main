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

## Maps each UIElement enum value to its CanvasItem target.
var _element_map: Dictionary = {}

func _ready() -> void:
	_element_map = {
		UIElement.BEAT_RING:          beat_ring,
		UIElement.BEAT_POINTER:       beat_pointer,
		UIElement.PLAY_PAUSE_BUTTON:  play_pause_button,
		UIElement.KLAPPY_CONTINUE:    klappy_continue,
		UIElement.CLAP_UI:            clap_ui,
		UIElement.STOMP_UI:           stomp_ui,
		UIElement.SYNTH2_LAYER:       synth2_layer,
		UIElement.MIC_RECORDER:       mic_recorder,
		UIElement.CHAOS_PAD_TRIANGLE: chaos_pad_triangle,
	}
	EventBus.ui_visibility_requested.connect(_on_ui_visibility_requested)

func _on_ui_visibility_requested(element: int, vis: bool) -> void:
	if element == UIElement.ENTIRE_INTERFACE:
		for node: CanvasItem in entire_interface_nodes:
			node.visible = vis
		return
	var target: CanvasItem = _element_map.get(element, null)
	if target:
		target.visible = vis
