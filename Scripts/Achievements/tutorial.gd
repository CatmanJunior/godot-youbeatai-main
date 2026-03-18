extends Node

# Tutorial state
var tutorial_level: int = 0
var tutorial_activated: bool = false
var use_tutorial: bool = false

var _beats_active_red_ring: int = 5
var _beats_active_orange_ring: int = 4
const _INDEX_RED_RING: int = 0
const _INDEX_ORANGE_RING: int = 1
const _RING_TOP: int = 0
const _RING_BOTTOM: int = 8
const _RING_RIGHT: int = 4
const _RING_LEFT: int = 12
const _GREEN_LAYER_MIC_INDEX: int = 0
var _knob_pos: Vector2
var _instruction: String = ""
var _condition: Callable = Callable()
var _outcome: Callable = Callable()
var _active: bool = false
var _top: Node2D = null
const _FIXED_AMOUNT: int = 5
var _previous_clap: int = -1
var _previous_stomp: int = -1
var _stomping: bool = false
var _clapping: bool = false
var _timer: Timer = null
var _allowed: bool = false
var _text_allowed: bool = true
var _clap_button = null
var _stomp_button = null
var _increased_speed: bool = false

# Tutorial steps: array of dictionaries with keys: instruction, condition, outcome
var tutorial_steps: Array = []
const TUTORIAL_STEPS_PATH: String = "res://Data/tutorial_steps.json"

var beatManager: Node
var audioPlayerManager: Node
var uiManager: Node
var visabilityManager: Node
var mixingManager: Node
var gameManager: Node

func _ready():
	EventBus.skip_tutorial_requested.connect(_on_skip_tutorial_requested)
	mixingManager = %MixingManager
	beatManager = %BeatManager
	audioPlayerManager = %AudioPlayerManager
	uiManager = %UiManager
	visabilityManager = %VisabilityManager
	gameManager = %GameManager


func _on_skip_tutorial_requested():
	GameState.use_tutorial = false
	uiManager.set_entire_interface_visibility(true)
	uiManager.achievements_panel.visible = false
	if DisplayServer.tts_is_speaking():
		DisplayServer.tts_stop()

func play_achievement_sfx() -> void:
	audioPlayerManager.play_extra_sfx(audioPlayerManager.achievement_sfx)

func _build_tutorial_steps() -> Array:
	var steps := _load_tutorial_steps_from_json()
	if steps.size() > 0:
		return steps
	else:
		#throw an error
		push_error("Failed to load tutorial steps from JSON")
		return []

# ── Condition callbacks ──────────────────────────────────────────────

func _cond_clapped() -> bool:
	return beatManager.clapped

func _cond_tts_done() -> bool:
	return not DisplayServer.tts_is_speaking()

func _cond_playing() -> bool:
	return GameState.playing

func _cond_not_playing() -> bool:
	return not GameState.playing

func _cond_timer_done() -> bool:
	return _timer.time_left == 0

func _cond_timer_stopped() -> bool:
	return _timer.is_stopped()

func _cond_red_ring_filled() -> bool:
	return _active_beats_per_ring(_INDEX_RED_RING) >= _beats_active_red_ring

func _cond_update_red_and_playing() -> bool:
	_beats_active_red_ring = _active_beats_per_ring(_INDEX_RED_RING)
	return GameState.playing

func _cond_stomped_enough() -> bool:
	return beatManager.stomped_on_beat_amount >= _FIXED_AMOUNT

func _cond_orange_ring_filled() -> bool:
	return _active_beats_per_ring(_INDEX_ORANGE_RING) >= _beats_active_orange_ring

func _cond_circle_removed() -> bool:
	return (_active_beats_per_ring(_INDEX_RED_RING) < _beats_active_red_ring
		or _active_beats_per_ring(_INDEX_ORANGE_RING) < _beats_active_orange_ring)

func _cond_update_orange_and_playing() -> bool:
	_beats_active_orange_ring = _active_beats_per_ring(_INDEX_ORANGE_RING)
	return GameState.playing

func _cond_clapped_enough() -> bool:
	return beatManager.clapped_on_beat_amount >= _FIXED_AMOUNT

func _cond_green_bear() -> bool:
	_return_player(uiManager.chaos_pad_ui.activate_green_chaos_button).play("Bear_pulse")
	return mixingManager.chaos_pad_mode == mixingManager.ChaosPadMode.SYNTH_MIXING

func _cond_green_record_or_tts() -> bool:
	_return_player(uiManager.green_layer_record_button.get_parent()).play("record_pulse")
	if uiManager.green_layer_record_button.button_pressed:
		play_achievement_sfx()
		tutorial_level += 5
		DisplayServer.tts_stop()
		_return_player(uiManager.green_layer_record_button.get_parent()).stop()
		return true
	return not DisplayServer.tts_is_speaking()

