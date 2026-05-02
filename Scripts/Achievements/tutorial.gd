extends Node

@export var achievements_panel: Panel
@export var achievements_fx_sound: AudioStream
@export var clap_stomp: Node
@export var instruction_label: Label
@export var piano_area: Area2D
@export var piano_mesh: Node3D
@export var in_between_area: Area2D
@export var in_between_mesh: Node3D
@export var out_side_area: Area2D
@export var out_side_mesh: Node3D
@export var knob_area: Area2D
@export var klappy_continue_button: BaseButton
@export var instrument_clap_button: BaseButton
@export var instrument_stomp_button: BaseButton
@export var chaos_pad_knob_top_position: Node2D
@export var continue_button: BaseButton
@export var mute_speech_button: BaseButton

# Tutorial state
var tutorial_level: int = 0
var tutorial_activated: bool = false
var use_tutorial: bool = false
var _first_tts_done: bool = false

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

func _process(delta: float) -> void:
	_clapping = false
	_stomping = false

func _ready():
	EventBus.skip_tutorial_requested.connect(_on_skip_tutorial_requested)



	EventBus.clap_stomp_detected.connect(_on_has_clapped_or_stomped)

func _on_skip_tutorial_requested():
	use_tutorial = false
	achievements_panel.visible = false
	if DisplayServer.tts_is_speaking():
		DisplayServer.tts_stop()

func play_achievement_sfx() -> void:
	EventBus.play_sfx_requested.emit(achievements_fx_sound)

func _build_tutorial_steps() -> Array:
	var steps := _load_tutorial_steps_from_json()
	if steps.size() > 0:
		return steps
	else:
		#throw an error
		push_error("Failed to load tutorial steps from JSON")
		return []

func _on_has_clapped_or_stomped(interaction_type: int) -> void:
	if interaction_type == 0: # InteractionType.CLAP
		_clapping = true
		_stomping = false
	else:
		_clapping = false
		_stomping = true

# ── Condition callbacks ──────────────────────────────────────────────

func _cond_clapped() -> bool:
	return clap_stomp != null and clap_stomp.is_clapping

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
	return clap_stomp != null and clap_stomp.is_stamping and clap_stomp.stomped_on_beat_amount >= _FIXED_AMOUNT

func _cond_orange_ring_filled() -> bool:
	return _active_beats_per_ring(_INDEX_ORANGE_RING) >= _beats_active_orange_ring

func _cond_circle_removed() -> bool:
	return (_active_beats_per_ring(_INDEX_RED_RING) < _beats_active_red_ring
		or _active_beats_per_ring(_INDEX_ORANGE_RING) < _beats_active_orange_ring)

func _cond_update_orange_and_playing() -> bool:
	_beats_active_orange_ring = _active_beats_per_ring(_INDEX_ORANGE_RING)
	return GameState.playing

func _cond_clapped_enough() -> bool:
	return clap_stomp != null and clap_stomp.is_clapping and clap_stomp.clapped_on_beat_amount >= _FIXED_AMOUNT

func _cond_synth_2_select() -> bool:
	return SongState.selected_track_index == 5

func _cond_synth_2_record_or_tts() -> bool:
	if SongState.selected_track_index == 5 and GameState.is_recording:
		play_achievement_sfx()
		tutorial_level += 5
		DisplayServer.tts_stop()
		return true
	return not DisplayServer.tts_is_speaking()

func _cond_synth_2_record_pressed() -> bool:
	return SongState.selected_track_index == 5 and GameState.is_recording

func _cond_false() -> bool:
	return false

func _cond_voice_over_finished() -> bool:
	return true

func _cond_save_knob_and_tts() -> bool:
	return not DisplayServer.tts_is_speaking()


# ── Outcome callbacks ────────────────────────────────────────────────

func _outcome_noop() -> void:
	pass

func _outcome_intro() -> void:
	EventBus.ui_visibility_requested.emit(VisibilityManager.UIElement.BEAT_POINTER, false)
	EventBus.track_sprites_visibility_requested.emit(0, true)
	EventBus.ui_visibility_requested.emit(VisibilityManager.UIElement.KLAPPY_CONTINUE, true)
	play_achievement_sfx()

