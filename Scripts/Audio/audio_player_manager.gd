extends Node
class_name AudioPlayerManager



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
@export var chord_player_settings: ChordPlayerSettings

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
	for i in range(SectionData.SAMPLE_TRACKS_PER_SECTION):
		var player = SampleTrackPlayer.new()
		player.setup(i, BusNames.SUBMASTER_BUS)
		player.set_streams(main_audio_files[i], alt_audio_files[i]) # set initial streams from exported arrays
		track_players.append(player)
		add_child(player)

	# Create synth track players
	for i in range(SectionData.SYNTH_TRACKS_PER_SECTION):
		var player : SynthTrackPlayer = SynthTrackPlayer.new()
		player.setup(track_players.size(), BusNames.SUBMASTER_BUS, note_player_settings[i]) # pass settings for note player
		track_players.append(player)
		add_child(player)

	# Create the song track player
	song_track_player = SongTrackPlayer.new()
	song_track_player.setup(SongTrackData.SONG_TRACK_INDEX, BusNames.SUBMASTER_BUS, chord_player_settings)
	add_child(song_track_player)

func play_sfx(stream: AudioStream):
	"""Play a sound effect"""
	if stream:
		sfx_player.stream = stream
		sfx_player.play()
