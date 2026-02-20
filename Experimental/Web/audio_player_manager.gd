extends Node

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
	%BpmManager.on_beat_event.connect(on_beat)

func init_all_audio_players():
	# Create SFX player
	sfx_player = AudioStreamPlayer2D.new()
	add_child(sfx_player)
	
	# Create 4 main audio players
	for i in range(4):
		var player = AudioStreamPlayer2D.new()
		player.bus = "Ring" + str(i)
		add_child(player)
		audio_players.append(player)
		
		if i < main_audio_files.size():
			player.stream = main_audio_files[i]
	
	# Create 4 alt audio players
	for i in range(4):
		var player = AudioStreamPlayer2D.new()
		player.bus = "Ring" + str(i)
		add_child(player)
		audio_players_alt.append(player)
		
		if i < alt_audio_files.size():
			player.stream = alt_audio_files[i]
	
	# Create 4 recorded audio players
	for i in range(4):
		var player = AudioStreamPlayer2D.new()
		player.bus = "Ring" + str(i)
		add_child(player)
		audio_players_rec.append(player)

func play_ring(ring: int):
	"""Play audio for a specific ring based on beat actives"""
	if ring < 0 or ring >= 4:
		return
	
	audio_players[ring].play()
	audio_players_alt[ring].play()
	if audio_players_rec[ring].stream != null:
		audio_players_rec[ring].play()

func _play_sfx(stream: AudioStream):
	"""Play a sound effect"""
	if stream:
		sfx_player.stream = stream
		sfx_player.play()

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

func on_beat(beat: int):
	"""Play audio for all active rings on beat"""
	for ring in range(4):
		if %BeatManager.get_beat(ring, beat):
			play_ring(ring)

func get_ring_volume(ring: int) -> float:
	"""Get the volume for a specific ring bus"""
	if ring < 0 or ring >= 4:
		return 0.0
	
	var bus_index = AudioServer.get_bus_index("Ring" + str(ring))
	var left = AudioServer.get_bus_peak_volume_left_db(bus_index, 0)
	var right = AudioServer.get_bus_peak_volume_right_db(bus_index, 0)
	return db_to_linear((left + right) / 2.0)
