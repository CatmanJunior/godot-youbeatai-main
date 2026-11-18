extends Node

const RecorderScript = preload("res://Scripts/Audio/track_recorder.gd")
const SynthRecorderScript = preload("res://Scripts/Audio/synth_voice_recorder.gd")
const SavingLabelScript = preload("res://Scripts/UI/saving_label.gd")

class RecoverySongPlayer extends SongTrackPlayer:
	var last_offset: float = -1.0

	func play(offset: float = 0.0) -> void:
		last_offset = offset

var _failures: int = 0

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	reparent(get_tree().root)
	get_tree().create_timer(45.0).timeout.connect(func() -> void:
		push_error("Performance tests timed out.")
		get_tree().quit(1)
	)
	GameState.mute_speech = true
	GameState.use_achievements = false
	SongState.selected_soundbank = load("res://Resources/Audio/SoundBanks/6_rock/6_rock.tres") as SoundBank
	get_tree().change_scene_to_file(SceneChanger.SCENE_MAIN)
	await get_tree().scene_changed
	for frame: int in range(4):
		await get_tree().process_frame
	var scene: Node = get_tree().current_scene
	var clock: BeatManager = scene.get_node("Managers/BeatManager")
	clock.set_process(false)
	PerformanceSettings.set_process(false)
	_test_settings(scene.get_node("UserInterface/SettingsPanel"))
	_test_ring(scene.get_node("UserInterface/BeatRing"))
	_test_clock(clock)
	_test_song_recovery()
	_test_analysis()
	_test_waveform()
	_test_silent_layers(scene.get_node("Managers/AudioManagers/AudioPlayerManager"))
	_test_recording(scene)
	await _test_export_interruption(scene)
	_test_quality()
	EventBus.all_players_stop_requested.emit()
	print("Performance regression tests: %s" % ("PASS" if _failures == 0 else "%d failures" % _failures))
	if OS.get_cmdline_user_args().has("--performance-ui-check"):
		EventBus.toggle_settings_menu_requested.emit()
		await get_tree().create_timer(1.0).timeout
		print("PERFORMANCE_UI_READY")
		await get_tree().create_timer(5.0).timeout
	get_tree().quit(0 if _failures == 0 else 1)

func _test_settings(settings: SettingsUI) -> void:
	var was_visible: bool = settings.is_visible
	var mode: int = GameState.performance_mode
	_check(not settings.has_node("QualityOption"), "Performance selector is temporarily absent")
	EventBus.toggle_settings_menu_requested.emit()
	_check(settings.is_visible != was_visible, "Settings still toggles without the performance selector")
	EventBus.toggle_settings_menu_requested.emit()
	_check(settings.is_visible == was_visible, "Settings can be closed again")
	_check(GameState.performance_mode == mode, "Opening settings preserves the performance preference")

func _test_ring(ring: BeatRingUI) -> void:
	for track: int in range(4):
		for beat: int in range(2):
			SongState.current_section.set_beat(track, beat, true)
	for steps: int in [8, 16, 32]:
		SongState.beats_per_section = steps
		ring._on_song_loaded()
		ring._reset_scales()
		_check(ring._beat_buttons[0].size() == steps, "Grid rebuild uses the requested step count")
		ring._update_beat_sprites(0)
		_check(ring._scale_tweens.size() == 4, "Only the first active column creates tweens")
		ring._update_beat_sprites(1)
		_check(ring._scale_tweens.size() <= 8, "At most two columns animate per step")
		_check(not ring._scale_tweens.has(ring._beat_buttons[0][5]), "Unchanged buttons do not create tweens")
		ring._reset_scales()
		_check(ring._scale_tweens.is_empty(), "Reset kills all scale tweens")
	SongState.beats_per_section = 16
	ring._on_song_loaded()

