extends Node

@export var tutorial_steps_resource: TutorialStepsCollection
@export var achievements_panel: Panel
@export var achievements_fx_sound: AudioStream
@export var clap_stomp: ClapStompDetector
@export var instruction_label: Label
@export var chaospad: ChaosPadUI
@export var chaospad_triangle_sprite: TextureRect
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
var _first_tts_done: bool = false

var _beats_active_red_ring: int = 5
var _beats_active_orange_ring: int = 4
const _INDEX_RED_RING: int = 0
const _INDEX_ORANGE_RING: int = 1
const _RING_TOP: int = 0
const _RING_BOTTOM: int = 8
const _RING_RIGHT: int = 4
const _RING_LEFT: int = 12
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
var _in_stomp_phase: bool = false
var _in_clap_phase: bool = false
var _timer: Timer = null
var _allowed: bool = false
var _text_allowed: bool = true
var _clap_button = null
var _stomp_button = null
var _increased_speed: bool = false

var tutorial_steps: Array[TutorialStepData] = []
var _condition_map: Dictionary = {}
var _outcome_map: Dictionary = {}

# Resets per-frame clap/stomp flags each tick so they are only true during the frame the interaction was detected.
func _process(delta: float) -> void:
	_clapping = false
	_stomping = false

# Builds the condition/outcome dispatch maps and subscribes to EventBus signals.
func _ready() -> void:
	_build_maps()
	EventBus.skip_tutorial_requested.connect(_on_skip_tutorial_requested)
	EventBus.clap_stomp_detected.connect(_on_has_clapped_or_stomped)

# Disables the tutorial immediately, hides the achievements panel, and stops any active TTS speech.
func _on_skip_tutorial_requested() -> void:
	GameState.use_tutorial = false
	achievements_panel.visible = false
	if DisplayServer.tts_is_speaking():
		DisplayServer.tts_stop()

# Requests playback of the achievement sound effect through the EventBus.
func play_achievement_sfx() -> void:
	EventBus.play_sfx_requested.emit(achievements_fx_sound)

# Updates the per-frame clapping/stomping state flags when ClapStompDetector emits an interaction.
func _on_has_clapped_or_stomped(interaction_type: int) -> void:
	if interaction_type == 0: # InteractionType.CLAP
		_clapping = true
		_stomping = false
	else:
		_clapping = false
		_stomping = true

# ── Condition callbacks ──────────────────────────────────────────────

# Condition: the clap detector is currently registering a clap.
func _cond_clapped() -> bool:
	return clap_stomp.is_clapping

# Condition: the text-to-speech engine has finished speaking.
func _cond_tts_done() -> bool:
	return not DisplayServer.tts_is_speaking()

# Condition: the song is currently playing.
func _cond_playing() -> bool:
	return GameState.playing

# Condition: the song is paused or stopped.
func _cond_not_playing() -> bool:
	return not GameState.playing

# Condition: the tutorial timer has counted down to zero.
func _cond_timer_done() -> bool:
	return _timer.time_left == 0

# Condition: the tutorial timer is fully stopped (was never started or has completed).
func _cond_timer_stopped() -> bool:
	return _timer.is_stopped()

# Condition: the kick (red) ring has at least the required number of active beats.
func _cond_red_ring_filled() -> bool:
	return _active_beats_per_ring(_INDEX_RED_RING) >= _beats_active_red_ring

# Condition: snapshots the current kick ring beat count, then returns true if the song is playing.
# Used to detect when the player confirms their kick pattern while playing.
func _cond_update_red_and_playing() -> bool:
	_beats_active_red_ring = _active_beats_per_ring(_INDEX_RED_RING)
	return GameState.playing

# Condition: the player is currently stamping and has stomped on beat the required number of times.
func _cond_stomped_enough() -> bool:
	return clap_stomp.is_stamping and clap_stomp.stomped_on_beat_amount >= _FIXED_AMOUNT

# Condition: the clap (orange) ring has at least the required number of active beats.
func _cond_orange_ring_filled() -> bool:
	return _active_beats_per_ring(_INDEX_ORANGE_RING) >= _beats_active_orange_ring

# Condition: the player has removed a beat from either ring since the last snapshot.
func _cond_circle_removed() -> bool:
	return (_active_beats_per_ring(_INDEX_RED_RING) < _beats_active_red_ring
		or _active_beats_per_ring(_INDEX_ORANGE_RING) < _beats_active_orange_ring)

