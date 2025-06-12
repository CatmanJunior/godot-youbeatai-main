extends Node3D

@onready var animation_tree = $AnimationTree

func _ready():
	# set animation to end to prevent playing on start
	animation_tree.set("parameters/ClapTrigger/seek_request", 10000.0)
	animation_tree.set("parameters/StampTrigger/seek_request", 10000.0)
	
	# default speed for 120 bpm
	animation_tree.set("parameters/TimeScale/scale", 120/60.0)

# trigger clap animation by setting time to 0.0
func on_clap():
	animation_tree.set("parameters/ClapTrigger/seek_request", 0.0)

# trigger stamp animation by setting time to 0.0
func on_stamp():
	animation_tree.set("parameters/StampTrigger/seek_request", 0.0)

# adjust animation speed to match bpm
func on_bpm_changed(bpm:float):
	animation_tree.set("parameters/TimeScale/scale", bpm / 60.0)