func _test_clock(clock: BeatManager) -> void:
	EventBus.bpm_set_requested.emit(120)
	EventBus.swing_set_requested.emit(0.2)
	var events: Array[int] = [0, 0]
	var beat_callback: Callable = func(_beat: int) -> void: events[0] += 1
	var recovery_callback: Callable = func(_steps: int, _loops: int) -> void: events[1] += 1
	EventBus.beat_triggered.connect(beat_callback)
	EventBus.transport_resynchronised.connect(recovery_callback)
	clock.current_beat = 0
	clock.last_beat_time = 1000.0
	clock._advance_clock(1100.0)
	_check(events[0] == 1 and GameState.current_beat == 1, "Normal swung beat fires once")
	clock.current_beat = 0
	clock.last_beat_time = 1000.0
	events[0] = 0
	clock._advance_clock(1375.0)
	_check(events[0] == 0 and events[1] == 1, "Stall resynchronises without stale beats")
	_check(GameState.current_beat == 3, "Recovery preserves musical step")
	_check(is_equal_approx(BeatManager.get_section_playback_time(), 0.375), "Recovery preserves swung playback offset")
	clock.current_beat = 0
	clock.last_beat_time = 1000.0
	clock._advance_clock(3601000.0)
	_check(events[0] == 0 and GameState.current_beat == 0, "Long suspension does not replay missed steps")
	GameState.song_mode_active = true
	for section: SectionData in SongState.sections:
		section.loop_count = 2
	GameState.loop_cursor = 0
	EventBus.transport_loops_skipped.emit(5)
	_check(SongState.current_section_index == 2 and GameState.loop_cursor == 1, "Skipped loops update section and loop cursor")
	EventBus.section_switch_requested.emit(0)
	GameState.song_mode_active = false
	EventBus.beat_triggered.disconnect(beat_callback)
	EventBus.transport_resynchronised.disconnect(recovery_callback)
	EventBus.swing_set_requested.emit(0.0)

func _test_analysis() -> void:
	var samples := PackedFloat32Array()
	samples.resize(22050)
	for i: int in range(samples.size()):
		samples[i] = 0.25 * sin(TAU * 220.0 * float(i) / 11025.0)
	var reference := VoiceAnalyzer.new()
	reference.summary_diagnostics_enabled = false
	reference.start(11025.0, 16, 0.125)
	var started: int = Time.get_ticks_usec()
	reference.push_samples(samples)
	var synchronous_ms: float = float(Time.get_ticks_usec() - started) / 1000.0
	var expected: Sequence = reference.finalize()
	_check(expected.notes[4].note == 57, "220 Hz is still detected as A3")
	var legacy := VoiceAnalyzer.new()
	legacy.summary_diagnostics_enabled = false
	legacy.start(11025.0, 16, 0.125)
	legacy.push_samples(samples, 0)
	legacy.begin_staged_finalize()
	var legacy_longest_ms: float = 0.0
	while legacy.is_staged_finalizing():
		started = Time.get_ticks_usec()
		legacy.process_finalize_step(2, 0)
		legacy_longest_ms = maxf(legacy_longest_ms, float(Time.get_ticks_usec() - started) / 1000.0)
	var incremental := VoiceAnalyzer.new()
	incremental.summary_diagnostics_enabled = false
	incremental.start(11025.0, 16, 0.125)
	incremental.push_samples(samples, 0)
	incremental.begin_staged_finalize()
	var calls: int = 0
	var longest_ms: float = 0.0
	while incremental.is_staged_finalizing() and calls < 10000:
		started = Time.get_ticks_usec()
		incremental.process_finalize_step(2, 2000)
		longest_ms = maxf(longest_ms, float(Time.get_ticks_usec() - started) / 1000.0)
		calls += 1
	_check(not incremental.is_staged_finalizing(), "Budgeted analysis finishes")
	_check(incremental._frame_results == reference._frame_results, "Budgeting preserves every pitch/RMS result")
	var actual: Sequence = incremental.get_staged_sequence()
	_check(actual.notes.size() == expected.notes.size(), "Budgeting preserves sequence length")
	for i: int in range(mini(actual.notes.size(), expected.notes.size())):
		_check(actual.notes[i].note == expected.notes[i].note and is_equal_approx(actual.notes[i].velocity, expected.notes[i].velocity), "Budgeting preserves quantised note")
	_check(calls > 4, "Analysis yields across multiple steps")
	_check(longest_ms < 20.0, "No full-analysis blocking step on the test host")
	print("Analysis benchmark: synchronous=%.3f ms, two-hop max=%.3f ms, budgeted max=%.3f ms, steps=%d" % [synchronous_ms, legacy_longest_ms, longest_ms, calls])
	expected.free()
	actual.free()
	legacy.get_staged_sequence().free()
	var delayed := VoiceAnalyzer.new()
	delayed.recording_delay_seconds = 0.8
	delayed.start(11025.0, 8, 0.075)
	_check(delayed._analysis_buffer.size() >= int(1.5 * 11025.0), "Short loops retain delay-compensation capture headroom")

