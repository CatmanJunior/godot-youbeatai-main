extends Node

# Private state
var _slow_beat_timer: float = 0.0

# Called by ui_manager._ready()
func initialize(ui: Node) -> void:
	ui.play_pause_button.button_up.connect(_on_play_pause)
	ui.bpm_up_button.pressed.connect(_on_bpm_up)
	ui.bpm_down_button.pressed.connect(_on_bpm_down)

func update(delta: float) -> void:
	var ui = get_parent()
	_update_play_pause_button(ui)
	_update_pointer(ui)
	_update_metronome(delta, ui)
	_update_labels(ui)
	_update_mic_meter(ui)

func _update_play_pause_button(ui: Node) -> void:
	ui.play_pause_button.text = "⏸️" if GameState.playing else "▶️"

func _update_pointer(ui: Node) -> void:
	if GameState.playing:
		var progression = float(GameState.current_beat + (GameState.beat_timer / GameState.time_per_beat)) / float(GameState.beats_amount)
		ui.pointer.rotation_degrees = progression * 360.0 - 7.0

func _update_metronome(delta: float, ui: Node) -> void:
	if GameState.playing:
		_slow_beat_timer += delta / 4.0
		if _slow_beat_timer > GameState.time_per_beat:
			_slow_beat_timer -= GameState.time_per_beat
		var beat_progress = _slow_beat_timer / GameState.time_per_beat
		ui.metronome.position.y = lerp(-0.4, 0.4, beat_progress)

func _update_labels(ui: Node) -> void:
	ui.bpm_label.text = str(GameState.current_bpm)
	ui.recording_delay_label.text = "%.2fs" % ui.recording_delay_slider.value
	GameState.swing = ui.swing_slider.value
	if ui.section_loop_toggle:
		ui.real_time_audio_recording_progress_bar.visible = ui.section_loop_toggle.button_pressed

func _update_mic_meter(ui: Node) -> void:
	ui.mic_meter.value = EventBus.microphone_volume * 100.0

func _on_play_pause() -> void:
	var ui = get_parent()
	if not ui.play_pause_button.disabled:
		EventBus.play_pause_toggled.emit()

func _on_bpm_up() -> void:
	EventBus.bpm_up_requested.emit(5)

func _on_bpm_down() -> void:
	EventBus.bpm_down_requested.emit(5)