# Condition: snapshots the current clap ring beat count, then returns true if the song is playing.
# Used to detect when the player confirms their clap pattern while playing.
func _cond_update_orange_and_playing() -> bool:
	_beats_active_orange_ring = _active_beats_per_ring(_INDEX_ORANGE_RING)
	return GameState.playing

# Condition: the player is clapping and has clapped on beat the required number of times.
func _cond_clapped_enough() -> bool:
	return clap_stomp.is_clapping and clap_stomp.clapped_on_beat_amount >= _FIXED_AMOUNT

# Condition: the synth 2 track (index 5) is currently selected.
func _cond_synth_2_select() -> bool:
	# _return_player(uiManager.chaos_pad_ui.activate_synth2_chaos_button).play("Bear_pulse")
	return SongState.selected_track_index == 5

# Condition: returns true when TTS is done. If the user already started recording on synth 2,
# awards achievement sfx and skips ahead 5 steps (fast-track through the recording instructions).
func _cond_synth_2_record_or_tts() -> bool:
	# _return_player(uiManager.synth2_layer_record_button.get_parent()).play("record_pulse")
	if SongState.selected_track_index == 5 and GameState.is_recording:
		play_achievement_sfx()
		tutorial_level += 4  # skip 4 steps here; _next_line adds 1 more = 5 total
		DisplayServer.tts_stop()
		return true
	return not DisplayServer.tts_is_speaking()

# Condition: the synth 2 track is selected and recording is actively in progress.
func _cond_synth_2_record_pressed() -> bool:
	return SongState.selected_track_index == 5 and GameState.is_recording

# Condition: always returns false — used as a sentinel "never advance" condition.
func _cond_false() -> bool:
	return false

# Condition: always returns true — used for steps that advance unconditionally (e.g. after voice-over plays).
func _cond_voice_over_finished() -> bool:
	return true

# Condition: returns true when TTS has finished speaking after the chaos pad knob interaction.
func _cond_save_knob_and_tts() -> bool:
	return not DisplayServer.tts_is_speaking()


# ── Outcome callbacks ────────────────────────────────────────────────

# Outcome: placeholder that does nothing — used when a step has no side-effect on advance.
func _outcome_noop() -> void:
	pass

# Outcome: hides the beat pointer, reveals the first track ring sprites and Klappy's continue button,
# and plays the achievement sound to signal the start of the tutorial.
func _outcome_intro() -> void:
	EventBus.ui_visibility_requested.emit(VisibilityManager.UIElement.BEAT_POINTER, false)
	EventBus.track_sprites_visibility_requested.emit(0, true)
	EventBus.ui_visibility_requested.emit(VisibilityManager.UIElement.KLAPPY_CONTINUE, true)
	play_achievement_sfx()

# Outcome: unlocks beats at the top, right, and bottom positions of the kick ring,
# and shows the play/pause button and the stomp UI.
func _outcome_kick_place() -> void:
	EventBus.beat_set_free_requested.emit(_INDEX_RED_RING, _RING_TOP, true)
	EventBus.beat_set_free_requested.emit(_INDEX_RED_RING, _RING_RIGHT, true)
	EventBus.beat_set_free_requested.emit(_INDEX_RED_RING, _RING_BOTTOM, true)
	EventBus.ui_visibility_requested.emit(VisibilityManager.UIElement.PLAY_PAUSE_BUTTON, true)
	EventBus.ui_visibility_requested.emit(VisibilityManager.UIElement.STOMP_UI, true)

# Outcome: starts the tutorial timer and marks this step as allowed to advance (shows continue button).
func _outcome_start_timer_allowed() -> void:
	_timer.start(_timer.wait_time)
	_allowed = true

# Outcome: plays achievement sfx and pauses playback if the song is currently running.
func _outcome_pause_beat() -> void:
	play_achievement_sfx()
	_skip_play()

# Outcome: re-enables TTS text output, marks the step as allowed to advance,
# and plays achievement sfx when the kick ring is fully filled.
func _outcome_red_ring_filled() -> void:
	_text_allowed = true
	_allowed = true
	play_achievement_sfx()

# Outcome: starts a short 2-second timer to give the player a brief pause.
func _outcome_timer_2() -> void:
	_timer.start(2)

# Outcome: begins the stomp interaction phase and plays achievement sfx.
func _outcome_stomp_setup() -> void:
	_in_stomp_phase = true
	play_achievement_sfx()