func _test_song_recovery() -> void:
	var player := RecoverySongPlayer.new()
	GameState.song_mode_active = true
	EventBus.swing_set_requested.emit(0.2)
	for section: int in [0, 2]:
		EventBus.section_switch_requested.emit(section)
		GameState.current_beat = 3
		GameState.beat_progress = 0.5
		GameState.loop_cursor = 1
		player._on_transport_resynchronised(3, 0)
		_check(is_equal_approx(player.last_offset, section * 4.0 + 2.425), "Song recovery includes section, loop, swung beat and fractional progress")
	player.free()
	EventBus.section_switch_requested.emit(0)
	EventBus.beat_seek_requested.emit(0)
	GameState.loop_cursor = 0
	GameState.song_mode_active = false
	EventBus.swing_set_requested.emit(0.0)

func _make_wav() -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	var bytes := PackedByteArray()
	bytes.resize(44100 * 2)
	for i: int in range(44100):
		bytes.encode_s16(i * 2, int(8000.0 * sin(TAU * 220.0 * float(i) / wav.mix_rate)))
	wav.data = bytes
	return wav

func _test_waveform() -> void:
	var wav: AudioStreamWAV = _make_wav()
	var old_line := Line2D.new()
	var new_line := Line2D.new()
	var reference := SynthWaveform.new(old_line, 196)
	var compact := SynthWaveform.new(new_line, 196)
	reference.update_line(VoiceProcessor.get_samples(wav), wav.mix_rate, wav.get_length())
	compact.update_from_wav(wav)
	_check(compact.offsets.size() == reference.offsets.size(), "Compact waveform preserves point count")
	for i: int in range(compact.offsets.size()):
		_check(compact.offsets[i].is_equal_approx(reference.offsets[i]), "Compact waveform preserves displayed shape")
	old_line.free()
	new_line.free()

func _test_silent_layers(audio: AudioPlayerManager) -> void:
	var player: SampleTrackPlayer = audio.track_players[0] as SampleTrackPlayer
	player.set_streams(_make_wav(), _make_wav())
	player._on_all_players_stop()
	player.set_weights(Vector3(1, 0, 0))
	player.play()
	_check(player.players[0].playing and not player.players[1].playing, "Zero-weight one-shot is not started")
	player.set_weights(Vector3(0, 1, 0))
	_check(player.players[1].playing and not player._needs_restore[1], "Crossfade restores the active skipped tail")
	player._on_all_players_stop()
	player.set_weights(Vector3(1, 0, 0))
	player.play()
	player._recent_hits[1] = PackedFloat64Array([float(Time.get_ticks_usec()) / 1000000.0 - 4.0])
	player.set_weights(Vector3(0, 1, 0))
	_check(not player.players[1].playing, "Expired samples are not replayed")
	player._on_all_players_stop()

func _test_recording(scene: Node) -> void:
	var recorder: RecorderScript = scene.get_node("Managers/AudioManagers/TrackRecorder")
	var synth: SynthRecorderScript = scene.get_node("Managers/AudioManagers/SynthRecorder")
	var status: SavingLabelScript = scene.get_node("UserInterface/SavingLabel")
	var messages: Array[String] = []
	var callback: Callable = func(message: String) -> void: messages.append(message)
	EventBus.status_message_requested.connect(callback)
	var track: SynthTrackData = SongState.get_track(0, 4) as SynthTrackData
	var previous := RecordingData.new(track, _make_wav())
	track.recording_data = previous
	track.recorded_audio_stream = previous.audio_stream
	recorder.current_recording_data = RecordingData.new(track)
	recorder.pre_recording_volume = AudioServer.get_bus_volume_db(0)
	GameState.is_recording = true
	EventBus.recording_interrupted.emit()
	_check(not GameState.is_recording and recorder.current_recording_data == null, "Interrupted recording clears capture state")
	_check(track.recording_data == previous and track.recorded_audio_stream == previous.audio_stream, "Interrupted recording preserves previous take")
	_check(messages.size() == 1 and status.visible, "Recording interruption still shows retry feedback")
	messages.clear()
	status._process(4.1)
	var completed := RecordingData.new(track, _make_wav())
	synth._on_recording_started(completed)
	synth._on_recording_stopped(completed)
	_check(GameState.is_processing_recording and synth._post_stop_processing_active, "Conversion still starts without an overlay")
	_check(messages.is_empty() and not status.visible, "Starting conversion does not show a processing overlay")
	recorder._start_recording()
	_check(recorder.current_recording_data == null, "New recording cannot synchronously flush analysis")
	_check(messages.is_empty() and not status.visible, "Busy recording requests do not show a processing overlay")
	EventBus.saving_completed.emit("user://test.ritme")
	_check(status.visible, "Save confirmations remain visible during conversion")
	status._process(4.1)
	_check(not status.visible, "Conversion does not keep unrelated notifications visible indefinitely")
	EventBus.section_switch_requested.emit(1)
	var sequence := Sequence.new([])
	synth._emit_sequence_ready(sequence, completed)
	_check(track.recording_data == completed and track.sequence != null, "Completion updates its original section after switching")
	_check(not GameState.is_processing_recording and messages.is_empty() and not status.visible, "Conversion completes without a completion overlay")
	track.sequence.free()
	track.sequence = null
	EventBus.section_switch_requested.emit(0)
	EventBus.status_message_requested.disconnect(callback)

