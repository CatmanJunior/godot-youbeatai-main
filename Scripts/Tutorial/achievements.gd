extends Node
class_name AchievementManager
## Manages achievements that lock/unlock UI buttons.
##
## Locking a button: disables it and adds a small lock icon child.
## Unlocking a button: re-enables it and hides the lock icon.
## Energy is earned by clapping/stomping on beat; energy-gated achievements
## unlock automatically once enough energy is accumulated.
## All achievement definitions live in [AchievementList].


#---Static ----
static var energy_points: float = 0.0


# -- Constants --
const START_ENERGY_POINTS: float = 25.0

const ENERGY_REWARD_PER_CLAP_STOMP_ON_BEAT: float = 3.0
const ENERGY_REWARD_PER_BEAT_REMOVED: float = 1.0
const ENERGY_REWARD_FULL_SECTION_PLAYED: float = 2.0

const ENERGY_COST_PER_BEAT_ADDED: float = 1.0
const ENERGY_COST_TEMPLATE_SET: float = 50.0
const ENERGY_THRESHOLD_LIGHT_PAD: float = 100.0


const LOCK_ICON_NODE_NAME: StringName = &"__lock_icon"

const TIMEOUT_AFTER_TOOLTIP_OPEN: float = 2.0


#---- EXPORTS ----
@export var energy_progress_bar: ProgressBar

@export var achievement_sfx: AudioStream
## Icon shown on a locked button. Assign a small padlock texture in the editor.
@export var lock_icon_texture: Texture2D
## Reference to SectionUI — used to retrieve the newly created section button after unlock.
@export var section_ui: SectionUI

## One export per AchievementNode — assign the button to lock in the inspector.
## Leave a slot empty (null) if that achievement has no button to lock.
@export_group("Locked Buttons", "btn_")
@export var btn_first_sample: BaseButton
@export var btn_second_sample: BaseButton
@export var btn_template_tip: BaseButton
@export var btn_track_2: BaseButton
@export var btn_track_3: BaseButton
@export var btn_synth_track_2: BaseButton
@export_group("")

var btn_section_2: BaseButton

## Built from the named exports above — do not edit directly.
var locked_buttons: Dictionary[int, BaseButton] = {}

## Public so AchievementList closures can read them.
var samples_recorded: int = 0
var sections_added: int = 0

var _achievements: Array[AchievementDef] = []
var _gui_input_callables: Dictionary[int, Callable] = {}
## Ensures one-time setup (tooltip wiring, default UI) runs after the first frame.
var _late_ready_done: bool = false


# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:	
	EventBus.on_tutorial_done.connect(_on_tutorial_done)

	await get_tree().create_timer(0.2).timeout
	if GameState.achievements_active:
		activate_achievements()
	elif not GameState.use_tutorial:
		change_energy_points(100)
		EventBus.set_klappy_speech_bubble.emit("", "", false)

func _input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event is InputEventKey:
		var i_event: InputEventKey = event
		if i_event.keycode == Key.KEY_9 and i_event.pressed:
			change_energy_points(10.0)
		if i_event.keycode == Key.KEY_8 and i_event.pressed:
			change_energy_points(-10.0)
		if i_event.keycode == Key.KEY_7 and i_event.pressed:
			unlock_all_achievements()

func _on_beat_triggered(_beat_index: int) -> void:
	# Reward energy for playing a full section, to encourage using the new sections.
	if _beat_index == SongState.beats_per_section - 1:
		change_energy_points(ENERGY_REWARD_FULL_SECTION_PLAYED)

# ── Energy ────────────────────────────────────────────────────────────────────
func _on_not_enough_energy() -> void:
	show_and_speak_tooltip("Je hebt niet genoeg energie om meer beats toe te voegen!")
	change_energy_points(-1.0) # Small penalty to prevent spamming

func change_energy_points(delta: float) -> void:
	energy_points = clampf(energy_points + delta, 0.0, 100.0)

	if energy_progress_bar:
		energy_progress_bar.value = energy_points
	EventBus.energy_points_changed.emit(energy_points)


