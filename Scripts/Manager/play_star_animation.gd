extends Node2D
@export var anim_player:AnimationPlayer
@export var animation_resource: Animation
signal animation_star_play
signal animation_star_stop

func _enter_tree() -> void:
	animation_star_play.connect(play)
	animation_star_stop.connect(stop)

func play():
	anim_player.play(animation_resource.resource_name)
	

func stop():
	anim_player.stop()
 