func _test_export_interruption(scene: Node) -> void:
	var exporter: Exporter = scene.get_node("Managers/Exporter")
	var ui: ExportUI = scene.get_node("Managers/Exporter/ExportUI")
	var exported: Array[int] = [0]
	var callback: Callable = func(_data: ExportRecordingData) -> void: exported[0] += 1
	EventBus.export_recording_requested.connect(callback)
	EventBus.export_requested.emit(false, false)
	_check(GameState.is_exporting and ui.started, "Export marks its startup as busy")
	EventBus.export_failed.emit("Test: export onderbroken.")
	for frame: int in range(3):
		await get_tree().process_frame
	await get_tree().create_timer(0.15).timeout
	_check(not exporter.recording and not exporter.recorder.is_recording_active() and not GameState.is_exporting, "Cancelled export cannot restart after awaiting startup")
	_check(not ui.started and not ui.loading.visible and exported[0] == 0, "Cancelled export closes its UI without exporting a partial mix")
	exporter.recorder.set_recording_active(true)
	exporter.recording = true
	GameState.is_exporting = true
	exporter.stop_recording()
	EventBus.export_failed.emit("Test: export onderbroken.")
	await get_tree().create_timer(0.15).timeout
	_check(not exporter.recorder.is_recording_active() and exported[0] == 0, "Cancelled export cannot finish after awaiting its recording tail")
	EventBus.export_recording_requested.disconnect(callback)

func _test_quality() -> void:
	GameState.performance_mode = 0
	GameState.lightweight_graphics = false
	PerformanceSettings._slow_windows = 0
	PerformanceSettings._reset_window()
	for i: int in range(200):
		PerformanceSettings.record_frame(35.0)
	PerformanceSettings._process(0.0)
	_check(GameState.lightweight_graphics, "Auto detects sustained slow frames")
	GameState.performance_mode = 1
	PerformanceSettings._process(0.0)
	_check(not GameState.lightweight_graphics, "Manual Normal overrides automatic downgrade")
	GameState.performance_mode = 2
	GameState.is_recording = true
	PerformanceSettings._process(0.0)
	_check(not GameState.lightweight_graphics, "Quality change waits until recording finishes")
	GameState.is_recording = false
	PerformanceSettings._process(0.0)
	_check(GameState.lightweight_graphics, "Pending quality applies safely")
	var robot: Node = get_tree().current_scene.get_node("UserInterface/Robot/Robot")
	_check(robot.viewport_container.stretch_shrink == 2, "Lightweight mode reduces actual robot viewport resolution")
	PerformanceSettings._on_scene_changed()
	PerformanceSettings.record_frame(35.0)
	PerformanceSettings._process(0.0)
	_check(PerformanceSettings._frames.is_empty(), "Startup frames are excluded")
	_check(GameState.performance_mode == 2 and GameState.lightweight_graphics, "Manual choice survives scene changes")
	PerformanceSettings._ignore_until_usec = 0
	PerformanceSettings._focused = false
	PerformanceSettings.record_frame(35.0)
	PerformanceSettings._process(0.0)
	_check(PerformanceSettings._frames.is_empty(), "Background frames are excluded")
	PerformanceSettings._focused = true
	PerformanceSettings._on_sampling_paused(true)
	PerformanceSettings._ignore_until_usec = 0
	PerformanceSettings.record_frame(35.0)
	PerformanceSettings._process(0.0)
	_check(PerformanceSettings._frames.is_empty(), "Loading frames are excluded")
	PerformanceSettings._on_sampling_paused(false)
	if OS.has_feature("web"):
		EventBus.performance_mode_requested.emit(1)
		GameState.performance_mode = 0
		PerformanceSettings._load_preference()
		_check(GameState.performance_mode == 1, "Manual preference reloads from disk")
		EventBus.performance_mode_requested.emit(0)

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAIL: " + message)
