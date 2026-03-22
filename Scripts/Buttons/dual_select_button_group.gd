## A ButtonGroup-like resource that allows up to 2 buttons to be pressed
## simultaneously. When a 3rd button is pressed, the oldest selection
## is automatically unpressed (FIFO).
##
## Usage:
##   1. Create a DualSelectButtonGroup resource.
##   2. In code, call add_button() for every BaseButton you want to manage.
##      (Do NOT assign the built-in button_group property — this replaces it.)
##   3. Connect to the "pressed" signal to react to selection changes.
class_name DualSelectButtonGroup
extends Resource

## Emitted every time a managed button is pressed or unpressed.
## [param buttons] is the array of currently pressed buttons.
signal pressed(buttons: Array[BaseButton])

## Maximum number of buttons that can be pressed at the same time.
@export var max_selected: int = 2

## Allow unpressing an already-pressed button by clicking it again.
@export var allow_unpress: bool = true

## Ordered queue of currently pressed buttons (oldest first).
var _selected: Array[BaseButton] = []

## All managed buttons.
var _buttons: Array[BaseButton] = []


## Register a button to be managed by this group.
## The button must be a toggle button (toggle_mode = true).
func add_button(button: BaseButton) -> void:
	if _buttons.has(button):
		return
	button.toggle_mode = true
	_buttons.append(button)
	button.toggled.connect(_on_button_toggled.bind(button))


## Remove a button from this group.
func remove_button(button: BaseButton) -> void:
	if not _buttons.has(button):
		return
	_buttons.erase(button)
	_selected.erase(button)
	if button.toggled.is_connected(_on_button_toggled.bind(button)):
		button.toggled.disconnect(_on_button_toggled.bind(button))


## Returns all currently pressed buttons (oldest first).
func get_pressed_buttons() -> Array[BaseButton]:
	return _selected.duplicate()


func _on_button_toggled(is_pressed: bool, button: BaseButton) -> void:
	if is_pressed:
		# Enforce the max selection limit (FIFO eviction).
		while _selected.size() >= max_selected:
			var oldest := _selected.pop_front() as BaseButton
			oldest.set_pressed_no_signal(false)

		_selected.append(button)
	else:
		if not allow_unpress:
			# Re-press the button — unpressing is not allowed.
			button.set_pressed_no_signal(true)
			return
		_selected.erase(button)

	pressed.emit(_selected.duplicate())
