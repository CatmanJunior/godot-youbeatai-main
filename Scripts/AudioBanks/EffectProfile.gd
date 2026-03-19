class_name EffectProfile
extends Resource

@export var pitch_shift: float
@export var distortion_db: float
@export var phaser: float
@export var delay: float
@export var reverb: float
@export var chorus: bool

func apply_effects(bus_index: int) -> void:
	apply_pitch_shift(bus_index, 0, pitch_shift)
	apply_distortion(bus_index, 1, distortion_db)
	apply_phaser(bus_index, 2, phaser)
	apply_chorus(bus_index, 3, chorus)
	apply_delay(bus_index, 4, delay)
	apply_reverb(bus_index, 5, reverb)

func apply_pitch_shift(bus_index: int, effect_index: int, value: float) -> void:
	var pitch: AudioEffectPitchShift = AudioServer.get_bus_effect(bus_index, effect_index)
	AudioServer.set_bus_effect_enabled(bus_index, effect_index, value > 0)
	pitch.pitch_scale = value if value > 0 else 1.0

func apply_distortion(bus_index: int, effect_index: int, value: float) -> void:
	var distortion: AudioEffectDistortion = AudioServer.get_bus_effect(bus_index, effect_index)
	AudioServer.set_bus_effect_enabled(bus_index, effect_index, value > 0)
	distortion.pre_gain = value

func apply_phaser(bus_index: int, effect_index: int, value: float) -> void:
	var phaser_effect: AudioEffectPhaser = AudioServer.get_bus_effect(bus_index, effect_index)
	AudioServer.set_bus_effect_enabled(bus_index, effect_index, value > 0)
	if value > 0:
		phaser_effect.rate_hz = value

func apply_chorus(bus_index: int, effect_index: int, enabled: bool) -> void:
	AudioServer.set_bus_effect_enabled(bus_index, effect_index, enabled)

func apply_delay(bus_index: int, effect_index: int, value: float) -> void:
	var delay_effect: AudioEffectDelay = AudioServer.get_bus_effect(bus_index, effect_index)
	AudioServer.set_bus_effect_enabled(bus_index, effect_index, value > 0)
	if value > 0:
		delay_effect.tap1_delay_ms = value
		delay_effect.tap2_delay_ms = value * 2

func apply_reverb(bus_index: int, effect_index: int, value: float) -> void:
	var reverb_effect: AudioEffectReverb = AudioServer.get_bus_effect(bus_index, effect_index)
	AudioServer.set_bus_effect_enabled(bus_index, effect_index, value > 0)
	if value > 0:
		reverb_effect.room_size = value

