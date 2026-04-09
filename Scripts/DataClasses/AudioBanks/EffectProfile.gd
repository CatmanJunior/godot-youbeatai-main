class_name EffectProfile
extends Resource

@export var pitch_shift: float
@export var distortion_db: float
@export var phaser: float
@export var delay: float
@export var reverb: float
@export var chorus: bool


enum EffectType {
	PITCH_SHIFT,
	DISTORTION,
	PHASER,
	CHORUS,
	DELAY,
	REVERB
}



var effect_values: Dictionary = {
	EffectType.PITCH_SHIFT: [AudioEffectPitchShift, apply_pitch_shift, pitch_shift],
	EffectType.DISTORTION: [AudioEffectDistortion, apply_distortion, distortion_db],
	EffectType.PHASER: [AudioEffectPhaser, apply_phaser, phaser],
	EffectType.CHORUS: [AudioEffectChorus, null, chorus],
	EffectType.DELAY: [AudioEffectDelay, apply_delay, delay],
	EffectType.REVERB: [AudioEffectReverb, apply_reverb, reverb]
}

func apply_effects(bus_index: int) -> void:
	var i : int = 0
	for effect_type in EffectType.values():
		var effect_class = effect_values[effect_type][0]
		var callable : Callable = effect_values[effect_type][1]
		var value = effect_values[effect_type][2]
		var effect_instance = effect_class.new()
		_add_effect_bus(effect_instance, bus_index, i, value)
		if callable:
			callable.call(effect_instance, value)
		i += 1

func _add_effect_bus(effect: AudioEffect, bus_index: int, effect_index: int, value):
	var new_effect: AudioEffect = effect.new()
	AudioServer.add_bus_effect(bus_index, new_effect)
	if value > 0:
		AudioServer.set_bus_effect_enabled(bus_index, effect_index, true)

func apply_pitch_shift(bus_effect: AudioEffectPitchShift, value: float) -> void:
	bus_effect.pitch_scale = value if value > 0 else 1.0

func apply_distortion(bus_effect: AudioEffectDistortion, value: float) -> void:
	bus_effect.pre_gain = value

func apply_phaser(bus_effect: AudioEffectPhaser, value: float) -> void:
	bus_effect.rate_hz = value

func apply_delay(bus_effect: AudioEffectDelay, value: float) -> void:
	bus_effect.tap1_delay_ms = value
	bus_effect.tap2_delay_ms = value * 2

func apply_reverb(bus_effect: AudioEffectReverb, value: float) -> void:
	bus_effect.room_size = value
