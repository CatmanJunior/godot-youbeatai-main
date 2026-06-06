extends Control

const PHASER_EFFECT_INDEX: int = 0
const DISTORTION_EFFECT_INDEX: int = 1
const HIGHPASS_EFFECT_INDEX: int = 2
const LOWPASS_EFFECT_INDEX: int = 3
const CURSOR_RESET_POSITION: Vector2 = Vector2(100, 100)
const FILTER_DEAD_ZONE_HALF: float = 0.12
const FILTER_CENTER: float = 0.5
const HIGHPASS_NEUTRAL_CUTOFF_HZ: float = 20.0
const HIGHPASS_MAX_CUTOFF_HZ: float = 650.0
const LOWPASS_NEUTRAL_CUTOFF_HZ: float = 20000.0
const LOWPASS_MIN_CUTOFF_HZ: float = 6500.0
const FILTER_RESONANCE: float = 0.15
const PHASER_MAX_DEPTH: float = 0.35
const DISTORTION_MAX_DRIVE: float = 0.16

var bus_index: int = -1
var phaser: AudioEffectPhaser
var distortion: AudioEffectDistortion
var highpass: AudioEffectHighPassFilter
var lowpass: AudioEffectLowPassFilter

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

	if AudioServer.get_bus_effect_count(bus_index) <= LOWPASS_EFFECT_INDEX:
		push_warning("KlappyLightPad: Audio bus '%s' does not have the required light pad effects." % BusNames.SUBMASTER_BUS)
		return

	phaser = AudioServer.get_bus_effect(bus_index, PHASER_EFFECT_INDEX) as AudioEffectPhaser
	distortion = AudioServer.get_bus_effect(bus_index, DISTORTION_EFFECT_INDEX) as AudioEffectDistortion
	highpass = AudioServer.get_bus_effect(bus_index, HIGHPASS_EFFECT_INDEX) as AudioEffectHighPassFilter
	lowpass = AudioServer.get_bus_effect(bus_index, LOWPASS_EFFECT_INDEX) as AudioEffectLowPassFilter
	has_audio_effects = phaser != null and distortion != null and highpass != null and lowpass != null

	if not has_audio_effects:
		push_warning("KlappyLightPad: SubMaster effects are not in the expected Phaser/Distortion/HighPass/LowPass order.")
		return

	_set_audio_effects_enabled(false)

func _set_audio_effects_enabled(enabled: bool) -> void:
	if not has_audio_effects:
		return

	AudioServer.set_bus_effect_enabled(bus_index, PHASER_EFFECT_INDEX, enabled)
	AudioServer.set_bus_effect_enabled(bus_index, DISTORTION_EFFECT_INDEX, enabled)

	if not enabled:
		_reset_filter_effects()

func _apply_pad_position(raw_position: Vector2) -> void:
	var pos: Vector2 = raw_position
	pos.x = clamp(pos.x, 0.0, size.x) #zorgt dat je binnen het grid blijft
	pos.y = clamp(pos.y, 0.0, size.y)

	$cursor.position = pos

	var safe_width: float = max(size.x, 1.0)
	var safe_height: float = max(size.y, 1.0)
	var x_percent: float = pos.x / safe_width #ipv pixels maakt hij er 200/0 van
	var y_percent: float = 1.0 - (pos.y / safe_height)

	if has_audio_effects:
		phaser.depth = clamp(1.0 - x_percent * 2.0, 0.0, 1.0) * PHASER_MAX_DEPTH
		distortion.drive = clamp((x_percent - 0.5) * 2.0, 0.0, 1.0) * DISTORTION_MAX_DRIVE
		_update_filter_effects(y_percent)

	klappy_light.visible = true
	face_light.light_color = klappy_light.light_color
	#klappys lampje word veranderd van kleur op basis van muis positie in het vak
	var color: Color = Color("#ffe8aa")
	var strength: float = 0.8
	#het midden is 100 dus vanaf daar meten (0-200)
	if pos.x >= 130:
		color = color.lerp(Color.RED, strength)
	if pos.x <= 70:
		color = color.lerp(Color.GREEN, strength)
	if pos.y >= 130:
		color = color.lerp(Color.BLUE, strength)
	if pos.y <= 70:
		color = color.lerp(Color.YELLOW, strength)

	klappy_light.light_color = color
	$cursor/Trail.default_color = color # trail word dezelfde kleur als light

func _update_filter_effects(y_percent: float) -> void:
	highpass.resonance = FILTER_RESONANCE
	lowpass.resonance = FILTER_RESONANCE

	var highpass_start: float = FILTER_CENTER + FILTER_DEAD_ZONE_HALF
	var lowpass_start: float = FILTER_CENTER - FILTER_DEAD_ZONE_HALF
	var highpass_amount: float = clamp((y_percent - highpass_start) / (1.0 - highpass_start), 0.0, 1.0)
	var lowpass_amount: float = clamp((lowpass_start - y_percent) / lowpass_start, 0.0, 1.0)

	if highpass_amount > 0.0:
		AudioServer.set_bus_effect_enabled(bus_index, HIGHPASS_EFFECT_INDEX, true)
		AudioServer.set_bus_effect_enabled(bus_index, LOWPASS_EFFECT_INDEX, false)
		highpass.cutoff_hz = lerp(HIGHPASS_NEUTRAL_CUTOFF_HZ, HIGHPASS_MAX_CUTOFF_HZ, highpass_amount)
		lowpass.cutoff_hz = LOWPASS_NEUTRAL_CUTOFF_HZ
		return

	if lowpass_amount > 0.0:
		AudioServer.set_bus_effect_enabled(bus_index, HIGHPASS_EFFECT_INDEX, false)
		AudioServer.set_bus_effect_enabled(bus_index, LOWPASS_EFFECT_INDEX, true)
		highpass.cutoff_hz = HIGHPASS_NEUTRAL_CUTOFF_HZ
		lowpass.cutoff_hz = lerp(LOWPASS_NEUTRAL_CUTOFF_HZ, LOWPASS_MIN_CUTOFF_HZ, lowpass_amount)
		return

	_reset_filter_effects()

func _reset_filter_effects() -> void:
	AudioServer.set_bus_effect_enabled(bus_index, HIGHPASS_EFFECT_INDEX, false)
	AudioServer.set_bus_effect_enabled(bus_index, LOWPASS_EFFECT_INDEX, false)
	highpass.resonance = FILTER_RESONANCE
	lowpass.resonance = FILTER_RESONANCE
	highpass.cutoff_hz = HIGHPASS_NEUTRAL_CUTOFF_HZ
	lowpass.cutoff_hz = LOWPASS_NEUTRAL_CUTOFF_HZ

func _reset_pad() -> void:
	$cursor.position = CURSOR_RESET_POSITION
	colormapje.visible = true
	klappy_light.visible = false

func _set_klappy_light_energy(value: float) -> void:
	klappy_light.light_energy = value / 50.0

func on_klappy_energy(value: float) -> void:
	_set_klappy_light_energy(value)
	if value >= EnergyManager.ENERGY_THRESHOLD_LIGHT_PAD and not flicker_done:
		unlocked = true
		flicker_done = true
		if not GameState.use_tutorial:
			KlappyVoice.say(KlappyLine.Id.LIGHT_PAD_UNLOCK)
		_light_flicker()
		await get_tree().create_timer(7.0).timeout
	
func _light_flicker() -> void:
	for color_name: String in colors_string:
		klappy_light.light_color = Color(color_name)
		
		await get_tree().create_timer(0.3).timeout
		
	colormapje.visible = true
	klappy_light.light_color = Color.WHITE	