func _outcome_kick_place() -> void:
	EventBus.beat_set_free_requested.emit(_INDEX_RED_RING, _RING_TOP, true)
	EventBus.beat_set_free_requested.emit(_INDEX_RED_RING, _RING_RIGHT, true)
	EventBus.beat_set_free_requested.emit(_INDEX_RED_RING, _RING_BOTTOM, true)
	EventBus.ui_visibility_requested.emit(VisibilityManager.UIElement.PLAY_PAUSE_BUTTON, true)
	EventBus.ui_visibility_requested.emit(VisibilityManager.UIElement.STOMP_UI, true)

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
	_stomping = true
	play_achievement_sfx()

func _outcome_stomp_done() -> void:
	_stomping = false
	EventBus.playing_change_requested.emit(false)
	play_achievement_sfx()

func _outcome_show_orange_ring() -> void:
	EventBus.track_sprites_visibility_requested.emit(_INDEX_ORANGE_RING, true)

func _outcome_clap_ring_setup() -> void:
	EventBus.beat_set_free_requested.emit(_INDEX_ORANGE_RING, _RING_RIGHT, true)
	EventBus.beat_set_free_requested.emit(_INDEX_ORANGE_RING, _RING_LEFT, true)
	EventBus.ui_visibility_requested.emit(VisibilityManager.UIElement.CLAP_UI, true)
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
	_clapping = true

func _outcome_clap_done() -> void:
	_clapping = false
	EventBus.playing_change_requested.emit(false)
	play_achievement_sfx()

func _outcome_show_green_layer() -> void:
	EventBus.ui_visibility_requested.emit(VisibilityManager.UIElement.GREEN_LAYER, true)

func _outcome_green_bear() -> void:
	EventBus.ui_visibility_requested.emit(VisibilityManager.UIElement.MIC_RECORDER, true)
	if chaos_pad_knob_top_position:
		EventBus.chaos_pad_knob_position_set_requested.emit(chaos_pad_knob_top_position.global_position)
	_allowed = true
	play_achievement_sfx()
	EventBus.chaos_pad_button_animation_stop_requested.emit()

func _outcome_green_record_pressed() -> void:
	play_achievement_sfx()
	_increased_speed = true
	DisplayServer.tts_stop()
	EventBus.record_button_animation_stop_requested.emit()

func _outcome_voice_over_done() -> void:
	_increased_speed = false
	_timer.start(3)

func _outcome_show_triangle() -> void:
	EventBus.ui_visibility_requested.emit(VisibilityManager.UIElement.CHAOS_PAD_TRIANGLE, true)

func _outcome_show_piano_area() -> void:
	piano_area.monitoring = true
	piano_mesh.visible = true
	piano_area.emit_signal("animation_star_play")
	piano_area.area_entered.connect(_body_continue)

func _outcome_move_to_star_1() -> void:
	play_achievement_sfx()
	_skip_play()

func _outcome_listen_piano() -> void:
	_text_allowed = true
	piano_area.set_deferred("monitoring", false)
	piano_mesh.visible = false
	piano_area.emit_signal("animation_star_stop")
	play_achievement_sfx()
	_active = true

func _outcome_show_in_between() -> void:
	_active = false
	in_between_mesh.visible = true
	in_between_area.set_deferred("monitoring", true)
	in_between_area.emit_signal("animation_star_play")
	in_between_area.area_entered.connect(_body_continue)

func _outcome_move_in_between() -> void:
	_active = true
	in_between_area.set_deferred("monitoring", false)
	in_between_area.emit_signal("animation_star_stop")
	play_achievement_sfx()
	in_between_mesh.visible = false

func _outcome_show_outside() -> void:
	_active = false
	out_side_area.set_deferred("monitoring", true)
	out_side_area.emit_signal("animation_star_play")
	out_side_mesh.visible = true

func _outcome_move_outside() -> void:
	out_side_area.set_deferred("monitoring", false)
	out_side_area.emit_signal("animation_star_stop")
	out_side_mesh.visible = false
	play_achievement_sfx()
	_active = true

func _outcome_end_tutorial() -> void:
	tutorial_level = -2
	EventBus.ui_visibility_requested.emit(VisibilityManager.UIElement.ENTIRE_INTERFACE, true)
	achievements_panel.visible = false
	play_achievement_sfx()
	EventBus.continue_button_pressed.disconnect(_tutorial_continue)
	if piano_area.area_entered.is_connected(_body_continue):
		piano_area.area_entered.disconnect(_body_continue)
	if in_between_area.area_entered.is_connected(_body_continue):
		in_between_area.area_entered.disconnect(_body_continue)
	if klappy_continue_button and klappy_continue_button.pressed.is_connected(_klappy_continue):
		klappy_continue_button.pressed.disconnect(_klappy_continue)
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
	_first_tts_done = false


