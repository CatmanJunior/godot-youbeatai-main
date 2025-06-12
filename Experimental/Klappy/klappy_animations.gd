extends Node3D

@onready var animation_tree = $AnimationTree

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_C:
			animation_tree.set("parameters/ClapTrigger/seek_request", 0.0)
		if event.keycode == KEY_S:
			animation_tree.set("parameters/StampTrigger/seek_request", 0.0)
