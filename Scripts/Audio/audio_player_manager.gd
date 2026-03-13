extends Node
# Audio Player Manager — manages audio players for rings and sound effects, and handles audio-related events.

const TRACK_COUNT = 6
const VOICE_TRACKS_COUNT = 2
const SAMPLE_TRACKS_COUNT = 4

# Audio Stream Players for 4 rings (main, alt, recorded)
var audio_players: Array[AudioStreamPlayer] = []
var sync_streams: Array[AudioStreamSynchronized] = []

# Audio Stream Players for 2 voice-over synths (green, purple)
var voice_players: Array[AudioStreamPlayer] = []
var voice_sync_streams: Array[AudioStreamSynchronized] = []

var sample_players: Array[AudioStreamPlayer] = []
var sample_sync_streams: Array[AudioStreamSynchronized] = []

var sfx_player: AudioStreamPlayer

# Audio files
@export var main_audio_files: Array[AudioStream] = []
@export var alt_audio_files: Array[AudioStream] = []

@export var metronome_sfx: AudioStream
@export var metronome_alt_sfx: AudioStream
@export var achievement_sfx: AudioStream

func _ready():
	_init_audio_players()
	_init_sfx_player()

	# Connect to EventBus instead of direct manager references
	EventBus.play_ring_requested.connect(play_sample_track)
	EventBus.set_track_volume_requested.connect(set_track_volume)
	EventBus.play_sfx_requested.connect(play_sfx)
	EventBus.beat_triggered.connect(_on_beat_pitch_randomization)
	EventBus.request_set_stream.connect(_on_request_set_stream)
	EventBus.request_mute_all.connect(_mute_all)

func _mute_all(mute: bool):
	var volume_db = -80.0 if mute else 0.0
	for player in audio_players:
		player.volume_db = volume_db
	for player in voice_players:
		player.volume_db = volume_db
	sfx_player.volume_db = volume_db

func _init_sfx_player():
	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)

func _init_audio_players():
	for i in range(TRACK_COUNT):
		# Check if we have enough audio files
		if i >= main_audio_files.size() or i >= alt_audio_files.size():
			printerr("Not enough main or alt audio files for track %d" % i)
			continue
		var sync_stream = AudioStreamSynchronized.new()
		sync_stream.stream_count = 3
		
		if i >= SAMPLE_TRACKS_COUNT:
			# For synth tracks, start with silent streams until set
			sync_stream.set_sync_stream(0, _create_silent_stream())
			sync_stream.set_sync_stream(1, _create_silent_stream())
		else:
			sync_stream.set_sync_stream(0, main_audio_files[i])
			sync_stream.set_sync_stream(1, alt_audio_files[i])
	
		sync_stream.set_sync_stream(2, _create_silent_stream())
		
		# Start all silent except main
		sync_stream.set_sync_stream_volume(0, 0.0)
		sync_stream.set_sync_stream_volume(1, -80.0)
		sync_stream.set_sync_stream_volume(2, -80.0)
		
		var player = AudioStreamPlayer.new()
		player.bus = "Track" + str(i)
		player.stream = sync_stream
		add_child(player)
		
		audio_players.append(player)
		sync_streams.append(sync_stream)

		if i < SAMPLE_TRACKS_COUNT:
			sample_players.append(player)
			sample_sync_streams.append(sync_stream)
		else:
			voice_players.append(player)
			voice_sync_streams.append(sync_stream)

func play_sample_track(track: int):
	if track < 0 or track >= SAMPLE_TRACKS_COUNT:
		printerr("Invalid track index %d for play_sample_track" % track)
		return
	audio_players[track].play()

func play_sfx(stream: AudioStream):
	"""Play a sound effect"""
	if stream:
		sfx_player.stream = stream
		sfx_player.play()

# Voice-over playback
func play_voice(synth_index: int):
	voice_players[synth_index].play()

func stop_voice(synth_index: int):
	voice_players[synth_index].stop()

func is_track_playing(track_index: int) -> bool:
	return audio_players[track_index].playing
	
func get_voice_playback_position(synth_index: int) -> float:
	return voice_players[synth_index].get_playback_position()

#TODO: ALSO UPDATE THE VOICE STREAM IN THE SECTIONDATA
func set_voice_stream(synth_index: int, audio: AudioStream):
	var stream = audio if audio else _create_silent_stream()
	voice_sync_streams[synth_index].set_sync_stream(0, stream)
	voice_sync_streams[synth_index].set_sync_stream(1, stream)
	voice_sync_streams[synth_index].set_sync_stream(2, stream)

#Signal handlers
func _on_beat_pitch_randomization(_beat: int):
	if audio_players.size() > 3:
		var strength = 0.2
		var pitch = 1.0 + (randf() - 0.5) * strength
		audio_players[3].pitch_scale = pitch

func _on_request_set_stream(track: int, audio_layer: int, audio: AudioStream):
	if track >= 0 and track < sync_streams.size():
		sync_streams[track].set_sync_stream(audio_layer, audio)


func get_track_volume(track: int) -> float:
	"""Get the volume for a specific track bus"""
	if track < 0 or track >= TRACK_COUNT:
		printerr("Invalid track index %d for get_track_volume" % track)
		return 0.0
	
	var bus_index = AudioServer.get_bus_index("Track" + str(track))
	var left = AudioServer.get_bus_peak_volume_left_db(bus_index, 0)
	var right = AudioServer.get_bus_peak_volume_right_db(bus_index, 0)
	return db_to_linear((left + right) / 2.0)

func set_track_volume(track: int, weights: Vector3):
	"""Set the volume for a specific track bus based on master volume and weights for main, alt, and rec"""
	if track < 0 or track >= TRACK_COUNT:
		return
	
	# Normalize weights to ensure they sum to 1
	var total = weights.x + weights.y + weights.z
	var w = weights / total if total > 0.0 else Vector3(1, 0, 0)

	sync_streams[track].set_sync_stream_volume(0, linear_to_db(max(sqrt(w.x), 0.0001)))
	sync_streams[track].set_sync_stream_volume(1, linear_to_db(max(sqrt(w.y), 0.0001)))
	sync_streams[track].set_sync_stream_volume(2, linear_to_db(max(sqrt(w.z), 0.0001)))


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
