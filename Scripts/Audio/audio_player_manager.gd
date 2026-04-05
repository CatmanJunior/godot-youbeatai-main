extends Node
class_name AudioPlayerManager

const TRACK_COUNT = 6
const SYNTH_TRACKS_COUNT = 2
const SAMPLE_TRACKS_COUNT = 4

var track_players: Array[TrackPlayerBase] = []

var sfx_player: AudioStreamPlayer

## FOR DEBUGGING
var current_volume: Dictionary= {} 

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
	EventBus.play_sfx_requested.connect(play_sfx)

func _process(_delta):
	_log_volumes()

func _log_volumes():
	for i in range(TRACK_COUNT):
		var volume = get_track_volume(i)
		current_volume[i] = volume

func _init_sfx_player():
	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "SFXPlayer"
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
		var player : SynthTrackPlayer = SynthTrackPlayer.new()
		player.setup(i + SAMPLE_TRACKS_COUNT, "Master", note_player_settings[i]) # pass settings for note player
		track_players.append(player)
		add_child(player)

func play_sfx(stream: AudioStream):
	"""Play a sound effect"""
	if stream:
		sfx_player.stream = stream
		sfx_player.play()

func get_playback_position(track_index: int) -> float:
	return track_players[track_index].get_playback_position()

##Get the volume for a specific track bus (used for visualizations and recording level checks)
func get_track_volume(track: int) -> float:
	if track < 0 or track >= TRACK_COUNT:
		printerr("Invalid track index %d for get_track_volume" % track)
		return 0.0
	
	return BusHelper.get_volume(track_players[track].bus_name)