func _cond_green_record_pressed() -> bool:
	return uiManager.green_layer_record_button.button_pressed

func _cond_false() -> bool:
	return false

func _cond_voice_over_finished() -> bool:
	return uiManager.layer_voice_over_0.finished

func _cond_save_knob_and_tts() -> bool:
	_knob_pos = uiManager.chaos_pad_ui.knob.global_position
	return not DisplayServer.tts_is_speaking()


# ── Outcome callbacks ────────────────────────────────────────────────

func _outcome_noop() -> void:
	pass

func _outcome_intro() -> void:
	uiManager.transport_ui.pointer.visible = true
	visabilityManager.set_ring_visibility(_INDEX_RED_RING, true)
	uiManager.cross.visible = true
	uiManager.klappy_continue.visible = false
	uiManager.audio_export_ui.settings_button.visible = true
	uiManager.continue_button.emit_signal("animation_play")
	play_achievement_sfx()

func _outcome_kick_place() -> void:
	beatManager.set_beat_free(_INDEX_RED_RING, _RING_TOP, true)
	beatManager.set_beat_free(_INDEX_RED_RING, _RING_RIGHT, true)
	beatManager.set_beat_free(_INDEX_RED_RING, _RING_BOTTOM, true)
	uiManager.transport_ui.play_pause_button.visible = true
	#TODO: HUH WHAT
	# uiManager.set_stomp_visibility(true)

func _outcome_start_timer_allowed() -> void:
	_timer.start(_timer.wait_time)
	_allowed = true

func _outcome_pause_beat() -> void:
	play_achievement_sfx()
	_skip_play()

func _outcome_red_ring_filled() -> void:
	_text_allowed = true
	_allowed = true
	play_achievement_sfx()

func _outcome_timer_2() -> void:
	_timer.start(2)

func _outcome_stomp_setup() -> void:
	uiManager.amount_left.text = "Goed gestamped %d / 5" % uiManager.stomped_on_beat_amount
	_stomping = true
	play_achievement_sfx()

func _outcome_stomp_done() -> void:
	_stomping = false
	uiManager.amount_left.visible = false
	uiManager.amount_left.text = ""
	EventBus.playing_change_requested.emit(false)
	play_achievement_sfx()

func _outcome_show_orange_ring() -> void:
	visabilityManager.set_ring_visibility(_INDEX_ORANGE_RING, true)

func _outcome_clap_ring_setup() -> void:
	beatManager.set_beat_free(_INDEX_ORANGE_RING, _RING_RIGHT, true)
	beatManager.set_beat_free(_INDEX_ORANGE_RING, _RING_LEFT, true)
	uiManager.set_clap_visibility(true)
	_skip_play()

func _outcome_clap_listen() -> void:
	_text_allowed = true
	_timer.start(_timer.wait_time)
	play_achievement_sfx()

func _outcome_stop_playing() -> void:
	EventBus.playing_change_requested.emit(false)

func _outcome_orange_ring_filled() -> void:
	_beats_active_orange_ring = _active_beats_per_ring(_INDEX_ORANGE_RING)
	_beats_active_red_ring = _active_beats_per_ring(_INDEX_RED_RING)
	play_achievement_sfx()

func _outcome_circle_removed() -> void:
	play_achievement_sfx()
	_skip_play()

func _outcome_listen_again() -> void:
	_text_allowed = true
	play_achievement_sfx()
	_timer.start(2)

func _outcome_clap_count_setup() -> void:
	uiManager.amount_left.visible = true
	uiManager.amount_left.text = "Goed geklapped %d / 5" % uiManager.clapped_on_beat_amount
	_clapping = true

func _outcome_clap_done() -> void:
	_clapping = false
	uiManager.amount_left.visible = false
	EventBus.playing_change_requested.emit(false)
	play_achievement_sfx()

func _outcome_show_green_layer() -> void:
	visabilityManager.set_green_layer_visibility(true)

func _outcome_green_bear() -> void:
	visabilityManager.set_mic_recorder_visibility(true)
	uiManager.chaos_pad_ui.knob.global_position = _top.global_position
	_allowed = true
	play_achievement_sfx()
	_return_player(uiManager.chaos_pad_ui.activate_green_chaos_button).stop()

func _outcome_green_record_pressed() -> void:
	play_achievement_sfx()
	_increased_speed = true
	DisplayServer.tts_stop()
	_return_player(uiManager.green_layer_record_button.get_parent()).stop()

func _outcome_voice_over_done() -> void:
	_increased_speed = false
	_timer.start(3)

func _outcome_show_triangle() -> void:
	uiManager.chaos_pad_ui.chaos_pad_triangle_sprite.visible = true

