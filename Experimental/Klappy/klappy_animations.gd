extends Node3D

@onready var animation_tree = $AnimationTree

func _ready():
	animation_tree.set("parameters/ClapTrigger/seek_request", 10000.0)
	animation_tree.set("parameters/StampTrigger/seek_request", 10000.0)
	
	animation_tree.set("parameters/TimeScale/scale", 120/60.0)

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_S:
			animation_tree.set("parameters/ClapTrigger/seek_request", 0.0)
		if event.keycode == KEY_A:
			animation_tree.set("parameters/StampTrigger/seek_request", 0.0)

func on_bpm_changed(bpm:float):
	animation_tree.set("parameters/TimeScale/scale", bpm / 60.0)