# Outcome: ends the stomp phase, stops playback, and plays achievement sfx.
func _outcome_stomp_done() -> void:
	_in_stomp_phase = false
	EventBus.playing_change_requested.emit(false)
	play_achievement_sfx()

# Outcome: makes the clap (orange) ring sprites visible.
func _outcome_show_orange_ring() -> void:
	EventBus.track_sprites_visibility_requested.emit(_INDEX_ORANGE_RING, true)

# Outcome: unlocks beats on the right and left of the clap ring, shows the clap UI,
# and pauses playback if running.
func _outcome_clap_ring_setup() -> void:
	EventBus.beat_set_free_requested.emit(_INDEX_ORANGE_RING, _RING_RIGHT, true)
	EventBus.beat_set_free_requested.emit(_INDEX_ORANGE_RING, _RING_LEFT, true)
	EventBus.ui_visibility_requested.emit(VisibilityManager.UIElement.CLAP_UI, true)
	_skip_play()

# Outcome: re-enables TTS text, starts the listen timer, and plays achievement sfx.
func _outcome_clap_listen() -> void:
	_text_allowed = true
	_timer.start(_timer.wait_time)
	play_achievement_sfx()

# Outcome: stops playback.
func _outcome_stop_playing() -> void:
	EventBus.playing_change_requested.emit(false)

# Outcome: snapshots the active beat counts on both rings and plays achievement sfx
# when the clap ring is confirmed as filled.
func _outcome_orange_ring_filled() -> void:
	_beats_active_orange_ring = _active_beats_per_ring(_INDEX_ORANGE_RING)
	_beats_active_red_ring = _active_beats_per_ring(_INDEX_RED_RING)
	play_achievement_sfx()

# Outcome: plays achievement sfx and pauses playback when the player removes a beat from a ring.
func _outcome_circle_removed() -> void:
	play_achievement_sfx()
	_skip_play()

# Outcome: re-enables TTS text, plays achievement sfx, and starts a 2-second listen-again timer.
func _outcome_listen_again() -> void:
	_text_allowed = true
	play_achievement_sfx()
	_timer.start(2)

# Outcome: begins the clap counting interaction phase.
func _outcome_clap_count_setup() -> void:
	_in_clap_phase = true

# Outcome: ends the clap counting phase, stops playback, and plays achievement sfx.
func _outcome_clap_done() -> void:
	_in_clap_phase = false
	EventBus.playing_change_requested.emit(false)
	play_achievement_sfx()

# Outcome: makes the synth 2 layer visible via the VisibilityManager.
func _outcome_show_synth2_layer() -> void:
	EventBus.ui_visibility_requested.emit(VisibilityManager.UIElement.SYNTH2_LAYER, true)

# Outcome: shows the mic recorder, moves the chaos pad knob to the top position,
# stops the chaos pad button animation, marks the step as allowed, and plays achievement sfx.
func _outcome_synth2_bear() -> void:
	EventBus.ui_visibility_requested.emit(VisibilityManager.UIElement.MIC_RECORDER, true)
	if chaos_pad_knob_top_position:
		EventBus.chaos_pad_knob_position_set_requested.emit(chaos_pad_knob_top_position.global_position)
	_allowed = true
	play_achievement_sfx()
	EventBus.chaos_pad_button_animation_stop_requested.emit()

# Outcome: plays achievement sfx, switches to fast TTS speed, stops current speech,
# and stops the record button animation when the user starts recording on synth 2.
func _outcome_synth2_record_pressed() -> void:
	play_achievement_sfx()
	_increased_speed = true
	DisplayServer.tts_stop()
	EventBus.record_button_animation_stop_requested.emit()

# Outcome: reverts TTS to normal speed and starts a 3-second pause after the voice-over finishes.
func _outcome_voice_over_done() -> void:
	_increased_speed = false
	_timer.start(3)

# Outcome: reveals the chaos pad triangle UI element.
func _outcome_show_triangle() -> void:
	EventBus.ui_visibility_requested.emit(VisibilityManager.UIElement.CHAOS_PAD_TRIANGLE, true)

# Outcome: makes the chaos pad triangle sprite visible to indicate the interactive star target.
func _outcome_show_chaospad_area() -> void:
	chaospad_triangle_sprite.visible = true

# Outcome: plays achievement sfx and pauses playback when the chaos pad star is reached.
func _outcome_move_to_star_1() -> void:
	play_achievement_sfx()
	_skip_play()

