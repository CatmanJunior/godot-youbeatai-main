extends Node
class_name EnergyManager
## Manages the player's energy points independently of the achievement system.
##
## Energy is earned by clapping/stomping on beat, completing a full section,
## and removing beats. Placing a beat costs energy. At 100 energy the light pad
## is activated. This manager runs in all game modes except tutorial.


# ── Constants ─────────────────────────────────────────────────────────────────

const START_ENERGY_POINTS: float = 25.0

const ENERGY_REWARD_PER_CLAP_STOMP_ON_BEAT: float = 3.0
const ENERGY_REWARD_PER_BEAT_REMOVED: float = 1.0
const ENERGY_REWARD_FULL_SECTION_PLAYED: float = 2.0

const ENERGY_COST_PER_BEAT_ADDED: float = 1.0
const ENERGY_THRESHOLD_LIGHT_PAD: float = 100.0


# ── Private state ─────────────────────────────────────────────────────────────────────

@export var not_enough_energy_message: String = "Je hebt niet genoeg energie om meer beats toe te voegen!"

var _signals_connected: bool = false


# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	EventBus.on_tutorial_done.connect(_on_tutorial_done)
	if not GameState.use_tutorial:
		activate()


func _input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event is InputEventKey:
		var i_event := event as InputEventKey
		if i_event.keycode == Key.KEY_9 and i_event.pressed:
			change_energy_points(10.0)
		if i_event.keycode == Key.KEY_8 and i_event.pressed:
			change_energy_points(-10.0)


# ── Activation ────────────────────────────────────────────────────────────────

func activate() -> void:
	if _signals_connected:
		return
	_signals_connected = true

	GameState.energy_points = 0.0
	change_energy_points(START_ENERGY_POINTS)

	EventBus.clap_on_beat_detected.connect(_on_clap_stomp_on_beat)
	EventBus.stomp_on_beat_detected.connect(_on_clap_stomp_on_beat)
	EventBus.beat_triggered.connect(_on_beat_triggered)
	EventBus.beat_state_changed.connect(_on_beat_state_change)
	EventBus.not_enough_energy.connect(_on_not_enough_energy)
	EventBus.energy_change_requested.connect(change_energy_points)


# ── Energy ────────────────────────────────────────────────────────────────────

func change_energy_points(delta: float) -> void:
	GameState.energy_points = clampf(GameState.energy_points + delta, 0.0, 100.0)
	EventBus.energy_points_changed.emit(GameState.energy_points)


# ── Event handlers ────────────────────────────────────────────────────────────

func _on_tutorial_done() -> void:
	activate()


func _on_clap_stomp_on_beat() -> void:
	change_energy_points(ENERGY_REWARD_PER_CLAP_STOMP_ON_BEAT)


func _on_beat_triggered(beat_index: int) -> void:
	if beat_index == SongState.beats_per_section - 1:
		change_energy_points(ENERGY_REWARD_FULL_SECTION_PLAYED)


func _on_beat_state_change(_track_id: int, _beat_index: int, active: bool) -> void:
	if active:
		change_energy_points(-ENERGY_COST_PER_BEAT_ADDED)
	else:
		change_energy_points(ENERGY_REWARD_PER_BEAT_REMOVED)


func _on_not_enough_energy() -> void:
	EventBus.set_klappy_speech_bubble.emit(
		not_enough_energy_message, "", false
	)
	change_energy_points(-1.0) # Small penalty to prevent spamming
