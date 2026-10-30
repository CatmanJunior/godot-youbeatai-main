extends Node
## Run the song_loading_test.tscn scene with Godot --headless --path .

const TEST_SAVE_PATH: String = "user://_song_loading_test.tres"
const SAMPLE_WEIGHTS: Vector3 = Vector3(0.1, 0.2, 0.7)
const SONG_WEIGHTS: Vector3 = Vector3(0.6, 0.3, 0.1)

var _failures: int = 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	reparent(get_tree().root)
	get_tree().create_timer(45.0).timeout.connect(func() -> void:
		push_error("Song loading test timed out.")
		get_tree().quit(1)
	)
	GameState.mute_speech = true
	GameState.use_achievements = false
	var song: SongData = _make_song()
	var bytes: PackedByteArray = _song_bytes(song)
	if bytes.is_empty():
		get_tree().quit(1)
		return

	_check(get_tree().change_scene_to_file(SceneChanger.SCENE_MAIN_MENU) == OK, "Open main menu")
	await get_tree().scene_changed
	var menu_loader: SongSaveLoadManager = get_tree().current_scene.get_node("MainMenuPanel/SongSaveLoadManager")
	EventBus.song_loaded.connect(_check_loading_overlay)
	menu_loader._load_from_bytes(bytes, "regression.ritme")
	var overlay: Node = get_tree().root.get_node_or_null("SongLoadingOverlay")
	_check(overlay != null, "Overlay appears before loading work")
	await get_tree().scene_changed
	_check(get_tree().root.get_node_or_null("SongLoadingOverlay") == overlay, "Overlay survives main-menu transition")
	await EventBus.song_loaded
	for frame: int in range(3):
		await get_tree().process_frame
	_check(get_tree().root.get_node_or_null("SongLoadingOverlay") == null, "Overlay closes after main-menu load")
	_check(SongState.pending_song == null, "Pending song consumed")
	_check_loaded_song(song)
	EventBus.track_selected.emit(SongTrackData.SONG_TRACK_INDEX)
	_check(SongState.song_track.weights.is_equal_approx(SONG_WEIGHTS), "Selecting loaded song track preserves its mix")
	_check(SongState.song_track.knob_position == song.song_track.knob_position, "Selecting loaded song track preserves its knob")
	EventBus.track_selected.emit(0)
	await get_tree().process_frame

	var current_scene: Node = get_tree().current_scene
	var loader: SongSaveLoadManager = current_scene.get_node("Managers/SongSaveLoadManager")
	for iteration: int in range(3):
		var saved_bytes: PackedByteArray = loader._serialize_current_song()
		_check(not saved_bytes.is_empty(), "Serialize restored song")
		await loader._load_from_bytes(saved_bytes, "roundtrip_%d.ritme" % iteration)
		_check(get_tree().root.get_node_or_null("SongLoadingOverlay") == null, "Overlay closes after in-game load")
		_check_loaded_song(song)

	EventBus.section_switch_requested.emit(0)
	_check_waveforms(false)
	EventBus.section_switch_requested.emit(1)
	_check_waveforms(true)

	var empty_song: SongData = _make_song()
	empty_song.chosen_emoij = ""
	empty_song.beats_per_section = 8
	empty_song.current_section_index = 0
	empty_song.song_track = null
	for section: SectionData in empty_song.sections:
		for track: TrackData in section.tracks:
			track.recorded_audio_stream = null
	empty_song.soundbank.synth_effect_profiles[0].pitch_shift = 0.0
	empty_song.soundbank.synth_effect_profiles[0].reverb = 0.0
	empty_song.chosen_emoij = String.chr(0x1F680)
	await loader._load_from_bytes(_song_bytes(empty_song), "different_theme.ritme")
	var emoji_label: Label = current_scene.get_node("UserInterface/ChosenEmoij's")
	_check(emoji_label.text == empty_song.chosen_emoij, "Replace theme during in-game load")
	empty_song.chosen_emoij = ""
	await loader._load_from_bytes(_song_bytes(empty_song), "empty.ritme")
	_check_waveforms(false)
	_check(emoji_label.text == SongState.CHOSEN_EMOIJ_DEFAULT, "Legacy emoji fallback replaces previous theme")
	var audio: AudioPlayerManager = current_scene.get_node("Managers/AudioManagers/AudioPlayerManager")
	for layer: int in [SongTrackPlayer.SongLayer.MIX, SongTrackPlayer.SongLayer.VOICE_OVER]:
		_check(audio.song_track_player.players[layer].stream == null, "Clear previous song recording")
	var ring: BeatRingUI = current_scene.get_node("UserInterface/BeatRing")
	_check(ring._beat_buttons[0].size() == 8, "Rebuild shorter beat grid")
	var bus_index: int = AudioServer.get_bus_index("Synth4_Alt")
	_check(not AudioServer.is_bus_effect_enabled(bus_index, EffectProfile.EffectType.PITCH_SHIFT), "Disable old pitch effect")
	_check(not AudioServer.is_bus_effect_enabled(bus_index, EffectProfile.EffectType.REVERB), "Disable old reverb effect")
	_check(AudioServer.get_bus_effect_count(bus_index) == 6, "Replacing profile keeps one chain")

	var failures_reported: Array[String] = []
	EventBus.song_file_failed.connect(func(message: String) -> void: failures_reported.append(message))
	await loader._load_from_bytes("not a song".to_utf8_buffer(), "invalid.ritme")
	_check(failures_reported.size() == 1, "Rejected file reports an error")
	_check(get_tree().root.get_node_or_null("SongLoadingOverlay") == null, "Rejected file clears overlay")
	await loader._on_load_path_selected("user://_missing_loading_test.ritme")
	_check(failures_reported.size() == 2, "Unreadable file reports an error")
	_check(get_tree().root.get_node_or_null("SongLoadingOverlay") == null, "Unreadable file clears overlay")

	EventBus.all_players_stop_requested.emit()
	print("Song loading regression tests: %s" % ("PASS" if _failures == 0 else "%d failures" % _failures))
	get_tree().quit(0 if _failures == 0 else 1)