static func has_energy_for_beat_addition() -> bool:
	if GameState.use_tutorial:
		return true
	return energy_points >= ENERGY_COST_PER_BEAT_ADDED

static func has_energy_for_light_pad() -> bool:
	return energy_points >= ENERGY_THRESHOLD_LIGHT_PAD

# ── Event handlers ────────────────────────────────────────────────────────────

func _on_clap_stomp_on_beat() -> void:
	change_energy_points(ENERGY_REWARD_PER_CLAP_STOMP_ON_BEAT)

func _on_beat_state_change(_track_id: int, _beat_index: int, active: bool) -> void:
	if active:
		change_energy_points(-ENERGY_COST_PER_BEAT_ADDED)
	else:
		change_energy_points(ENERGY_REWARD_PER_BEAT_REMOVED)

func _on_add_section_requested(_tex: Texture2D) -> void:
	sections_added += 1

func _on_recording_stopped(rec: RecordingData) -> void:
	if rec != null and rec.track_type == TrackData.TrackType.SAMPLE:
		samples_recorded += 1

func _on_tutorial_done() -> void:
	activate_achievements()

func activate_achievements() -> void:
	if _late_ready_done:
		return
	_late_ready_done = true
	_setup_default_ui_state()
	change_energy_points(START_ENERGY_POINTS)
		
	var list := AchievementList.new()
	list.tracker = self
	_achievements = list.build()


	EventBus.add_section_requested.emit(null)
	EventBus.section_switch_requested.emit(0) # Switch to the first section, so the new section button appears in the UI and can be locked.
	# Add the initial second section upfront and lock its button as the ADD_SECTION unlock target.
	btn_section_2 = section_ui.section_buttons[1]
	_build_locked_buttons_map()

	_init_tooltip_actions()
	_setup_locks()

	EventBus.clap_on_beat_detected.connect(_on_clap_stomp_on_beat)
	EventBus.stomp_on_beat_detected.connect(_on_clap_stomp_on_beat)
	EventBus.beat_state_changed.connect(_on_beat_state_change)
	EventBus.recording_stopped.connect(_on_recording_stopped)
	EventBus.add_section_requested.connect(_on_add_section_requested)
	EventBus.beat_triggered.connect(_on_beat_triggered)
	EventBus.not_enough_energy.connect(_on_not_enough_energy)
	print("Achievements activated")
	GameState.achievements_active = true

	

# ── Achievement update loop ───────────────────────────────────────────────────

func _setup_locks() -> void:
	for button: BaseButton in locked_buttons.values():
		_lock_button(button)


func _try_unlock(ach: AchievementDef, button: BaseButton) -> void:
	if not ach.condition.call():
		return
	if ach.worth > 0.0 and energy_points < ach.worth:
		return
	_do_unlock(ach, button)


func _do_unlock(ach: AchievementDef, button: BaseButton) -> void:
	_unlock_button(button)
	if ach.worth > 0.0:
		change_energy_points(-ach.worth)
	if ach.result.is_valid():
		ach.result.call()
	_play_achievement_sfx()
	EventBus.achievement_done.emit(ach.node_id)
	var callable: Callable = _gui_input_callables.get(ach.node_id, Callable())
	if callable.is_valid() and button.gui_input.is_connected(callable):
		button.gui_input.disconnect(callable)
	_gui_input_callables.erase(ach.node_id)


# ── Tooltip ───────────────────────────────────────────────────────────────────

func _init_tooltip_actions() -> void:
	for ach: AchievementDef in _achievements:
		var button := _get_locked_button(ach)
		if button == null:
			continue
		var callable := func(event: InputEvent) -> void:
			if not button.disabled:
				return
			if not (event is InputEventMouseButton):
				return
			var mb := event as InputEventMouseButton
			if not (mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT):
				return
			close_tooltip()
			# Attempt unlock on click; only show tooltip if still locked.
			_try_unlock(ach, button)
			if button.disabled:
				show_and_speak_tooltip(ach.tooltip, ach.worth)
		_gui_input_callables[ach.node_id] = callable
		button.gui_input.connect(callable)


