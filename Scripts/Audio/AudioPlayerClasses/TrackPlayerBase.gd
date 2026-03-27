## Base class for track players (SampleTrackPlayer and SynthTrackPlayer)
class_name TrackPlayerBase
extends Node

const SILENT_DB: float = -80.0
const SUB_TRACK_PLAYER_COUNT = 3

var track_index: int
var bus_name: String # the root bus for this track

var sub_bus_names: Array[String] = [] # bus names for this track

var players: Array[AudioStreamPlayer] = [] # players for main, alt, recording

var _weights: Vector3 = Vector3(1.0, 0.0, 0.0)

@warning_ignore("unused_private_class_variable")
var _has_recording: bool = false

func _get_bus_suffixes() -> Array[String]:
	return []

func _get_bus_prefix() -> String:
	return ""

func setup(index: int, parent_bus: String) -> void:
	track_index = index
	_create_buses(parent_bus)
	_setup_players()

# Override in subclasses
func _create_buses(parent_bus: String) -> void:
	bus_name = "%s%d" % [_get_bus_prefix(), track_index]
	BusHelper.create_bus(bus_name, parent_bus)

	for i in range(SUB_TRACK_PLAYER_COUNT):
		sub_bus_names.append(bus_name + "_" + _get_bus_suffixes()[i])
		var new_bus_index = BusHelper.create_bus(sub_bus_names[i], bus_name)
		_apply_layer_effects(i, new_bus_index)

	set_weights(_weights) # initialize volumes based on default weights

func _setup_players() -> void:
	for i in range(SUB_TRACK_PLAYER_COUNT):
		players.append(_make_player(sub_bus_names[i]))

func _make_player(bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	add_child(p)
	return p

func _apply_layer_effects(layer: int, bus_idx: int) -> void:
	if bus_idx == -1:
		push_error("Bus '%s' not found for applying effects." % sub_bus_names[layer])
		return
	match layer:
		0: # Dry — no effects
			pass
		1: # Alt1 — no effects
			pass
		2: # Alt2 — no effects
			pass


func set_streams(_a: AudioStream, _b: AudioStream, _rec: AudioStream = null) -> void: pass
func set_recorded_stream(_rec: AudioStream) -> void: pass

func set_stream(audio_layer: int, stream: AudioStream) -> void:
	if audio_layer < 0 or audio_layer >= SUB_TRACK_PLAYER_COUNT:
		printerr("Invalid audio layer %d for set_stream" % audio_layer)
		return
	if audio_layer == 2:
		set_recorded_stream(stream)
		printerr("Warning: set_stream with audio_layer 2 will set the recorded stream. Use set_recorded_stream directly for clarity. Stream: %s" % stream)
	else:
		players[audio_layer].stream = stream

func set_weights(weights: Vector3) -> void:
	_weights = BusHelper.crossfade3(sub_bus_names, weights)

func play(_offset: float = 0.0) -> void: pass

func stop() -> void:
	for p in players:
		p.stop()

func set_volume_db(db: float) -> void:
	BusHelper.set_volume(bus_name, db)

func set_muted(muted: bool) -> void:
	BusHelper.set_mute(bus_name, muted)

func get_playback_position() -> float:
	if players.size() > 0:
		return players[0].get_playback_position()
	return 0.0

# Called by Section when tearing down (section change)
func teardown_buses() -> void:
	for b in sub_bus_names:
		BusHelper.remove_bus(b)

	BusHelper.remove_bus(bus_name)
