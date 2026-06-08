extends Control

enum PadEffect {
	PHASER = 0,
	DISTORTION = 1,
	HIGHPASS = 2,
	LOWPASS = 3,
}

const CURSOR_RESET_POSITION: Vector2 = Vector2(100, 100)

const FILTER_CENTER: float = 0.5
const HIGHPASS_NEUTRAL_CUTOFF_HZ: float = 20.0
const HIGHPASS_MAX_CUTOFF_HZ: float = 650.0
const LOWPASS_NEUTRAL_CUTOFF_HZ: float = 20000.0
const LOWPASS_MIN_CUTOFF_HZ: float = 6500.0
const FILTER_RESONANCE: float = 0.15
const PHASER_MAX_DEPTH: float = 0.8
const DISTORTION_MAX_DRIVE: float = 0.3


const LIGHT_BASE_COLOR: Color = Color("#ffe8aa")
const LIGHT_BLEND_STRENGTH: float = 0.8
const LIGHT_LOW_ZONE: float = 0.35
const LIGHT_HIGH_ZONE: float = 0.65
const LIGHT_FLICKER_INTERVAL: float = 0.3

var bus_index: int = -1
var phaser: AudioEffectPhaser
var distortion: AudioEffectDistortion
var highpass: AudioEffectHighPassFilter
var lowpass: AudioEffectLowPassFilter

@export var klappy_light2D: PointLight2D
@export var klappy_light: OmniLight3D
@export var klappy_energy: ProgressBar
@export var face_light: SpotLight3D

var unlocked: bool = false
var flicker_done: bool = false
var has_audio_effects: bool = false
var is_dragging: bool = false

var colors_string: Array[String] = ["green", "red", "blue", "yellow", "green", "red", "blue", "yellow"]

@export var colormapje: Node3D

func _ready() -> void:
	EventBus.energy_points_changed.connect(on_klappy_energy)
	_setup_audio_effects()
	
	unlocked = false
	klappy_light.visible = true
	colormapje.visible = false

func _on_gui_input(event: InputEvent) -> void:
	if not unlocked:
		return

	colormapje.visible = true

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_dragging = event.is_pressed()
		_set_audio_effects_enabled(is_dragging)

		if event.is_pressed():
			_apply_pad_position(event.position)
		else:
			_reset_pad()

		accept_event()
		return

	if event is InputEventMouseMotion and (is_dragging or event.button_mask & MOUSE_BUTTON_MASK_LEFT):
		_apply_pad_position(event.position)
		accept_event()
		return

	if event is InputEventScreenTouch:
		is_dragging = event.is_pressed()
		_set_audio_effects_enabled(is_dragging)

		if event.is_pressed():
			_apply_pad_position(event.position)
		else:
			_reset_pad()

		accept_event()
		return

	if event is InputEventScreenDrag:
		is_dragging = true
		_set_audio_effects_enabled(true)
		_apply_pad_position(event.position)
		accept_event()

func _setup_audio_effects() -> void:
	bus_index = AudioServer.get_bus_index(BusNames.SUBMASTER_BUS)

	if bus_index == -1:
		push_warning("KlappyLightPad: Audio bus '%s' was not found." % BusNames.SUBMASTER_BUS)
		return

	if AudioServer.get_bus_effect_count(bus_index) <= PadEffect.LOWPASS:
		push_warning("KlappyLightPad: Audio bus '%s' does not have the required light pad effects." % BusNames.SUBMASTER_BUS)
		return

	phaser = AudioServer.get_bus_effect(bus_index, PadEffect.PHASER) as AudioEffectPhaser
	distortion = AudioServer.get_bus_effect(bus_index, PadEffect.DISTORTION) as AudioEffectDistortion
	highpass = AudioServer.get_bus_effect(bus_index, PadEffect.HIGHPASS) as AudioEffectHighPassFilter
	lowpass = AudioServer.get_bus_effect(bus_index, PadEffect.LOWPASS) as AudioEffectLowPassFilter
	has_audio_effects = phaser != null and distortion != null and highpass != null and lowpass != null

	if not has_audio_effects:
		push_warning("KlappyLightPad: SubMaster effects are not in the expected Phaser/Distortion/HighPass/LowPass order.")
		return

	_set_audio_effects_enabled(false)

func _set_audio_effects_enabled(enabled: bool) -> void:
	if not has_audio_effects:
		return

	if not enabled:
		_reset_all_pad_effects()

func _apply_pad_position(raw_position: Vector2) -> void:
	var pad_position: Vector2 = _get_clamped_pad_position(raw_position)
	var pad_percent: Vector2 = _get_pad_percent(pad_position)

	$cursor.position = pad_position

	if has_audio_effects:
		_update_quadrant_effect(pad_percent.x, 1.0 - pad_percent.y)

	_update_lights_from_pad_position(pad_percent)

func _get_clamped_pad_position(raw_position: Vector2) -> Vector2:
	return Vector2(
		clamp(raw_position.x, 0.0, size.x),
		clamp(raw_position.y, 0.0, size.y)
	)

func _get_pad_percent(pad_position: Vector2) -> Vector2:
	var safe_width: float = max(size.x, 1.0)
	var safe_height: float = max(size.y, 1.0)
	return Vector2(pad_position.x / safe_width, pad_position.y / safe_height)

