extends Node
# Audio Player Manager — manages audio players for rings and sound effects, and handles audio-related events.

# Audio Stream Players for 4 rings (main, alt, recorded)
var audio_players: Array[AudioStreamPlayer2D] = []
var audio_players_alt: Array[AudioStreamPlayer2D] = []
var audio_players_rec: Array[AudioStreamPlayer2D] = []
var sfx_player: AudioStreamPlayer2D

# Audio files
@export var main_audio_files: Array[AudioStream] = []
@export var alt_audio_files: Array[AudioStream] = []
@export var metronome_sfx: AudioStream
@export var metronome_alt_sfx: AudioStream
@export var achievement_sfx: AudioStream

signal green_synth_set(font: Resource, instrument: int)
signal purple_synth_set(font: Resource, instrument: int)

func _ready():
	init_all_audio_players()
	# Connect to EventBus instead of direct manager references
	EventBus.play_ring_requested.connect(play_ring)
	EventBus.play_sfx_requested.connect(play_sfx)
	EventBus.beat_triggered.connect(_on_beat_pitch_randomization)

func init_all_audio_players():
	# Create SFX player
	sfx_player = AudioStreamPlayer2D.new()
	add_child(sfx_player)

	# Create 4 audio players for main, alt, and recorded streams
	_create_audio_players(audio_players, main_audio_files)
	_create_audio_players(audio_players_alt, alt_audio_files)
	_create_audio_players(audio_players_rec, [])

func _create_audio_players(players_array: Array[AudioStreamPlayer2D], audio_files: Array[AudioStream]):
	"""Create 4 audio players for a ring and assign audio files"""
	for i in range(4):
		var player = AudioStreamPlayer2D.new()
		player.bus = "Ring" + str(i)
		add_child(player)
		players_array.append(player)
		
		if i < audio_files.size():
			player.stream = audio_files[i]

func play_ring(ring: int):
	"""Play audio for a specific ring based on beat actives"""
	if ring < 0 or ring >= 4:
		return
	
	audio_players[ring].play()
	audio_players_alt[ring].play()
	if audio_players_rec[ring].stream != null:
		audio_players_rec[ring].play()

func play_sfx(stream: AudioStream):
	"""Play a sound effect"""
	if stream:
		sfx_player.stream = stream
		sfx_player.play()

func _on_beat_pitch_randomization(_beat: int):
	"""Apply random pitch variation for ring 3 on each beat"""
	if audio_players.size() > 3:
		var strength = 0.2
		var pitch = 1.0 + (randf() - 0.5) * strength
		audio_players[3].pitch_scale = pitch
		if audio_players_alt.size() > 3:
			audio_players_alt[3].pitch_scale = pitch
		if audio_players_rec.size() > 3:
			audio_players_rec[3].pitch_scale = pitch

func set_main_stream(ring: int, stream: AudioStream):
	"""Set the main audio stream for a ring"""
	if ring >= 0 and ring < audio_players.size():
		audio_players[ring].stream = stream

func set_alt_stream(ring: int, stream: AudioStream):
	"""Set the alt audio stream for a ring"""
	if ring >= 0 and ring < audio_players_alt.size():
		audio_players_alt[ring].stream = stream

func set_rec_stream(ring: int, stream: AudioStream):
	"""Set the recorded audio stream for a ring"""
	if ring >= 0 and ring < audio_players_rec.size():
		audio_players_rec[ring].stream = stream

func get_ring_volume(ring: int) -> float:
	"""Get the volume for a specific ring bus"""
	if ring < 0 or ring >= 4:
		return 0.0
	
	var bus_index = AudioServer.get_bus_index("Ring" + str(ring))
	var left = AudioServer.get_bus_peak_volume_left_db(bus_index, 0)
	var right = AudioServer.get_bus_peak_volume_right_db(bus_index, 0)
	return db_to_linear((left + right) / 2.0)
