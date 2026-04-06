extends Control
class_name ChaosPadKnob
const DRAG_THRESHOLD := 6.0

# How far outside the triangle edges the knob can travel (matches ChaosPadKnob)
@export var outer_triangle_size: float = 60.0

var _dragging := false
var _mouse_down := false
var _press_pos := Vector2.ZERO

@onready var container: TriangleContainer = get_parent()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_mouse_down = true
			_press_pos = get_global_mouse_position()
		else:
			if _dragging:
				accept_event()
			_dragging = false
			_mouse_down = false

	elif event is InputEventMouseMotion and _mouse_down:
		var delta := get_global_mouse_position() - _press_pos
		if not _dragging and delta.length() > DRAG_THRESHOLD:
			_dragging = true
		if _dragging:
			accept_event()
			_move_handle_constrained()

func _move_handle_constrained() -> void:
	var local_mouse := container.get_local_mouse_position()

	# Build local-space corner array for the calculator
	var tri := container.tri
	var corners: Array[Vector2] = [tri[0], tri[1], tri[2]]

	var clamped := ChaosPadCalculator.clamp_to_triangle_area(
		local_mouse,
		corners,
		outer_triangle_size
	)

	position = clamped - size / 2.0
	_get_weights_and_emit()

func _get_weights_and_emit() -> void:
	var local_pos := container.get_local_mouse_position()
	var tri := container.tri
	var corners: Array[Vector2] = [tri[0], tri[1], tri[2]]

	var result = ChaosPadCalculator.calc_weights(local_pos, corners, outer_triangle_size)
	EventBus.chaos_pad_dragging.emit(local_pos)
	EventBus.mixing_weights_changed.emit(SongState.selected_track_index, result.weights)
	EventBus.set_track_volume_requested.emit(SongState.selected_track_index, result.master_volume)
