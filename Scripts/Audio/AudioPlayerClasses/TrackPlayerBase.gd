## Base class for track players (SampleTrackPlayer and SynthTrackPlayer)
class_name TrackPlayerBase
extends Node


const SILENT_DB: float = -80.0
const SUB_TRACK_PLAYER_COUNT = 3

var track_index: int
var bus_name: String # the root bus for this track

var sub_bus_names: Array[String] = [] # bus names for this track

var players: Array[AudioStreamPlayer] = [] # players for main, alt, recording

var _weights: Vector3 = Vector3(0.3, 0.3, 0.4) # default weights for main, alt, recording layers

var track_data: TrackData:
	get:
		if SongState.current_section and track_index >= 0 and track_index < SongState.current_section.tracks.size():
			return SongState.current_section.tracks[track_index]
		if track_index == SongTrackData.SONG_TRACK_INDEX:
			return SongState.song_track
		return null
		
@warning_ignore("unused_private_class_variable")
var _has_recording: bool = false

func _get_bus_suffixes() -> Array[String]:
	return []

func _get_bus_prefix() -> String:
	return ""

func _ready() -> void:
	EventBus.all_players_stop_requested.connect(_on_all_players_stop)
	EventBus.mute_all_requested.connect(_mute_all)
	EventBus.set_track_volume_requested.connect(_set_track_volume)
	EventBus.set_stream_requested.connect(_on_request_set_stream)
	EventBus.set_recorded_stream_requested.connect(_on_request_set_recorded_stream)
	EventBus.beat_triggered.connect(_on_beat_triggered)
	EventBus.section_switched.connect(_on_section_switched)
	EventBus.soundbank_loaded.connect(_on_soundbank_loaded)
	EventBus.mixing_weights_changed.connect(_on_mixing_weights_changed)
	EventBus.chaos_pad_dragging.connect(_on_knob_position_changed)

func _on_knob_position_changed(knobPos: Vector2) -> void:
	if SongState.selected_track_index == track_index and track_data:
		track_data.knob_position = knobPos

func _on_mixing_weights_changed(trackIndex: int, weights: Vector3) -> void:
	if trackIndex == track_index:
		set_weights(weights)

func _on_soundbank_loaded(_bank: SoundBank) -> void:
	# Default implementation does nothing, since not all track players will need to respond to new soundbanks.
	# SynthTrackPlayer will override this to update its note player settings based on the new bank.
	pass

## Override in subclasses
func _on_beat_triggered(_beat: int) -> void:
	push_error("Beat triggered should be overridden in subclass if needed")

func _on_section_switched(_new) -> void:
	push_error("Section switched should be overridden in subclass if needed")

func _on_request_set_recorded_stream(recording_data: RecordingData) -> void:
	if recording_data and recording_data.track_data and track_data and recording_data.track_data.index == track_index:
		_set_recorded_stream(recording_data)

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

func _set_track_volume(track: int, volume: float):
	if track != track_index:
		return
	set_volume_db(volume)
	

func apply_effect_profile(effect_profile: EffectProfile) -> void:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		push_error("Bus '%s' not found for applying effect profile." % bus_name)
		return
	effect_profile.apply_effects(bus_idx)

func set_streams(_a: AudioStream, _b: AudioStream, _rec: AudioStream = null) -> void: pass
func _set_recorded_stream(_recording_data: RecordingData) -> void: pass

func set_stream(_audio_layer: int, _stream: AudioStream) -> void:
	pass

func set_weights(weights: Vector3) -> void:
	_weights = BusHelper.crossfade3(sub_bus_names, weights)
	track_data.weights = weights

func play(_offset: float = 0.0) -> void: pass

func stop() -> void:
	for p in players:
		p.stop()

func set_volume_db(db: float) -> void:
	BusHelper.set_volume(bus_name, db)
	track_data.master_volume = db

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
	