func _make_song() -> SongData:
	var song := SongData.new()
	song.format_version = SongData.FORMAT_VERSION
	song.bpm = 137
	song.swing = 0.12
	song.beats_per_section = 32
	song.current_section_index = 1
	song.chosen_emoij = String.chr(0x1F3B5) + String.chr(0x1F31F)
	song.soundbank = load("res://Resources/Audio/SoundBanks/6_rock/6_rock.tres").duplicate(true) as SoundBank
	song.soundbank.synth_effect_profiles[0].pitch_shift = 1.25
	song.soundbank.synth_effect_profiles[0].reverb = 0.65
	var texture: Texture2D = load("res://Resources/Icons/Icons-_28_0029_Leaf.png")
	for index: int in range(2):
		var section := SectionData.new(texture, index)
		section.create_default_tracks()
		section.loop_count = index + 2
		for track: TrackData in section.tracks:
			if track is SampleTrackData:
				track.beats.resize(song.beats_per_section)
		song.sections.append(section)
	song.sections[1].set_beat(0, 31, true)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 22050
	wav.data = PackedByteArray([0, 20, 40, 60, 80, 60, 40, 20])
	for index: int in [0, SectionData.SAMPLE_TRACKS_PER_SECTION]:
		var track: TrackData = song.sections[1].tracks[index]
		track.recorded_audio_stream = wav
		track.weights = SAMPLE_WEIGHTS
		track.master_volume = -8.0
	song.song_track = SongTrackData.new()
	song.song_track.knob_position = Vector2(280.0, 300.0)
	song.song_track.recorded_audio_stream = wav
	song.song_track.weights = SONG_WEIGHTS
	song.song_track.master_volume = -6.0
	return song


func _song_bytes(song: SongData) -> PackedByteArray:
	var error: Error = song.save_to_file(TEST_SAVE_PATH)
	_check(error == OK, "Save test fixture")
	if error != OK:
		return PackedByteArray()
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(TEST_SAVE_PATH)
	DirAccess.remove_absolute(TEST_SAVE_PATH)
	return bytes


