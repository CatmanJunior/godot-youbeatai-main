class_name Tutorial
extends Node

@export var tutorial_steps_resource: TutorialStepsCollection
@export var achievements_panel: Panel
@export var achievements_fx_sound: AudioStream
@export var clap_stomp: ClapStompDetector
@export var chaos_pad_ui: ChaosPadUI
@export var chaos_pad_knob_top_position: Node2D

# ── Constants ─────────────────────────────────────────────

## Track indices for the two main beat rings.
const INDEX_KICK_TRACK: int = 0
const INDEX_CLAP_TRACK: int = 1

## Beat indices at compass positions on a 16-beat ring.
## Used to pre-place beats at the top, right, and bottom of the kick ring.
const KICK_PRESET_BEAT_INDICES: Array[int] = [0, 4, 8]   # top, right, bottom
## Used to pre-place beats at the right and left of the clap ring.
const CLAP_PRESET_BEAT_INDICES: Array[int] = [4, 12]     # right, left

## Number of on-beat claps/stomps required to complete the interaction phase.
const CLAP_REQUIRED_ON_BEAT_COUNT: int = 5

# ── Tutorial state ────────────────────────────────────────────

var tutorial_level: int = 0
var tutorial_activated: bool = false
var _first_tts_done: bool = false

var _beats_active_kick_track: int = 5
var _beats_active_clap_track: int = 4
var _instruction: String = ""
var _condition: Callable = Callable()
var _outcome: Callable = Callable()
var _active: bool = false
var _previous_clap: int = -1
var _previous_stomp: int = -1
var stomping: bool = false
var clapping: bool = false
var clapped_on_beat: int = 0
var stomped_on_beat: int = 0

var _in_stomp_phase: bool = false
var _in_clap_phase: bool = false
var _timer: Timer = null
var _text_allowed: bool = true
var _increased_speed: bool = false

var tutorial_steps: Array[TutorialStepData] = []
var _condition_map: Dictionary = {}
var _outcome_map: Dictionary = {}

var _last_knob_pos: Vector2 = Vector2.ZERO

var _conditions: TutorialConditions
var _outcomes: TutorialOutcomes

# ── Godot lifecycle ───────────────────────────────────────────

# Resets per-frame clap/stomp flags each tick so they are only true during the frame the interaction was detected.
func _process(_delta: float) -> void:
	update_tutorial()
	clapping = false
	stomping = false

# Creates sub-nodes, builds the condition/outcome dispatch maps, and subscribes to EventBus signals.
func _ready() -> void:

	_conditions = TutorialConditions.new()
	_conditions.tutorial = self
	add_child(_conditions)

	_outcomes = TutorialOutcomes.new()
	_outcomes.tutorial = self
	add_child(_outcomes)

	_build_maps()
	EventBus.chaos_pad_dragging.connect(_on_chaos_pad_knob_dragged)
	EventBus.skip_tutorial_requested.connect(_on_skip_tutorial_requested)
	EventBus.clap_stomp_detected.connect(_on_has_clapped_or_stomped)
	EventBus.clap_on_beat_detected.connect(_on_has_clapped_on_beat)
	EventBus.stomp_on_beat_detected.connect(_on_has_stomped_on_beat)
	try_activate_tutorial()



func _turn_off_stars():
	EventBus.ui_visibility_requested.emit(UIVisibilityListener.UIElement.STAR1, false)
	EventBus.ui_visibility_requested.emit(UIVisibilityListener.UIElement.STAR2, false)
	EventBus.ui_visibility_requested.emit(UIVisibilityListener.UIElement.STAR3, false)

func _on_has_clapped_on_beat() -> void:
	clapped_on_beat += 1
	print("clapped on beat: %d" % clapped_on_beat)

func _on_has_stomped_on_beat() -> void:
	stomped_on_beat += 1
	print("stomped on beat: %d" % stomped_on_beat)
	

# ── EventBus handlers ───────────────────────────────────────────────────────────────────────────────────────────────────────