# Outcome: hides the chaos pad triangle sprite, re-enables TTS text, plays achievement sfx,
# and activates the continue button so the player can proceed.
func _outcome_listen_chaospad() -> void:
	_text_allowed = true
	chaospad_triangle_sprite.visible = false
	play_achievement_sfx()
	_active = true

# Outcome: hides the continue button, shows and activates the in-between area star,
# and waits for the player to move into it.
func _outcome_show_in_between() -> void:
	_active = false
	in_between_mesh.visible = true
	in_between_area.set_deferred("monitoring", true)
	in_between_area.emit_signal("animation_star_play")
	in_between_area.area_entered.connect(_body_continue)

# Outcome: deactivates the in-between area star, plays achievement sfx, hides its mesh,
# and shows the continue button.
func _outcome_move_in_between() -> void:
	_active = true
	in_between_area.set_deferred("monitoring", false)
	in_between_area.emit_signal("animation_star_stop")
	play_achievement_sfx()
	in_between_mesh.visible = false

# Outcome: hides the continue button, shows and activates the outside area star,
# and waits for the player to move into it.
func _outcome_show_outside() -> void:
	_active = false
	out_side_area.set_deferred("monitoring", true)
	out_side_area.emit_signal("animation_star_play")
	out_side_mesh.visible = true
	out_side_area.area_entered.connect(_body_continue)

# Outcome: deactivates the outside area star, plays achievement sfx, hides its mesh,
# and shows the continue button.
func _outcome_move_outside() -> void:
	out_side_area.set_deferred("monitoring", false)
	out_side_area.emit_signal("animation_star_stop")
	out_side_mesh.visible = false
	play_achievement_sfx()
	_active = true

# Outcome: completes the tutorial — disables it in GameState, reveals the full UI, hides the panel,
# plays achievement sfx, disconnects all tutorial signal handlers, and stops TTS.
func _outcome_end_tutorial() -> void:
	tutorial_level = -1
	GameState.use_tutorial = false
	EventBus.ui_visibility_requested.emit(VisibilityManager.UIElement.ENTIRE_INTERFACE, true)
	achievements_panel.visible = false
	play_achievement_sfx()
	EventBus.continue_button_pressed.disconnect(_tutorial_continue)
	if in_between_area.area_entered.is_connected(_body_continue):
		in_between_area.area_entered.disconnect(_body_continue)
	if out_side_area.area_entered.is_connected(_body_continue):
		out_side_area.area_entered.disconnect(_body_continue)
	if klappy_continue_button and klappy_continue_button.pressed.is_connected(_klappy_continue):
		klappy_continue_button.pressed.disconnect(_klappy_continue)
	DisplayServer.tts_stop()


# ── Public ───────────────────────────────────────────────────────

# Resets all tutorial state variables to their initial values.
# Call this before re-running the tutorial from the beginning.
func reset() -> void:
	tutorial_level = 0
	tutorial_activated = false
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
	_in_stomp_phase = false
	_in_clap_phase = false
	_text_allowed = true
	_clap_button = null
	_stomp_button = null
	_increased_speed = false
	_first_tts_done = false


# Activates the tutorial if GameState.use_tutorial is set.
# Sets the BPM to 60, hides the beat pointer, wires up continue and instrument buttons,
# and stores references needed during the tutorial flow.
func try_activate_tutorial() -> void:
	if GameState.use_tutorial:
		print("tutorial activated")
		GameState.tutorialActivated = true
		EventBus.ui_visibility_requested.emit(VisibilityManager.UIElement.BEAT_POINTER, false)
		EventBus.bpm_set_requested.emit(60)
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


# Creates the tutorial timer and loads the ordered list of steps from the assigned resource.
# Must be called before update_tutorial() is first ticked.
func setup_tutorial() -> void:
	_timer_setup()
	if tutorial_steps_resource:
		tutorial_steps = tutorial_steps_resource.steps
	else:
		push_error("tutorial_steps_resource is not assigned on Tutorial node")


# Per-frame update: triggers the first TTS on the initial frame, fires per-beat sfx feedback
# for stomp/clap phases, and checks the current condition callable to advance the tutorial.
func update_tutorial() -> void:
	_button_state()

	if not _first_tts_done and GameState.use_tutorial:
		_speak_tutorial_instruction(tutorial_level)
		_first_tts_done = true

	_correct_clap_play_sfx()
	_correct_stomp_play_sfx()

	if tutorial_level != -1 and GameState.use_tutorial and tutorial_level < tutorial_steps.size():
		_update_lists()
		if _condition.is_valid() and _condition.call():
			_next_line()


