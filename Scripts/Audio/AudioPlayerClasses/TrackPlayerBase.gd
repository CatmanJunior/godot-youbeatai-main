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

var track_data: TrackData:
	get:
		return GameState.current_section.tracks[track_index]

@warning_ignore("unused_private_class_variable")
var _has_recording: bool = false

func _get_bus_suffixes() -> Array[String]:
	return []

func _get_bus_prefix() -> String:
	return ""

func _ready() -> void:
	EventBus.all_players_stop_requested.connect(_on_all_players_stop)
	EventBus.mute_all_requested.connect(_mute_all)
	EventBus.set_track_volume_requested.connect(set_track_volume)
	EventBus.set_stream_requested.connect(_on_request_set_stream)
	EventBus.set_recorded_stream_requested.connect(_on_request_set_recorded_stream)
	EventBus.beat_triggered.connect(_on_beat_triggered)
	EventBus.section_switched.connect(_on_section_switched)
	EventBus.audio_bank_loaded.connect(_on_audio_bank_loaded)
	EventBus.mixing_weights_changed.connect(_on_mixing_weights_changed)

func _on_mixing_weights_changed(trackIndex: int, master_volume: float, weights: Vector3) -> void:
	if trackIndex == track_index:
		set_weights(weights)
		set_volume_db(master_volume)
		print("TrackPlayerBase received mixing_weights_changed for track %d: master_volume=%.2f, weights=%s" % [trackIndex, master_volume, str(weights)])

func _on_audio_bank_loaded(_bank: AudioBank) -> void:
	# Default implementation does nothing, since not all track players will need to respond to new soundbanks.
	# SynthTrackPlayer will override this to update its note player settings based on the new bank.
	pass

## Override in subclasses
func _on_beat_triggered(_beat: int) -> void:
	print("Beat triggered should be overridden in subclass if needed")

func _on_section_switched(_new) -> void:
	print("Section Switched should be overridden in subclass if needed")

func _on_request_set_recorded_stream(trackIndex: int, audio: AudioStream):
	if trackIndex != track_index:
		return
	_set_recorded_stream(audio)

func _on_request_set_stream(trackIndex: int, audio_layer: int, audio: AudioStream):
	if trackIndex != track_index:
		return
	set_stream(audio_layer, audio)

func _mute_all(muted: bool) -> void:
	set_muted(muted)

func _on_all_players_stop():
	for p in players:
		p.stop()

# Override in subclasses
func _create_buses(parent_bus: String) -> void:
	bus_name = "%s%d" % [_get_bus_prefix(), track_index]
	BusHelper.create_bus(bus_name, parent_bus)

	for i in range(SUB_TRACK_PLAYER_COUNT):
		sub_bus_names.append(bus_name + "_" + _get_bus_suffixes()[i])
		BusHelper.create_bus(sub_bus_names[i], bus_name)

	set_weights(_weights) # initialize volumes based on default weights

func _setup_players() -> void:
	for i in range(SUB_TRACK_PLAYER_COUNT):
		players.append(_make_player(sub_bus_names[i]))
		

func _make_player(bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.name = bus
	p.bus = bus
	add_child(p)
	return p


func setup(index: int, parent_bus: String, _settings = null) -> void:
	track_index = index
	name = "%sTrack%d" % [_get_bus_prefix(), track_index]
	_create_buses(parent_bus)
	_setup_players()

func set_track_volume(track: int, volume: float, weights: Vector3):
	if track != track_index:
		return
	set_weights(weights)
	set_volume_db(volume)

func apply_effect_profile(effect_profile: EffectProfile) -> void:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		push_error("Bus '%s' not found for applying effect profile." % bus_name)
		return
	effect_profile.apply_effects(bus_idx)

func set_streams(_a: AudioStream, _b: AudioStream, _rec: AudioStream = null) -> void: pass
func _set_recorded_stream(_rec: AudioStream) -> void: pass

func set_stream(audio_layer: int, stream: AudioStream) -> void:
	if audio_layer < 0 or audio_layer >= SUB_TRACK_PLAYER_COUNT:
		printerr("Invalid audio layer %d for set_stream" % audio_layer)
		return
	if audio_layer == 2:
		_set_recorded_stream(stream)
		printerr("Warning: set_stream with audio_layer 2 will set the recorded stream. Use _set_recorded_stream directly for clarity. Stream: %s" % stream)
	else:
		players[audio_layer].stream = stream

func set_weights(weights: Vector3) -> void:
	print("Setting weights for track %d: %s" % [track_index, str(weights)])
	_weights = BusHelper.crossfade3(sub_bus_names, weights)

func play(_offset: float = 0.0) -> void: pass

func stop() -> void:
	for p in players:
		p.stop()

func set_volume_db(db: float) -> void:
	print("Setting volume for track %d to %.2f dB" % [track_index, db])
	BusHelper.set_volume(bus_name, db*10)

func set_muted(muted: bool) -> void:
	BusHelper.set_mute(bus_name, muted)

func get_playback_position() -> float:
	if players.size() > 0:
		return players[0].get_playback_position()
	return 0.0

func teardown_buses() -> void:
	for b in sub_bus_names:
		BusHelper.remove_bus(b)

	BusHelper.remove_bus(bus_name)

func create_data() -> TrackData:
	return track_data.duplicate_track()
	