# Disables the tutorial immediately, hides the achievements panel, and stops any active TTS speech.
func _on_skip_tutorial_requested() -> void:
	GameState.use_tutorial = false
	achievements_panel.visible = false
	if DisplayServer.tts_is_speaking():
		DisplayServer.tts_stop()

# Updates the per-frame clapping/stomping state flags when ClapStompDetector emits an interaction.
func _on_has_clapped_or_stomped(interaction_type: int) -> void:
	if interaction_type == 0: #stomp
		clapping = false
		stomping = true
	else:
		clapping = true
		stomping = false
	print("clapping: %s, stomping: %s" % [clapping, stomping])

# ── Public API ────────────────────────────────────────────────────────────────────────────────────────────

# Requests playback of the achievement sound effect through the EventBus.
func play_achievement_sfx() -> void:
	EventBus.play_sfx_requested.emit(achievements_fx_sound)

# Resets all tutorial state variables to their initial values.
# Call this before re-running the tutorial from the beginning.
func reset() -> void:
	tutorial_level = 0
	tutorial_activated = false
	if _timer:
		_timer.queue_free()
		_timer = null
	_beats_active_kick_track = 5
	_beats_active_clap_track = 4
	_instruction = ""
	_condition = Callable()
	_outcome = Callable()
	_active = false
	_previous_clap = -1
	_previous_stomp = -1
	stomping = false
	clapping = false
	_in_stomp_phase = false
	_in_clap_phase = false
	_text_allowed = true
	_increased_speed = false
	_first_tts_done = false
	_last_knob_pos = Vector2.ZERO

#when . is pressed goto next tutorial step
func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var i_event : InputEventKey = event
		if i_event.keycode == Key.KEY_0 and i_event.pressed:
			if _outcome.is_valid():
				_outcome.call()
			if tutorial_level >= tutorial_steps.size():
				return
			tutorial_level += 1
			_speak_tutorial_instruction(tutorial_level)
			_update_lists()

# Activates the tutorial if GameState.use_tutorial is set.
# Sets the BPM to 60, hides the beat pointer, wires up continue and instrument buttons.
func try_activate_tutorial() -> void:
	if GameState.use_tutorial:
		GameState.tutorial_activated = true

		EventBus.bpm_set_requested.emit(60)
		EventBus.continue_button_pressed.connect(_tutorial_continue)
		setup_tutorial()
		_set_interface_invisible_initial.call_deferred()
	else:
		_turn_off_stars.call_deferred()

func _set_interface_invisible_initial() -> void:
	EventBus.ui_visibility_requested.emit(UIVisibilityListener.UIElement.ENTIRE_INTERFACE, false)
	for i in range(SectionData.SAMPLE_TRACKS_PER_SECTION):
		EventBus.track_sprites_visibility_requested.emit(i, false)
	EventBus.track_sprites_visibility_requested.emit(INDEX_KICK_TRACK, false)
	EventBus.ui_visibility_requested.emit(UIVisibilityListener.UIElement.ACHIEVEMENTS_PANEL, true)
	EventBus.ui_visibility_requested.emit(UIVisibilityListener.UIElement.BEAT_RING, true)
	EventBus.track_select_button_visibility_requested.emit(0, true)
	EventBus.track_select_button_visibility_requested.emit(1, true)
	EventBus.synth_progress_bar_visible_requested.emit(0, false)
	EventBus.synth_progress_bar_visible_requested.emit(1, false)

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
	# _continue_button_visible(_active)

	if not _first_tts_done and GameState.use_tutorial:
		_speak_tutorial_instruction(tutorial_level)
		_first_tts_done = true

	_update_interaction_sfx()

	if tutorial_level != -1 and GameState.use_tutorial and tutorial_level < tutorial_steps.size():
		_update_lists()
		if _condition.is_valid() and _condition.call():
			_next_line()

# ── Private helpers ─────────────────────────────────────────────────────────────────────────────────────────────────────