func _outcome_show_piano_area() -> void:
	uiManager.piano_area.monitoring = true
	uiManager.piano_mesh.visible = true
	uiManager.piano_area.emit_signal("animation_star_play")

func _outcome_move_to_star_1() -> void:
	play_achievement_sfx()
	_skip_play()

func _outcome_listen_piano() -> void:
	_text_allowed = true
	uiManager.piano_area.set_deferred("monitoring", false)
	uiManager.piano_mesh.visible = false
	uiManager.piano_area.emit_signal("animation_star_stop")
	play_achievement_sfx()
	_active = true

func _outcome_show_in_between() -> void:
	_active = false
	uiManager.in_between_mesh.visible = true
	uiManager.in_between_area.set_deferred("monitoring", true)
	uiManager.in_between_area.emit_signal("animation_star_play")

func _outcome_move_in_between() -> void:
	_active = true
	uiManager.in_between_area.set_deferred("monitoring", false)
	uiManager.in_between_area.emit_signal("animation_star_stop")
	play_achievement_sfx()
	uiManager.in_between_mesh.visible = false

func _outcome_show_outside() -> void:
	_active = false
	uiManager.out_side_area.set_deferred("monitoring", true)
	uiManager.out_side_area.emit_signal("animation_star_play")
	uiManager.out_side_mesh.visible = true

func _outcome_move_outside() -> void:
	uiManager.out_side_area.set_deferred("monitoring", false)
	uiManager.out_side_area.emit_signal("animation_star_stop")
	uiManager.out_side_mesh.visible = false
	play_achievement_sfx()
	_active = true

func _outcome_end_tutorial() -> void:
	tutorial_level = -2
	visabilityManager.set_entire_interface_visibility(true)
	uiManager.achievements_panel.visible = false
	play_achievement_sfx()
	uiManager.continue_button.pressed.disconnect(_tutorial_continue)
	uiManager.piano_area.area_entered.disconnect(_body_continue)
	uiManager.in_between_area.area_entered.disconnect(_body_continue)
	uiManager.klappy_continue.pressed.disconnect(_klappy_continue)
	DisplayServer.tts_stop()


# ── Public ───────────────────────────────────────────────────────

func reset() -> void:
	tutorial_level = 0
	tutorial_activated = false
	use_tutorial = _read_use_tutorial()
	if _timer:
		_timer.queue_free()
		_timer = null
	_beats_active_red_ring = 5
	_beats_active_orange_ring = 4
	_instruction = ""
	_condition = Callable()
	_outcome = Callable()
	_active = false
	_top = null
	_previous_clap = -1
	_previous_stomp = -1
	_stomping = false
	_clapping = false
	_text_allowed = true
	_clap_button = null
	_stomp_button = null
	_increased_speed = false


func check_if_tutorial_was_chosen() -> void:
	use_tutorial = _read_use_tutorial()


func try_activate_tutorial() -> void:
	if use_tutorial:
		print("tutorial activated")
		uiManager.transport_ui.pointer.visible = false
		EventBus.bpm_set_requested.emit(60)
		visabilityManager.set_entire_interface_visibility(false)
		uiManager.audio_export_ui.settings_button.visible = true
		uiManager.achievements_panel.visible = true
		uiManager.continue_button.pressed.connect(_tutorial_continue)
		uiManager.piano_area.area_entered.connect(_body_continue)
		uiManager.in_between_area.area_entered.connect(_body_continue)
		uiManager.klappy_continue.pressed.connect(_klappy_continue)
		uiManager.out_side_area.area_entered.connect(_body_continue)
		uiManager.add_beats.set_pressed(true)
		_top = uiManager.corners[1]
		_clap_button = uiManager.instrument_button_1
		_stomp_button = uiManager.instrument_button_0
		_clap_button.on_pressed.connect(uiManager.on_clap)
		_stomp_button.on_pressed.connect(uiManager.on_stomp)


func setup_tutorial() -> void:
	_timer_setup()
	tutorial_steps = _build_tutorial_steps()


func update_tutorial() -> void:
	_button_state()

	if not gameManager.first_tts_done and use_tutorial:
		_speak_tutorial_instruction(tutorial_level)
		gameManager.first_tts_done = true

	_correct_clap_play_sfx()
	_correct_stomp_play_sfx()

	if tutorial_level != -1 and use_tutorial and tutorial_level < tutorial_steps.size():
		_update_lists()
		if _condition.is_valid() and _condition.call():
			_next_line()


# ── Private helpers ──────────────────────────────────────────────────

func _timer_setup() -> void:
	if _timer == null:
		_timer = Timer.new()
		_timer.wait_time = 3
		_timer.one_shot = true
		uiManager.achievements_panel.add_child(_timer)


