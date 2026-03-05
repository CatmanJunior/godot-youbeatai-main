extends Node
# Audio Player Manager — manages audio players for rings and sound effects, and handles audio-related events.


const RING_COUNT = 4

# Audio Stream Players for 4 rings (main, alt, recorded)
var audio_players: Array[AudioStreamPlayer] = []
var sync_streams: Array[AudioStreamSynchronized] = []

var sfx_player: AudioStreamPlayer

# Audio files
@export var main_audio_files: Array[AudioStream] = []
@export var alt_audio_files: Array[AudioStream] = []


@export var metronome_sfx: AudioStream
@export var metronome_alt_sfx: AudioStream
@export var achievement_sfx: AudioStream

func _ready():
	_init_ring_audio_players()
	_init_sfx_player()

	# Connect to EventBus instead of direct manager references
	EventBus.play_ring_requested.connect(play_ring)
	EventBus.set_ring_volume_requested.connect(set_ring_volume)
	EventBus.play_sfx_requested.connect(play_sfx)
	EventBus.beat_triggered.connect(_on_beat_pitch_randomization)
	EventBus.request_set_stream.connect(_on_request_set_stream)

func _init_sfx_player():
	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)

func _init_ring_audio_players():
	for i in range(RING_COUNT):
		# Check if we have enough audio files
		if i >= main_audio_files.size() or i >= alt_audio_files.size():
			print("Not enough main or alt audio files for ring %d" % i)
		
		var sync_stream = AudioStreamSynchronized.new()
		sync_stream.stream_count = 3
		
		sync_stream.set_sync_stream(0, main_audio_files[i])
		sync_stream.set_sync_stream(1, alt_audio_files[i])
		sync_stream.set_sync_stream(2, _create_silent_stream())
		
		# Start all silent except main
		sync_stream.set_sync_stream_volume(0, 0.0)
		sync_stream.set_sync_stream_volume(1, -80.0)
		sync_stream.set_sync_stream_volume(2, -80.0)
		
		var player = AudioStreamPlayer.new()
		player.bus = "Ring" + str(i)
		player.stream = sync_stream
		add_child(player)
		
		audio_players.append(player)
		sync_streams.append(sync_stream)


func play_ring(ring: int):
	if ring < 0 or ring >= RING_COUNT:
		return
	audio_players[ring].play()

func play_sfx(stream: AudioStream):
	"""Play a sound effect"""
	if stream:
		sfx_player.stream = stream
		sfx_player.play()


#Signal handlers
func _on_beat_pitch_randomization(_beat: int):
	if audio_players.size() > 3:
		var strength = 0.2
		var pitch = 1.0 + (randf() - 0.5) * strength
		audio_players[3].pitch_scale = pitch

func _on_request_set_stream(ring: int, track: int, audio: AudioStream):
	if ring >= 0 and ring < sync_streams.size():
		sync_streams[ring].set_sync_stream(track, audio)


#Helper
func _create_silent_stream() -> AudioStreamWAV:
	"""Helper: Create a silent audio stream for recording layer when no recording is present"""
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.stereo = false
	wav.mix_rate = AudioServer.get_mix_rate()
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.data = PackedByteArray([0, 0]) # single silent sample, loops
	return wav


func get_ring_volume(ring: int) -> float:
	"""Get the volume for a specific ring bus"""
	if ring < 0 or ring >= RING_COUNT:
		return 0.0
	
	var bus_index = AudioServer.get_bus_index("Ring" + str(ring))
	var left = AudioServer.get_bus_peak_volume_left_db(bus_index, 0)
	var right = AudioServer.get_bus_peak_volume_right_db(bus_index, 0)
	return db_to_linear((left + right) / 2.0)

func set_ring_volume(ring: int, weights: Vector3):
	"""Set the volume for a specific ring bus based on master volume and weights for main, alt, and rec"""
	if ring < 0 or ring >= RING_COUNT:
		return
	
	# Normalize weights to ensure they sum to 1
	var total = weights.x + weights.y + weights.z
	var w = weights / total if total > 0.0 else Vector3(1, 0, 0)

	sync_streams[ring].set_sync_stream_volume(0, linear_to_db(max(sqrt(w.x), 0.0001)))
	sync_streams[ring].set_sync_stream_volume(1, linear_to_db(max(sqrt(w.y), 0.0001)))
	sync_streams[ring].set_sync_stream_volume(2, linear_to_db(max(sqrt(w.z), 0.0001)))
