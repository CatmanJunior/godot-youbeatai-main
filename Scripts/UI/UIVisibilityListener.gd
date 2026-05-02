class_name UIVisibilityListener
extends CanvasItem

## Attach to any [CanvasItem] node to make it self-manage its visibility via EventBus.
## Set [member ui_element] to the matching [enum VisibilityManager.UIElement] value in the editor.
## Each instance **must** have its [member ui_element] assigned — the default is only a placeholder.
## When [signal EventBus.ui_visibility_requested] fires with that value, [member visible] is updated.

@export var ui_element: VisibilityManager.UIElement = VisibilityManager.UIElement.BEAT_RING

func _ready() -> void:
	EventBus.ui_visibility_requested.connect(_on_ui_visibility_requested)

func _on_ui_visibility_requested(element: int, vis: bool) -> void:
	if element == ui_element:
		visible = vis