func _check_loaded_song(expected: SongData) -> void:
	var current_scene: Node = get_tree().current_scene
	_check(SongState.bpm == expected.bpm, "Restore BPM after bank defaults")
	_check(is_equal_approx(SongState.swing, expected.swing), "Restore swing")
	_check(SongState.current_section_index == 1, "Restore selected section")
	_check(SongState.sections.size() == 2, "Replace initial sections")
	_check(SongState.sections[1].loop_count == 3, "Restore loop counts")
	_check(SongState.sections[1].get_beat(0, 31), "Restore beat pattern")
	var emoji_label: Label = current_scene.get_node("UserInterface/ChosenEmoij's")
	_check(emoji_label.text == expected.chosen_emoij, "Refresh theme emojis")
	var audio: AudioPlayerManager = current_scene.get_node("Managers/AudioManagers/AudioPlayerManager")
	for index: int in [0, SectionData.SAMPLE_TRACKS_PER_SECTION]:
		var track: TrackData = SongState.sections[1].tracks[index]
		_check(track.weights.is_equal_approx(SAMPLE_WEIGHTS), "Preserve saved mix weights")
		_check(is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(audio.track_players[index].bus_name)), -8.0), "Restore track volume")
		_check(audio.track_players[index].players[2].stream == track.recorded_audio_stream, "Restore track recording")
	for layer: int in [SongTrackPlayer.SongLayer.MIX, SongTrackPlayer.SongLayer.VOICE_OVER]:
		_check(audio.song_track_player.players[layer].stream == SongState.song_track.recorded_audio_stream, "Restore song recording")
	_check(SongState.song_track.weights.is_equal_approx(SONG_WEIGHTS), "Restore song mix")
	_check(is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(audio.song_track_player.bus_name)), -6.0), "Restore song volume")
	for bus_name: String in ["Synth4_Alt", "Synth4_NotePlayer", "Synth5_Alt", "Synth5_NotePlayer", "Song6_Mix", "Song6_Chord"]:
		var bus_index: int = AudioServer.get_bus_index(bus_name)
		_check(AudioServer.get_bus_effect_count(bus_index) == 6, "Exactly one effect chain on %s" % bus_name)
	var effect_bus: int = AudioServer.get_bus_index("Synth4_Alt")
	var pitch: AudioEffectPitchShift = AudioServer.get_bus_effect(effect_bus, EffectProfile.EffectType.PITCH_SHIFT) as AudioEffectPitchShift
	var reverb: AudioEffectReverb = AudioServer.get_bus_effect(effect_bus, EffectProfile.EffectType.REVERB) as AudioEffectReverb
	_check(is_equal_approx(pitch.pitch_scale, 1.25), "Restore pitch value")
	_check(is_equal_approx(reverb.room_size, 0.65), "Restore reverb value")
	var ring: BeatRingUI = current_scene.get_node("UserInterface/BeatRing")
	_check(ring._beat_buttons[0].size() == 32, "Rebuild longer beat grid")
	_check_waveforms(true)


func _check_waveforms(recorded: bool) -> void:
	var visualizer: TrackWaveformVisualizer = get_tree().current_scene.get_node("UserInterface/BeatRing/Waveform_visualisers")
	_check(visualizer.waveform_lines[0].visible == recorded, "Recorded waveform visibility")
	_check(visualizer.waveform_lines[0].points.is_empty() != recorded, "Clear or restore waveform points")
	_check(is_equal_approx(visualizer.progress_bars[0].value, 0.0 if recorded else 1.0), "Placeholder and waveform never overlap")
	_check(not visualizer.waveform_lines[1].visible, "Unrecorded second synth has no stale waveform")
	_check(is_equal_approx(visualizer.progress_bars[1].value, 1.0), "Unrecorded second synth keeps placeholder")


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAIL: %s" % message)


func _check_loading_overlay() -> void:
	var overlay: CanvasLayer = get_tree().root.get_node_or_null("SongLoadingOverlay") as CanvasLayer
	_check(overlay != null and overlay.visible, "Overlay stays visible during song/UI restoration")
	if overlay != null:
		var background: ColorRect = overlay.get_node("Background")
		_check(background.size.is_equal_approx(get_viewport().get_visible_rect().size), "Overlay covers the full viewport")
		_check(background.mouse_filter == Control.MOUSE_FILTER_STOP, "Overlay blocks pointer input")
