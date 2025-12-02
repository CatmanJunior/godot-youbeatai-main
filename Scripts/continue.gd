extends Button
@export var anim: AnimationPlayer
@export var animation: Animation 
signal animation_play
signal animation_stop

func _enter_tree()-> void:
	animation_play.connect(play)
	animation_stop.connect(stop)

func play() -> void:
	anim.play(animation.resource_name)

func stop() -> void:
	anim.stop()