# Creates a one-shot Timer (3 s default) and adds it as a child of the achievements panel.
func _timer_setup() -> void:
	if _timer == null:
		_timer = Timer.new()
		_timer.wait_time = 3
		_timer.one_shot = true
		achievements_panel.add_child(_timer)

# Returns the number of active (filled) beats in the given ring of the current section.
func _active_beats_per_ring(index_ring: int) -> int:
	if SongState.current_section == null:
		return 0
	var amount: int = 0
	for beat: int in range(SongState.total_beats):
		if SongState.current_section.get_beat(index_ring, beat):
			amount += 1
	return amount

# Shows or hides the main continue button depending on whether the current step allows it.
func _continue_button_visible(vis : bool) -> void:
	EventBus.ui_visibility_requested.emit(UIVisibilityListener.UIElement.KLAPPY_CONTINUE, vis)

# Advances the tutorial when the main continue button is pressed,
# but only if the current step has set _active = true.
func _tutorial_continue() -> void:
	if not _active:
		return
	_next_line()

# Advances the tutorial when the Klappy robot's continue button is pressed.
func _klappy_continue() -> void:
	_next_line()

func _on_chaos_pad_knob_dragged(pos: Vector2) -> void:
	_last_knob_pos = pos

# Fires the current outcome callable, increments the step index, speaks the next instruction,
# and refreshes the active condition and outcome callables for the new step.
func _next_line() -> void:
	if _outcome.is_valid():
		_outcome.call()
	if tutorial_level >= tutorial_steps.size():
		return
	tutorial_level += 1
	_speak_tutorial_instruction(tutorial_level)
	_update_lists()

# Plays achievement sfx once each time a new on-beat stomp or clap is registered during its phase.
func _update_interaction_sfx() -> void:
	if _in_stomp_phase and stomping and clap_stomp.stomped_on_beat_amount > _previous_stomp:
		play_achievement_sfx()
		_previous_stomp = clap_stomp.stomped_on_beat_amount
	if _in_clap_phase and clapping and clap_stomp.clapped_on_beat_amount > _previous_clap:
		play_achievement_sfx()
		_previous_clap = clap_stomp.clapped_on_beat_amount

# Speaks the instruction text for the given step index via TTS.
# Strips emoticons from the text and uses a faster rate if _increased_speed is set.
# Does nothing if TTS text is suppressed, speech is muted, or the index is out of bounds.
func _speak_tutorial_instruction(instruction_index: int) -> void:
	if not _text_allowed:
		return
	if GameState.mute_speech:
		return
	if instruction_index < 0 or instruction_index >= tutorial_steps.size():
		return
	var text: String = tutorial_steps[instruction_index].instruction
	var clean_text: String = TTSHelper.text_without_emoticons(text)
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
	return false

# Reads the current step data and refreshes the instruction text label,
# condition callable, and outcome callable from the step's enum values.
func _update_lists() -> void:
	if tutorial_level >= 0 and tutorial_level < tutorial_steps.size():
		var current_step: TutorialStepData = tutorial_steps[tutorial_level]
		_instruction = current_step.instruction
		_condition = _get_condition_callable(current_step.condition)
		_outcome = _get_outcome_callable(current_step.outcome)

		EventBus.tutorial_instruction_text_requested.emit(_instruction)

# ── Enum dispatch ──────────────────────────────────────────────────────────────────────────────────────────────────

# Populates the condition and outcome dispatch dictionaries from the sub-node maps.
func _build_maps() -> void:
	_condition_map = _conditions.get_map()
	_outcome_map = _outcomes.get_map()

# Returns the condition callable mapped to the given enum value.
# Falls back to an invalid Callable(); callers guard with is_valid() before calling.
func _get_condition_callable(c: TutorialStepData.TutorialCondition) -> Callable:
	return _condition_map.get(c, Callable())

# Returns the outcome callable mapped to the given enum value, falling back to an empty Callable.
func _get_outcome_callable(o: TutorialStepData.TutorialOutcome) -> Callable:
	return _outcome_map.get(o, Callable())