func check_if_tutorial_was_chosen() -> void:
	use_tutorial = _read_use_tutorial()


func try_activate_tutorial() -> void:
	if use_tutorial:
		print("tutorial activated")
		EventBus.ui_visibility_requested.emit(VisibilityManager.UIElement.BEAT_POINTER, false)
		EventBus.bpm_set_requested.emit(60)
		#TODO set entire interface invisible except for tutorial elements
		# uiManager.audio_export_ui.settings_button.visible = true
		# uiManager.achievements_panel.visible = true
		EventBus.continue_button_pressed.connect(_tutorial_continue)
		if klappy_continue_button:
			klappy_continue_button.pressed.connect(_klappy_continue)
		_top = chaos_pad_knob_top_position
		_clap_button = instrument_clap_button
		_stomp_button = instrument_stomp_button
		if _clap_button:
			_clap_button.pressed.connect(func(): EventBus.clap_stomp_detected.emit(0))
		if _stomp_button:
			_stomp_button.pressed.connect(func(): EventBus.clap_stomp_detected.emit(1))


func setup_tutorial() -> void:
	_timer_setup()
	tutorial_steps = _build_tutorial_steps()


func update_tutorial() -> void:
	_button_state()

	if not _first_tts_done and use_tutorial:
		_speak_tutorial_instruction(tutorial_level)
		_first_tts_done = true

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
		achievements_panel.add_child(_timer)


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
	for beat in range(SongState.total_beats):
		if SongState.current_section.get_beat(index_ring, beat):
			amount += 1
	return amount


func _klappy_continue() -> void:
	# manager.klappy.call("on_clap")
	_next_line()


func _button_state() -> void:
	if continue_button:
		continue_button.visible = _active


func _tutorial_continue() -> void:
	if not _active:
		return
	_next_line()


func _body_continue(body: Area2D) -> void:
	print("body continue " + str(body))
	if body == knob_area:
		_next_line()


func _next_line() -> void:
	print(SongState.bpm)
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
	if _stomping and clap_stomp != null:
		if clap_stomp.stomped_on_beat_amount > _previous_stomp:
			play_achievement_sfx()
			_previous_stomp = clap_stomp.stomped_on_beat_amount


func _correct_clap_play_sfx() -> void:
	if _clapping and clap_stomp != null:
		if clap_stomp.clapped_on_beat_amount > _previous_clap:
			play_achievement_sfx()
			_previous_clap = clap_stomp.clapped_on_beat_amount


func _speak_tutorial_instruction(instruction_index: int) -> void:
	if not _text_allowed:
		return
	if mute_speech_button and mute_speech_button.button_pressed:
		return
	if instruction_index < 0 or instruction_index >= tutorial_steps.size():
		return

	var text: String = tutorial_steps[instruction_index]["instruction"]
	var clean_text: String = TTSHelper.Text_without_emoticons(text)

	if _increased_speed:
		print("Increase the speed")
		TTSHelper.speak(clean_text, 2.5)
	else:
		TTSHelper.speak(clean_text)


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
		if instruction_label:
			instruction_label.text = _instruction

func _load_tutorial_steps_from_json() -> Array:
	var file := FileAccess.open(TUTORIAL_STEPS_PATH, FileAccess.READ)
	if file == null:
		push_warning("Could not open tutorial steps JSON at %s" % TUTORIAL_STEPS_PATH)
		return []
	var raw: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(raw)
	if parsed == null or typeof(parsed) != TYPE_ARRAY:
		push_warning("Tutorial steps JSON is invalid or not an array")
		return []
	var steps: Array = []
	for entry in parsed:
		if entry is Dictionary:
			steps.append({
				"instruction": entry.get("instruction", ""),
				"condition": _resolve_step_callable(entry.get("condition"), "_cond_false"),
				"outcome": _resolve_step_callable(entry.get("outcome"), "_outcome_noop"),
			})
	return steps

func _resolve_step_callable(step_name: Variant, fallback: String) -> Callable:
	var method_name: String = "" if step_name == null else str(step_name).strip_edges()
	if method_name == "":
		method_name = fallback
	if has_method(method_name):
		return Callable(self, method_name)
	if method_name != fallback and has_method(fallback):
		return Callable(self, fallback)
	return Callable()