# ── Private helpers ──────────────────────────────────────────────────

# Creates a one-shot Timer (3 s default) and adds it as a child of the achievements panel.
func _timer_setup() -> void:
	if _timer == null:
		_timer = Timer.new()
		_timer.wait_time = 3
		_timer.one_shot = true
		achievements_panel.add_child(_timer)


# Returns the number of active (filled) beats in the given ring of the current section.
func _active_beats_per_ring(index_ring: int) -> int:
	var amount: int = 0
	for beat in range(SongState.total_beats):
		if SongState.current_section.get_beat(index_ring, beat):
			amount += 1
	return amount


# Advances the tutorial when the Klappy robot's continue button is pressed.
func _klappy_continue() -> void:
	_next_line()


# Shows or hides the main continue button depending on whether the current step allows it.
func _button_state() -> void:
	if continue_button:
		continue_button.visible = _active


# Advances the tutorial when the main continue button is pressed,
# but only if the current step has set _active = true.
func _tutorial_continue() -> void:
	if not _active:
		return
	_next_line()


# Advances the tutorial when the knob Area2D is entered by another Area2D body.
func _body_continue(body: Area2D) -> void:
	print("body continue " + str(body))
	if body == knob_area:
		_next_line()


# Fires the current outcome callable, increments the step index, speaks the next instruction,
# and refreshes the active condition and outcome callables for the new step.
func _next_line() -> void:
	print(SongState.bpm)
	if _outcome.is_valid():
		_outcome.call()
	if tutorial_level >= tutorial_steps.size():
		return
	tutorial_level += 1
	_speak_tutorial_instruction(tutorial_level)
	_update_lists()


# Searches a node's children for the first AnimationPlayer and returns it, or null if not found.
func _return_player(parent: Node) -> AnimationPlayer:
	for child in parent.get_children():
		if child is AnimationPlayer:
			return child
	return null


# Plays achievement sfx once each time the player stomps a new on-beat stomp during the stomp phase.
func _correct_stomp_play_sfx() -> void:
	if _in_stomp_phase and _stomping:
		if clap_stomp.stomped_on_beat_amount > _previous_stomp:
			play_achievement_sfx()
			_previous_stomp = clap_stomp.stomped_on_beat_amount


# Plays achievement sfx once each time the player claps a new on-beat clap during the clap phase.
func _correct_clap_play_sfx() -> void:
	if _in_clap_phase and _clapping:
		if clap_stomp.clapped_on_beat_amount > _previous_clap:
			play_achievement_sfx()
			_previous_clap = clap_stomp.clapped_on_beat_amount


# Speaks the instruction text for the given step index via TTS.
# Strips emoticons from the text and uses a faster rate if _increased_speed is set.
# Does nothing if TTS text is suppressed, speech is muted, or the index is out of bounds.
func _speak_tutorial_instruction(instruction_index: int) -> void:
	if not _text_allowed:
		return
	if mute_speech_button and mute_speech_button.button_pressed:
		return
	if instruction_index < 0 or instruction_index >= tutorial_steps.size():
		return

	var text: String = tutorial_steps[instruction_index].instruction
	var clean_text: String = TTSHelper.Text_without_emoticons(text)

	if _increased_speed:
		TTSHelper.speak(clean_text, 2.5)
	else:
		TTSHelper.speak(clean_text)


# Suppresses TTS text output if the song is currently playing, so instructions don't
# overlap with music. Returns true if playback is active, false otherwise.
func _skip_play() -> bool:
	if GameState.playing:
		_text_allowed = false
		return true
	else:
		return false


# Reads the current step data and refreshes the instruction text label,
# condition callable, and outcome callable from the step's enum values.
func _update_lists() -> void:
	if tutorial_level >= 0 and tutorial_level < tutorial_steps.size():
		var current_step: TutorialStepData = tutorial_steps[tutorial_level]
		_instruction = current_step.instruction
		_condition = _get_condition_callable(current_step.condition)
		_outcome = _get_outcome_callable(current_step.outcome)
		if instruction_label:
			instruction_label.text = _instruction


# ── Enum dispatch ────────────────────────────────────────────────────

