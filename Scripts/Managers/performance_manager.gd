extends Node

enum Mode { AUTO, NORMAL, LIGHTWEIGHT }

const SETTINGS_PATH: String = "user://performance.cfg"
const WINDOW_SECONDS: float = 3.0
const MAX_SAMPLES: int = 360
const SLOW_FRAME_MS: float = 25.0

var diagnostics_enabled: bool = false
var _frames: PackedFloat64Array = PackedFloat64Array()
var _metrics: Dictionary[StringName, PackedFloat64Array] = {}
var _elapsed: float = 0.0
var _slow_windows: int = 0
var _sampling_paused: bool = false
var _focused: bool = true
var _ignore_until_usec: int = 0
var _last_frame_usec: int = 0

func _ready() -> void:
	diagnostics_enabled = OS.get_cmdline_user_args().has("--performance-diagnostics")
	EventBus.performance_mode_requested.connect(_on_mode_requested)
	EventBus.performance_sample.connect(_on_sample)
	EventBus.performance_sampling_paused.connect(_on_sampling_paused)
	get_tree().scene_changed.connect(_on_scene_changed)
	_load_preference()
	_set_quality(GameState.performance_mode == Mode.LIGHTWEIGHT)
	_on_scene_changed()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_focused = false
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_focused = true
		_reset_window()

func _process(_delta: float) -> void:
	if not GameState.is_recording and not GameState.is_processing_recording and not GameState.is_exporting:
		var lightweight: bool = GameState.performance_mode == Mode.LIGHTWEIGHT or (GameState.performance_mode == Mode.AUTO and _slow_windows >= 2)
		_set_quality(lightweight)
	var now: int = Time.get_ticks_usec()
	var frame_ms: float = float(now - _last_frame_usec) / 1000.0
	_last_frame_usec = now
	if not _focused or _sampling_paused or now < _ignore_until_usec or frame_ms > 250.0:
		_reset_window()
		return
	record_frame(frame_ms)

func record_frame(frame_ms: float) -> void:
	_frames.append(frame_ms)
	if _frames.size() > MAX_SAMPLES:
		_frames.remove_at(0)
	_elapsed += frame_ms / 1000.0
	if _elapsed < WINDOW_SECONDS:
		return
	var stats: Dictionary = summarize(_frames)
	if GameState.performance_mode == Mode.AUTO:
		# Latch until a scene change or explicit mode change to prevent flapping.
		if float(stats.p95) > SLOW_FRAME_MS:
			_slow_windows += 1
		elif not GameState.lightweight_graphics:
			_slow_windows = 0
	if diagnostics_enabled:
		var report: Dictionary = {"frame_ms": stats, "lightweight": GameState.lightweight_graphics}
		for metric: StringName in _metrics:
			report[metric] = summarize(_metrics[metric])
		var effects: int = 0
		for bus: int in range(AudioServer.bus_count):
			for effect: int in range(AudioServer.get_bus_effect_count(bus)):
				if AudioServer.is_bus_effect_enabled(bus, effect):
					effects += 1
		report["buses"] = AudioServer.bus_count
		report["enabled_effects"] = effects
		var playing_streams: int = 0
		for node: Node in get_tree().get_nodes_in_group("performance_track_streams"):
			var player: AudioStreamPlayer = node as AudioStreamPlayer
			if player.playing:
				playing_streams += 1
		report["playing_track_streams"] = playing_streams
		report["mix_rate"] = AudioServer.get_mix_rate()
		report["input_mix_rate"] = AudioServer.get_input_mix_rate()
		report["output_latency_ms"] = AudioServer.get_output_latency() * 1000.0
		report["master_peak_db"] = maxf(AudioServer.get_bus_peak_volume_left_db(0, 0), AudioServer.get_bus_peak_volume_right_db(0, 0))
		report["draw_calls"] = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		print("Performance: ", JSON.stringify(report))
	_metrics.clear()
	_frames.clear()
	_elapsed = 0.0

static func summarize(samples: PackedFloat64Array) -> Dictionary:
	var sorted: PackedFloat64Array = samples.duplicate()
	sorted.sort()
	if sorted.is_empty():
		return {"p50": 0.0, "p95": 0.0, "p99": 0.0, "max": 0.0}
	return {
		"p50": sorted[int((sorted.size() - 1) * 0.50)],
		"p95": sorted[int((sorted.size() - 1) * 0.95)],
		"p99": sorted[int((sorted.size() - 1) * 0.99)],
		"max": sorted[-1],
	}

func _on_sample(metric: StringName, value: float) -> void:
	if not diagnostics_enabled:
		return
	var samples: PackedFloat64Array = _metrics.get(metric, PackedFloat64Array())
	if samples.size() < MAX_SAMPLES:
		samples.append(value)
		_metrics[metric] = samples

func _on_mode_requested(mode: int) -> void:
	if mode < Mode.AUTO or mode > Mode.LIGHTWEIGHT:
		push_error("PerformanceManager: invalid quality mode.")
		return
	GameState.performance_mode = mode
	_slow_windows = 0
	_reset_window()
	var config := ConfigFile.new()
	config.set_value("graphics", "mode", mode)
	var error: Error = config.save(SETTINGS_PATH)
	if error != OK:
		push_error("PerformanceManager: could not save preference (%d)." % error)
		EventBus.status_message_requested.emit("De beeldinstelling kon niet worden bewaard.")

func _load_preference() -> void:
	var config := ConfigFile.new()
	var error: Error = config.load(SETTINGS_PATH)
	if error == ERR_FILE_NOT_FOUND:
		return
	if error != OK:
		push_error("PerformanceManager: could not load preference (%d)." % error)
		return
	var mode: Variant = config.get_value("graphics", "mode", Mode.AUTO)
	if not mode is int or mode < Mode.AUTO or mode > Mode.LIGHTWEIGHT:
		push_error("PerformanceManager: invalid saved quality mode.")
		return
	GameState.performance_mode = mode

func _set_quality(lightweight: bool) -> void:
	if GameState.lightweight_graphics == lightweight:
		return
	GameState.lightweight_graphics = lightweight
	EventBus.performance_quality_changed.emit(lightweight)

func _on_scene_changed() -> void:
	_slow_windows = 0
	_ignore_until_usec = Time.get_ticks_usec() + 3000000
	_reset_window()

func _on_sampling_paused(paused: bool) -> void:
	_sampling_paused = paused
	_ignore_until_usec = Time.get_ticks_usec() + 3000000
	_reset_window()

func _reset_window() -> void:
	_frames.clear()
	_metrics.clear()
	_elapsed = 0.0
