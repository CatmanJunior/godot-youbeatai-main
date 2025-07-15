extends Node
class_name Envelope

signal level_changed(level: float)

@export_range(0.001, 10.0, 0.01) var attack_time: float
@export_range(0.001, 10.0, 0.01) var decay_time: float
@export_range(0.001, 1.0, 0.01) var sustain_level: float
@export_range(0.001, 10.0, 0.01) var sustain_time: float
@export_range(0.001, 10.0, 0.01) var release_time: float

var current_level: float
var time: float = 0


func _process(delta):
	time += delta

	var attack = lerpf( 0.0, 1.0, clampf(time/max(attack_time,0.001), 0.0, 1.0) )
	var sustain = lerpf( 1.0, sustain_level, clampf((time-attack_time)/max(decay_time,0.001), 0.0, 1.0) )
	var release = lerpf( 1.0, 0.0, clampf((time - attack_time - decay_time - sustain_time) /max(0.001,release_time), 0.0, 1.0) )
	current_level = attack * sustain * release
	level_changed.emit(current_level)

func play():
	time = 0

func get_duration():
	return attack_time + decay_time + sustain_time + release_time