func show_and_speak_tooltip(text: String, cost: float = 0) -> void:
	var cost_text : String = ""
	if cost > 0:
		cost_text = "Dit kost " + str(int(cost)) + " energie"
	
	text = text + "\n" + cost_text if cost_text != "" else text
	EventBus.set_klappy_speech_bubble.emit(text, "", false)
	
	if not (GameState.mute_speech or text == ""):
		TTSHelper.speak(TTSHelper.text_without_emoticons(text))
		_start_tooltip_close_timer()


func close_tooltip() -> void:
	EventBus.set_klappy_speech_bubble.emit("", "", false)
	if DisplayServer.tts_is_speaking():
		DisplayServer.tts_stop()


func _start_tooltip_close_timer() -> void:
	get_tree().create_timer(TIMEOUT_AFTER_TOOLTIP_OPEN).timeout.connect(func() -> void:
		if DisplayServer.tts_is_speaking():
			_start_tooltip_close_timer()
		else:
			close_tooltip()
	)


# ── Unlock all ────────────────────────────────────────────────────────────────

func unlock_all_achievements() -> void:
	for button: BaseButton in locked_buttons.values():
		_unlock_button(button)
	EventBus.all_achievements_unlocked.emit()


# ── Default UI state ──────────────────────────────────────────────────────────

func _setup_default_ui_state() -> void:
	EventBus.track_sprites_visibility_requested.emit(2, false)
	EventBus.track_sprites_visibility_requested.emit(3, false)
	EventBus.synth_progress_bar_visible_requested.emit(1, false)
	section_ui.hide_all_context_buttons()
	if not GameState.use_tutorial:
		EventBus.ui_visibility_requested.emit(UIVisibilityListener.UIElement.ACHIEVEMENTS_PANEL, false)
	

# ── Lock / unlock helpers ─────────────────────────────────────────────────────

func _lock_button(button: BaseButton) -> void:
	button.disabled = true
	if lock_icon_texture == null:
		return
	var icon := TextureRect.new()
	icon.name = LOCK_ICON_NODE_NAME
	icon.texture = lock_icon_texture
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# Anchor to the center of the button, then size it to 60% of the button.
	icon.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	icon.position = icon.size /2.5
	icon.scale = Vector2.ONE * 0.6
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(icon)


func _unlock_button(button: BaseButton) -> void:
	button.disabled = false
	var icon := button.find_child(LOCK_ICON_NODE_NAME, false, false) as TextureRect
	if icon:
		icon.visible = false


func _get_locked_button(ach: AchievementDef) -> BaseButton:
	return locked_buttons.get(ach.node_id, null) as BaseButton


func _build_locked_buttons_map() -> void:
	var N := AchievementDef.AchievementNode
	var pairs: Array = [
		[N.TRACK_2, btn_track_2],
		[N.SYNTH_2, btn_synth_track_2],
		[N.TEMPLATE_TIP, btn_template_tip],
		[N.FIRST_SAMPLE, btn_first_sample],
		[N.SECOND_SAMPLE, btn_second_sample],
		[N.TRACK_3, btn_track_3],
	]
	if btn_section_2:
		pairs.append([N.ADD_SECTION, btn_section_2])
	# Build the locked_buttons map from the exported button variables. 
	for pair: Array in pairs:
		# Only register non-null buttons, so we can have achievements without locked buttons.
		if pair[1] != null:
			locked_buttons[pair[0]] = pair[1]


func _play_achievement_sfx() -> void:
	EventBus.play_sfx_requested.emit(achievement_sfx)


# ── Reset ─────────────────────────────────────────────────────────────────────

func reset() -> void:
	GameState.achievements_active = false
	_late_ready_done = false
	energy_points = 0.0