# Populates the condition and outcome dispatch dictionaries,
# mapping TutorialCondition/TutorialOutcome enum values to their corresponding callables.
func _build_maps() -> void:
	var C := TutorialStepData.TutorialCondition
	_condition_map = {
		C.IS_CLAPPING: _cond_clapped,
		C.TTS_FINISHED: _cond_tts_done,
		C.IS_PLAYING: _cond_playing,
		C.IS_PAUSED: _cond_not_playing,
		C.TIMER_AT_ZERO: _cond_timer_done,
		C.TIMER_IDLE: _cond_timer_stopped,
		C.KICK_RING_FULL: _cond_red_ring_filled,
		C.KICK_COUNT_SNAPPED_AND_PLAYING: _cond_update_red_and_playing,
		C.STOMPED_ENOUGH: _cond_stomped_enough,
		C.CLAP_RING_FULL: _cond_orange_ring_filled,
		C.BEAT_REMOVED: _cond_circle_removed,
		C.CLAP_COUNT_SNAPPED_AND_PLAYING: _cond_update_orange_and_playing,
		C.CLAPPED_ENOUGH: _cond_clapped_enough,
		C.BASS_TRACK_SELECTED: _cond_synth_2_select,
		C.BASS_RECORDING_OR_TTS_DONE: _cond_synth_2_record_or_tts,
		C.BASS_RECORDING_ACTIVE: _cond_synth_2_record_pressed,
		C.ALWAYS: _cond_voice_over_finished,
		C.TTS_DONE_AFTER_KNOB: _cond_save_knob_and_tts,
		C.NEVER: _cond_false,
	}
	var O := TutorialStepData.TutorialOutcome
	_outcome_map = {
		O.NOOP: _outcome_noop,
		O.SHOW_INTRO: _outcome_intro,
		O.PLACE_KICK_BEATS: _outcome_kick_place,
		O.START_TIMER_AND_UNLOCK: _outcome_start_timer_allowed,
		O.ON_PAUSED: _outcome_pause_beat,
		O.ON_KICK_RING_FILLED: _outcome_red_ring_filled,
		O.START_SHORT_TIMER: _outcome_timer_2,
		O.BEGIN_STOMP_PHASE: _outcome_stomp_setup,
		O.END_STOMP_PHASE: _outcome_stomp_done,
		O.SHOW_CLAP_RING: _outcome_show_orange_ring,
		O.PLACE_CLAP_BEATS: _outcome_clap_ring_setup,
		O.START_CLAP_LISTEN_TIMER: _outcome_clap_listen,
		O.STOP_PLAYBACK: _outcome_stop_playing,
		O.ON_CLAP_RING_FILLED: _outcome_orange_ring_filled,
		O.ON_BEAT_REMOVED: _outcome_circle_removed,
		O.START_LISTEN_AGAIN_TIMER: _outcome_listen_again,
		O.BEGIN_CLAP_COUNT: _outcome_clap_count_setup,
		O.END_CLAP_PHASE: _outcome_clap_done,
		O.SHOW_BASS_LAYER: _outcome_show_synth2_layer,
		O.SETUP_BASS_RECORDER: _outcome_synth2_bear,
		O.ON_BASS_RECORDING_STARTED: _outcome_synth2_record_pressed,
		O.END_FAST_TTS_AND_WAIT: _outcome_voice_over_done,
		O.SHOW_CHAOS_TRIANGLE: _outcome_show_triangle,
		O.SHOW_CHAOSPAD_STAR: _outcome_show_chaospad_area,
		O.ON_CHAOSPAD_STAR_REACHED: _outcome_move_to_star_1,
		O.ON_CHAOSPAD_LISTENED: _outcome_listen_chaospad,
		O.SHOW_MIX_STAR: _outcome_show_in_between,
		O.ON_MIX_STAR_REACHED: _outcome_move_in_between,
		O.SHOW_OUTSIDE_STAR: _outcome_show_outside,
		O.ON_OUTSIDE_STAR_REACHED: _outcome_move_outside,
		O.FINISH_TUTORIAL: _outcome_end_tutorial,
	}


# Returns the condition callable mapped to the given enum value, falling back to _cond_false.
func _get_condition_callable(c: TutorialStepData.TutorialCondition) -> Callable:
	return _condition_map.get(c, _cond_false)


# Returns the outcome callable mapped to the given enum value, falling back to an empty Callable.
func _get_outcome_callable(o: TutorialStepData.TutorialOutcome) -> Callable:
	return _outcome_map.get(o, Callable())
