class_name UIVisibilityListener
extends CanvasItem

## Attach to any [CanvasItem] node to make it self-manage its visibility via EventBus.
## Set [member ui_element] to the matching [enum UIVisibilityListener.UIElement] value in the editor.
## Each instance **must** have its [member ui_element] assigned — the default is only a placeholder.
## When [signal EventBus.ui_visibility_requested] fires with that value, [member visible] is updated.


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
	ENTIRE_INTERFACE,
	ACHIEVEMENTS_PANEL,
	STAR1,
	STAR2,
}

@export var ui_element: UIVisibilityListener.UIElement = UIVisibilityListener.UIElement.BEAT_RING
@export var ui_reference: CanvasItem
@export var target_self: bool = false

func _ready() -> void:
	EventBus.ui_visibility_requested.connect(_on_ui_visibility_requested)

func _on_ui_visibility_requested(element: int, vis: bool) -> void:
	print("UIVisibilityListener: Received visibility request for element ", element, " with value ", vis)
	if element == ui_element or element == UIVisibilityListener.UIElement.ENTIRE_INTERFACE:
		if target_self:
			visible = vis
		else:
			ui_reference.visible = vis
		print("UIVisibilityListener: Set visibility of ", ui_element, " to ", vis)
