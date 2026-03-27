extends Node
# Audio Player Manager — manages audio players for rings and sound effects, and handles audio-related events.

const TRACK_COUNT = 6
const SYNTH_TRACKS_COUNT = 2
const SAMPLE_TRACKS_COUNT = 4

var track_players: Array[TrackPlayerBase] = []

var sfx_player: AudioStreamPlayer

# Audio files
@export var main_audio_files: Array[AudioStream] = []
@export var alt_audio_files: Array[AudioStream] = []

@export var metronome_sfx: AudioStream
@export var metronome_alt_sfx: AudioStream
@export var achievement_sfx: AudioStream

@export var note_player_settings: Array[NotePlayerSettings] = []

func _ready():
	_init_audio_players()
	_init_sfx_player()

	# Connect to EventBus instead of direct manager references
	EventBus.play_sample_track_requested.connect(play_track)
	EventBus.play_track_requested.connect(play_track)
	EventBus.set_track_volume_requested.connect(set_track_volume)
	EventBus.play_sfx_requested.connect(play_sfx)
	EventBus.beat_triggered.connect(_on_beat_pitch_randomization)
	EventBus.set_stream_requested.connect(_on_request_set_stream)
	EventBus.set_recorded_stream_requested.connect(_on_request_set_recorded_stream)
	EventBus.mute_all_requested.connect(_mute_all)
	EventBus.all_players_stop_requested.connect(_on_all_players_stop)

func _on_all_players_stop():
	for player in track_players:
		player.stop()


func _init_sfx_player():
	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)

func _init_audio_players():
	# Create sample track players
	for i in range(SAMPLE_TRACKS_COUNT):
		var player = SampleTrackPlayer.new()
		player.setup(i, "Master")
		player.set_streams(main_audio_files[i], alt_audio_files[i]) # set initial streams from exported arrays
		track_players.append(player)
		add_child(player)

	# Create synth track players
	for i in range(SYNTH_TRACKS_COUNT):
		var player = SynthTrackPlayer.new()
		player.setup(i + SAMPLE_TRACKS_COUNT, "Master")
		if i < note_player_settings.size():
			var np = notePlayer.new()
			np.stream = AudioStreamGenerator.new()
			np.stream.buffer_length = 0.1
			np.apply_settings(note_player_settings[i])
			player.note_player = np
			player.add_child(np)
		track_players.append(player)
		add_child(player)

func play_track(track: int):
	if track < 0 or track >= track_players.size():
		printerr("Invalid track index %d for play_track" % track)
		return
	track_players[track].play()

func play_sfx(stream: AudioStream):
	"""Play a sound effect"""
	if stream:
		sfx_player.stream = stream
		sfx_player.play()

func get_playback_position(track_index: int) -> float:
	return track_players[track_index].get_playback_position()

func set_recorded_stream(track_index: int, stream: AudioStream):
	track_players[track_index].set_recorded_stream(stream)

#Signal handlers
func _on_beat_pitch_randomization(_beat: int):
	# TODO: Implement pitch randomization in the track players
	pass

func _on_request_set_stream(trackIndex: int, audio_layer: int, audio: AudioStream):
	if trackIndex < 0 or trackIndex >= track_players.size():
		printerr("Invalid track index %d for _on_request_set_stream" % trackIndex)
		return
	track_players[trackIndex].set_stream(audio_layer, audio)

func _on_request_set_recorded_stream(trackIndex: int, audio: AudioStream):
	if trackIndex < 0 or trackIndex >= track_players.size():
		printerr("Invalid track index %d for _on_request_set_recorded_stream" % trackIndex)
		return
	track_players[trackIndex].set_recorded_stream(audio)

##Get the volume for a specific track bus (used for visualizations and recording level checks)
func get_track_volume(track: int) -> float:
	if track < 0 or track >= TRACK_COUNT:
		printerr("Invalid track index %d for get_track_volume" % track)
		return 0.0
	
	return BusHelper.get_volume(track_players[track].bus_name)

## Set the volume for a specific track bus, and update the crossfade weights for sample tracks
func set_track_volume(track: int, volume: float, weights: Vector3):
	if track < 0 or track >= TRACK_COUNT:
		printerr("Invalid track index %d for set_track_volume" % track)
		return
	track_players[track].set_weights(weights)
	track_players[track].set_volume_db(volume)

## Mute/unmute all audio (used for pause and global mute)
func _mute_all(mute: bool):
	for player in track_players:
		player.set_muted(mute)
	
	sfx_player.volume_db = -80.0 if mute else 0.0
