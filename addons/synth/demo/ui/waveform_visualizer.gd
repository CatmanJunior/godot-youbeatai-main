extends Node2D
class_name WaveformVisualizer

var size_scale = Vector2(3, 1) * 100
var _waveform: PackedVector2Array = []

@export var _synth: Synth


func _ready() -> void:
	assert(_synth != null)
	_synth.wave_cycle_completed.connect(update_waveform)

func _draw() -> void:
	# box
	draw_rect(Rect2(Vector2(0, -1) * size_scale, size_scale * Vector2(1, 2)), Color.BLACK, false)

	if (_waveform.size() > 2):
		draw_polyline(_waveform, Color.WHITE)

func update_waveform(waveform):
	_waveform = waveform * Transform2D(0, size_scale, 0, Vector2.ZERO)
	queue_redraw()