func _update_lights_from_pad_position(pad_percent: Vector2) -> void:
	_set_light_nodes_visible(true)
	_set_light_color(_get_pad_light_color(pad_percent))

func _get_pad_light_color(pad_percent: Vector2) -> Color:
	var color: Color = LIGHT_BASE_COLOR

	if pad_percent.x >= LIGHT_HIGH_ZONE:
		color = color.lerp(Color.RED, LIGHT_BLEND_STRENGTH)
	if pad_percent.x <= LIGHT_LOW_ZONE:
		color = color.lerp(Color.GREEN, LIGHT_BLEND_STRENGTH)
	if pad_percent.y >= LIGHT_HIGH_ZONE:
		color = color.lerp(Color.BLUE, LIGHT_BLEND_STRENGTH)
	if pad_percent.y <= LIGHT_LOW_ZONE:
		color = color.lerp(Color.YELLOW, LIGHT_BLEND_STRENGTH)

	return color

func _set_light_color(color: Color) -> void:
	face_light.light_color = color
	klappy_light2D.color = color
	klappy_light.light_color = color
	$cursor/Trail.default_color = color

func _set_light_nodes_visible(should_show: bool) -> void:
	klappy_light2D.visible = should_show
	klappy_light.visible = should_show

func _update_quadrant_effect(x_percent: float, y_percent: float) -> void:
	var effect_amount: float = clamp(max(abs(x_percent - FILTER_CENTER), abs(y_percent - FILTER_CENTER)) * 2.0, 0.0, 1.0)
	var selected_effect: PadEffect = _get_quadrant_effect(x_percent, y_percent)

	_reset_all_pad_effects()

	match selected_effect:
		PadEffect.PHASER:
			AudioServer.set_bus_effect_enabled(bus_index, PadEffect.PHASER, true)
			phaser.depth = effect_amount * PHASER_MAX_DEPTH
		PadEffect.DISTORTION:
			AudioServer.set_bus_effect_enabled(bus_index, PadEffect.DISTORTION, true)
			distortion.drive = effect_amount * DISTORTION_MAX_DRIVE
		PadEffect.HIGHPASS:
			AudioServer.set_bus_effect_enabled(bus_index, PadEffect.HIGHPASS, true)
			highpass.cutoff_hz = lerp(HIGHPASS_NEUTRAL_CUTOFF_HZ, HIGHPASS_MAX_CUTOFF_HZ, effect_amount)
		PadEffect.LOWPASS:
			AudioServer.set_bus_effect_enabled(bus_index, PadEffect.LOWPASS, true)
			lowpass.cutoff_hz = lerp(LOWPASS_NEUTRAL_CUTOFF_HZ, LOWPASS_MIN_CUTOFF_HZ, effect_amount)

func _get_quadrant_effect(x_percent: float, y_percent: float) -> PadEffect:
	if x_percent < FILTER_CENTER and y_percent >= FILTER_CENTER:
		return PadEffect.PHASER
	if x_percent >= FILTER_CENTER and y_percent >= FILTER_CENTER:
		return PadEffect.HIGHPASS
	if x_percent < FILTER_CENTER and y_percent < FILTER_CENTER:
		return PadEffect.LOWPASS
	return PadEffect.DISTORTION

func _reset_all_pad_effects() -> void:
	AudioServer.set_bus_effect_enabled(bus_index, PadEffect.PHASER, false)
	AudioServer.set_bus_effect_enabled(bus_index, PadEffect.DISTORTION, false)
	AudioServer.set_bus_effect_enabled(bus_index, PadEffect.HIGHPASS, false)
	AudioServer.set_bus_effect_enabled(bus_index, PadEffect.LOWPASS, false)
	phaser.depth = 0.0
	distortion.drive = 0.0
	highpass.resonance = FILTER_RESONANCE
	lowpass.resonance = FILTER_RESONANCE
	highpass.cutoff_hz = HIGHPASS_NEUTRAL_CUTOFF_HZ
	lowpass.cutoff_hz = LOWPASS_NEUTRAL_CUTOFF_HZ

func _reset_pad() -> void:
	$cursor.position = CURSOR_RESET_POSITION
	colormapje.visible = true
	_set_light_nodes_visible(false)

func _set_klappy_light_energy(value: float) -> void:
	klappy_light.light_energy = value / 50.0
	klappy_light2D.energy = value / 50.0

func on_klappy_energy(value: float) -> void:
	_set_klappy_light_energy(value)
	if value >= EnergyManager.ENERGY_THRESHOLD_LIGHT_PAD and not flicker_done:
		unlocked = true
		flicker_done = true
		_set_light_nodes_visible(true)
		if not GameState.use_tutorial:
			KlappyVoice.say(KlappyLine.Id.LIGHT_PAD_UNLOCK)
		_light_flicker()
		await get_tree().create_timer(7.0).timeout
	
func _light_flicker() -> void:
	for color_name: String in colors_string:
		_set_light_color(Color(color_name))
		
		await get_tree().create_timer(LIGHT_FLICKER_INTERVAL).timeout
		
	colormapje.visible = true
	_set_light_color(Color.WHITE)	
