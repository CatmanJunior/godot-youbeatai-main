class_name SynthVoiceOverManager

extends Node

## Manages playback of synth voice-over tracks.
## Handles playing, stopping, and stream management for 2 synth tracks.

const SYNTH_TRACK_COUNT = 2
const SAMPLE_TRACK_COUNT = 4

# Voice-over audio players (synth tracks 0 and 1)
var voice_players: Array[AudioStreamPlayer] = []
var voice_sync_streams: Array[AudioStreamSynchronized] = []

func _ready():
	# Initialize voice players from AudioPlayerManager if available
	var audio_player_manager = get_node_or_null("%AudioPlayerManager")
	if audio_player_manager:
		voice_players = audio_player_manager.voice_players
		voice_sync_streams = audio_player_manager.voice_sync_streams
	
	# Listen for stream update requests
	EventBus.set_stream_requested.connect(_on_request_set_stream)


## Play a synth voice-over track
func play_voice(synth_index: int) -> void:
	if _is_valid_synth_index(synth_index):
		voice_players[synth_index].play()


## Stop a synth voice-over track
func stop_voice(synth_index: int) -> void:
	if _is_valid_synth_index(synth_index):
		voice_players[synth_index].stop()


## Set the audio stream for a synth voice-over track
func set_voice_stream(synth_index: int, audio: AudioStream) -> void:
	if not _is_valid_synth_index(synth_index):
		return
	
	var stream = audio if audio else _create_silent_stream()
	voice_sync_streams[synth_index].set_sync_stream(0, stream)
	voice_sync_streams[synth_index].set_sync_stream(1, stream)
	voice_sync_streams[synth_index].set_sync_stream(2, stream)


## Get the current playback position of a synth voice-over track
func get_voice_playback_position(synth_index: int) -> float:
	if _is_valid_synth_index(synth_index):
		return voice_players[synth_index].get_playback_position()
	return 0.0


## Check if a synth voice-over track is currently playing
func is_voice_playing(synth_index: int) -> bool:
	if _is_valid_synth_index(synth_index):
		return voice_players[synth_index].playing
	return false


## Handle stream update requests from EventBus
func _on_request_set_stream(track: int, audio_layer: int, audio: AudioStream) -> void:
	# Only handle synth tracks
	if SongState.current_section.tracks[track].track_type == TrackData.TrackType.SYNTH:
		var synth_index = track - SAMPLE_TRACK_COUNT
		set_voice_stream(synth_index, audio)


## Helper: Check if synth index is valid
func _is_valid_synth_index(synth_index: int) -> bool:
	return synth_index >= 0 and synth_index < SYNTH_TRACK_COUNT and synth_index < voice_players.size()


## Helper: Create a silent audio stream
func _create_silent_stream() -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.stereo = false
	wav.mix_rate = AudioServer.get_mix_rate()
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.data = PackedByteArray([0, 0])  # single silent sample, loops
	return wav
