class_name SampleTrackPlayer
extends TrackPlayerBase

var BUS_SUFFIXES : Array[String] = ["Main", "Alt", "Rec"]

var BUS_PREFIX : String = "Sample"
var _recent_hits: Dictionary[int, PackedFloat64Array] = {}
var _needs_restore: Array[bool] = [false, false, false]

func _get_bus_suffixes() -> Array[String]:
	return BUS_SUFFIXES

func _get_bus_prefix() -> String:
	return BUS_PREFIX

# --- Public API ---

func set_streams(a: AudioStream, b: AudioStream, rec: AudioStream=null) -> void:
	_recent_hits.clear()
	_needs_restore.fill(false)
	players[0].stream = a
	players[1].stream = b
	if track_data:
		track_data.main_audio_stream = a
		track_data.alt_audio_stream = b
	if rec != null:
		var rec_data = track_data.create_recording_data()
		rec_data.audio_stream = rec
		rec_data.state = RecordingData.State.RECORDING_DONE
		_set_recorded_stream(rec_data)

func _ready() -> void:
	super._ready()
	EventBus.play_track_requested.connect(_on_play_track_requested)

func setup(index: int, parent_bus: String, _settings = null) -> void:
	super.setup(index, parent_bus, _settings)
	

func _on_soundbank_loaded(bank: SoundBank) -> void:
	apply_effect_profile(bank.synth_effect_profiles[0])
	match track_index:
		0:
			set_streams(bank.kick, bank.kick_alt)
		1:
			set_streams(bank.clap, bank.clap_alt)
		2:
			set_streams(bank.snare, bank.snare_alt)
		3:
			set_streams(bank.closed, bank.closed_alt)
	
func _on_play_track_requested(trackIndex: int) -> void:
	if trackIndex == track_index:
		play()


func _on_section_switched(_new : SectionData) -> void:
	
	if _new.tracks[track_index].recording_data and _new.tracks[track_index].recording_data.audio_stream:
		_set_recorded_stream(_new.tracks[track_index].recording_data)
	else:
		# Clear recording stream and flag if new section doesn't have a recording for this track
		players[2].stream = null
		_has_recording = false
	_recent_hits.erase(2)
	_needs_restore[2] = false
	set_weights(_new.tracks[track_index].weights) # apply new section's weights for this track
	set_volume_db(_new.tracks[track_index].master_volume) # apply new section's master volume for this track

func _on_beat_triggered(beat: int) -> void:
	var data := track_data as SampleTrackData
	if data and data.get_beat_active(beat):
		play()

func _set_recorded_stream(recording_data: RecordingData) -> void:
	if recording_data.track_data.index != track_index:
		return
	if recording_data.section_index != track_data.section_index:
		return
	players[2].stream = recording_data.audio_stream
	_recent_hits.erase(2)
	_needs_restore[2] = false
	_has_recording = true
	if track_data:
		track_data.set_recording_audio_stream(recording_data)
	set_weights(track_data.weights)

## Playback control (called by Section when starting/stopping playback)
## Offset: for starting in the middle of a track. Value is in seconds.
func play(offset: float = 0.0) -> void:
	var now: float = _next_mix_time()
	for layer: int in range(players.size()):
		if layer == 2 and not _has_recording:
			continue
		var hits: PackedFloat64Array = _recent_hits.get(layer, PackedFloat64Array())
		hits.append(now - offset)
		if hits.size() > 2:
			hits.remove_at(0)
		_recent_hits[layer] = hits
		var wav: AudioStreamWAV = players[layer].stream as AudioStreamWAV
		if _weights[layer] == 0.0 and wav != null and wav.loop_mode == AudioStreamWAV.LOOP_DISABLED and is_equal_approx(players[layer].pitch_scale, 1.0):
			_needs_restore[layer] = true
		else:
			players[layer].play(offset)

func set_weights(weights: Vector3) -> void:
	super.set_weights(weights)
	var now: float = _next_mix_time()
	for layer: int in range(players.size()):
		if weights[layer] <= 0.0 or not _needs_restore[layer]:
			continue
		players[layer].stop()
		_needs_restore[layer] = false
		var stream: AudioStream = players[layer].stream
		if stream == null:
			continue
		var hits: PackedFloat64Array = _recent_hits.get(layer, PackedFloat64Array())
		for hit: float in hits:
			var offset: float = maxf(0.0, now - hit)
			if offset < stream.get_length():
				players[layer].play(offset)

func _next_mix_time() -> float:
	# Both original and restored voices begin on an audio mix, not the render frame.
	return float(Time.get_ticks_usec()) / 1000000.0 + AudioServer.get_time_to_next_mix()

func _on_all_players_stop() -> void:
	super._on_all_players_stop()
	_recent_hits.clear()
	_needs_restore.fill(false)
