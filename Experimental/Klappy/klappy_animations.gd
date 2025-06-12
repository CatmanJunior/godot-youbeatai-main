extends Node3D

@onready var animation_tree = $AnimationTree

func _ready():
	animation_tree.set("parameters/ClapTrigger/seek_request", 10000.0)
	animation_tree.set("parameters/StampTrigger/seek_request", 10000.0)
	
	animation_tree.set("parameters/TimeScale/scale", 120/60.0)

func on_clap():
	print("event clap")
	animation_tree.set("parameters/ClapTrigger/seek_request", 0.0)

func on_stamp():
	print("event stamp")
	animation_tree.set("parameters/StampTrigger/seek_request", 0.0)

func on_bpm_changed(bpm:float):
	animation_tree.set("parameters/TimeScale/scale", bpm / 60.0)