func _read_use_tutorial() -> bool:
	var use: bool = true
	var path: String = OS.get_user_data_dir() + "/use_tutorial.txt"
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if file:
			var content: String = file.get_as_text().strip_edges()
			use = content.to_lower() == "true"
			file.close()
		DirAccess.remove_absolute(path)
	print("use tutorial: " + str(use))
	return use


func _active_beats_per_ring(index_ring: int) -> int:
	var amount: int = 0
	for beat in range(GameState.total_beats):
		if beatManager.current_section.get_beat(index_ring, beat):
			amount += 1
	return amount


func _klappy_continue() -> void:
	# manager.klappy.call("on_clap")
	_next_line()


func _button_state() -> void:
	uiManager.continue_button.visible = _active


func _tutorial_continue() -> void:
	if not _active:
		return
	_next_line()


func _body_continue(body: Area2D) -> void:
	print("body continue " + str(body))
	if body == uiManager.knob_area:
		_next_line()


func _next_line() -> void:
	print(GameState.bpm)
	if _outcome.is_valid():
		_outcome.call()
	if tutorial_level >= tutorial_steps.size():
		return
	tutorial_level += 1
	_speak_tutorial_instruction(tutorial_level)
	_update_lists()


func _return_player(parent: Node) -> AnimationPlayer:
	for child in parent.get_children():
		if child is AnimationPlayer:
			return child
	return null


func _correct_stomp_play_sfx() -> void:
	if _stomping:
		if beatManager.stomped_on_beat_amount > _previous_stomp:
			play_achievement_sfx()
			_previous_stomp = beatManager.stomped_on_beat_amount
			uiManager.amount_left.text = "Goed gestamped %d / 5" % beatManager.stomped_on_beat_amount


func _correct_clap_play_sfx() -> void:
	if _clapping:
		if beatManager.clapped_on_beat_amount > _previous_clap:
			play_achievement_sfx()
			_previous_clap = beatManager.clapped_on_beat_amount
			uiManager.amount_left.text = "Goed geklapped %d / 5" % beatManager.clapped_on_beat_amount


func _speak_tutorial_instruction(instruction_index: int) -> void:
	if not _text_allowed:
		return
	if uiManager.audio_export_ui.mute_speach.button_pressed:
		return
	if instruction_index < 0 or instruction_index >= tutorial_steps.size():
		return

	var text: String = tutorial_steps[instruction_index]["instruction"]
	var clean_text: String = gameManager.text_without_emoticons(text)

	var voices: PackedStringArray = DisplayServer.tts_get_voices_for_language("nl")
	if voices.size() == 0:
		voices = DisplayServer.tts_get_voices_for_language("en")
	if DisplayServer.tts_is_speaking():
		DisplayServer.tts_stop()
	if _increased_speed:
		print("Increase the speed")
		DisplayServer.tts_speak(clean_text, voices[0], 100, 1.0, 2.5)
	else:
		DisplayServer.tts_speak(clean_text, voices[0], 100)


func _skip_play() -> bool:
	if GameState.playing:
		_text_allowed = false
		return true
	else:
		return false


func _update_lists() -> void:
	if tutorial_level >= 0 and tutorial_level < tutorial_steps.size():
		var current_step: Dictionary = tutorial_steps[tutorial_level]
		_instruction = current_step["instruction"]
		_condition = current_step["condition"]
		_outcome = current_step["outcome"]
		uiManager.instruction_label.text = _instruction

func _load_tutorial_steps_from_json() -> Array:
	var file := FileAccess.open(TUTORIAL_STEPS_PATH, FileAccess.READ)
	if file == null:
		push_warning("Could not open tutorial steps JSON at %s" % TUTORIAL_STEPS_PATH)
		return []
	var raw: String = file.get_as_text()
	file.close()
	var parse_result: Variant = JSON.parse_string(raw)
	if parse_result.error != OK or typeof(parse_result.result) != TYPE_ARRAY:
		push_warning("Tutorial steps JSON is invalid: %s" % str(parse_result.error))
		return []
	var steps: Array = []
	for entry in parse_result.result:
		if entry is Dictionary:
			steps.append({
				"instruction": entry.get("instruction", ""),
				"condition": _resolve_step_callable(entry.get("condition", ""), "_cond_false"),
				"outcome": _resolve_step_callable(entry.get("outcome", ""), "_outcome_noop"),
			})
	return steps

func _resolve_step_callable(stepName: String, fallback: String) -> Callable:
	var method_name: String = stepName.strip_edges()
	if method_name == "":
		method_name = fallback
	if has_method(method_name):
		return Callable(self , method_name)
	if method_name != fallback and has_method(fallback):
		return Callable(self , fallback)
	return Callable()
