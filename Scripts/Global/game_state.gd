extends Node

## Global game state singleton (autoload).
## Provides easy access to layers, playback state, and common data
## without needing %UniqueNode references everywhere.

# ── Layers ───────────────────────────────────────────────────────────────────

var layers: Array[LayerData] = []
var current_layer: LayerData = null
var current_layer_index: int = 0
var layers_amount: int = 0

# ── Playback ─────────────────────────────────────────────────────────────────

var playing: bool = false
var bpm: int = 120
var current_beat: int = 0
var beats_amount: int = 16
var swing: float = 0.05

# ── Mixing ───────────────────────────────────────────────────────────────────

var selected_ring: int = 0
var selected_synth: int = 0

# ── Recording ────────────────────────────────────────────────────────────────

var is_recording: bool = false

func _ready() -> void:
	EventBus.layer_changed.connect(_on_layer_changed)
	EventBus.layer_added.connect(_on_layer_added)
	EventBus.layer_removed.connect(_on_layer_removed)
	EventBus.playing_changed.connect(func(value: bool): playing = value)
	EventBus.bpm_changed.connect(func(value: float): bpm = int(value))
	EventBus.beat_triggered.connect(func(beat: int): current_beat = beat)
	EventBus.ring_selected.connect(func(ring: int): selected_ring = ring)
	EventBus.synth_selected.connect(func(synth: int): selected_synth = synth)
	EventBus.recording_started.connect(func(): is_recording = true)
	EventBus.recording_stopped.connect(func(_audio): is_recording = false)


# ── Layer helpers ────────────────────────────────────────────────────────────

func _on_layer_changed(layer: LayerData) -> void:
	current_layer = layer

func _on_layer_added(layer_index: int, _emoji: String) -> void:
	_sync_layers()

func _on_layer_removed(_layer_index: int) -> void:
	_sync_layers()

func _sync_layers() -> void:
	var lm = _get_layer_manager()
	if lm:
		layers = lm.layers
		layers_amount = lm.layers_amount
		current_layer_index = lm.current_layer_index
		current_layer = lm.current_layer

func _get_layer_manager():
	var tree = get_tree()
	if tree == null or tree.current_scene == null:
		return null
	return tree.current_scene.get_node_or_null("%LayerManager")


# ── Convenience accessors ────────────────────────────────────────────────────

func get_layer(index: int) -> LayerData:
	if index >= 0 and index < layers.size():
		return layers[index]
	return null

func get_current_ring_data(ring: int) -> RingData:
	if current_layer and ring >= 0 and ring < current_layer.rings.size():
		return current_layer.rings[ring]
	return null

func get_current_synth_data(synth: int) -> SynthData:
	if current_layer and synth >= 0 and synth < current_layer.synths.size():
		return current_layer.synths[synth]
	return null

func get_beat(ring: int, beat: int) -> bool:
	if current_layer:
		return current_layer.get_beat(ring, beat)
	return false

func has_active_beats_on_layer(layer_index: int) -> bool:
	var layer = get_layer(layer_index)
	if layer:
		return layer.has_active_beats()
	return false

func is_last_layer() -> bool:
	return current_layer_index == layers_amount - 1
