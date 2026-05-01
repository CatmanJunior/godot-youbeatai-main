extends Node
class_name AudioPlayerManager

static var TRACK_COUNT = 6
static var SYNTH_TRACKS_COUNT = 2
static var SAMPLE_TRACKS_COUNT = 4

var track_players: Array[TrackPlayerBase] = []
var song_track_player: SongTrackPlayer
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
	EventBus.play_sfx_requested.connect(play_sfx)

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
		player.setup(track_players.size(), "Master", note_player_settings[i]) # pass settings for note player
		track_players.append(player)
		add_child(player)

	# Create the song track player
	song_track_player = SongTrackPlayer.new()
	song_track_player.setup(SongTrackData.SONG_TRACK_INDEX, "Master")
	add_child(song_track_player)

func play_sfx(stream: AudioStream):
	"""Play a sound effect"""
	if stream:
		sfx_player.stream = stream
		sfx_player.play()

##--- Debugging method to get current track volumes (not used for actual volume control) ---
func get_track_volume(track: int) -> float:
	if track < 0 or track >= TRACK_COUNT:
		printerr("Invalid track index %d for get_track_volume" % track)
		return 0.0
	
	return BusHelper.get_volume(track_players[track].bus_name)


