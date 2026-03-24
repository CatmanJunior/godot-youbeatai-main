extends Control
class_name KnobTest

# Tune this — higher = less accidental drags on button clicks
const DRAG_THRESHOLD := 6.0

var _dragging := false
var _mouse_down := false
var _press_pos := Vector2.ZERO
var _start_handle_pos := Vector2.ZERO

@onready var container: TriangleContainer = get_parent()  # TriangleContainer

func _ready() -> void:
	# Must be on top and intercept mouse, but not block events until drag confirmed
	mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_mouse_down = true
			_press_pos = get_global_mouse_position()
			_start_handle_pos = global_position
		else:
			if _dragging:
				# Swallow the release so buttons beneath don't fire
				accept_event()
			_dragging = false
			_mouse_down = false

	elif event is InputEventMouseMotion and _mouse_down:
		var delta := get_global_mouse_position() - _press_pos

		if not _dragging and delta.length() > DRAG_THRESHOLD:
			_dragging = true

		if _dragging:
			accept_event()  # Prevents click events reaching buttons
			_move_handle_constrained()

func _move_handle_constrained() -> void:
	# Convert mouse position to container local space
	var local_mouse := container.get_local_mouse_position()

	# Clamp to triangle
	var tri := container.tri
	var clamped := TriangleContainer.clamp_to_triangle(
		local_mouse, tri[0], tri[1], tri[2]
	)

	# Apply back as global position (offset by handle's own size for centering)
	global_position = container.global_position + clamped - size / 2.0
