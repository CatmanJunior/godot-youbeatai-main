extends Node3D

@onready var animation_tree = $model/AnimationTree

var talking = false
var beat_time = 0.0

func _ready():
	# set animation to end to prevent playing on start
	animation_tree.set("parameters/ClapTrigger/seek_request", 10000.0)
	animation_tree.set("parameters/StampTrigger/seek_request", 10000.0)
	animation_tree.set("parameters/talkingTrigger/seek_request", 10000.0)
	
	# default speed for 120 bpm
	if beat_time == 0:
		on_bpm_changed(120.0)

func init():
	animation_tree = $model/AnimationTree

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			on_clap()
			on_stamp()
			on_talking()

func _process(_delta: float) -> void:
	if talking: return
	if DisplayServer.tts_is_speaking():
			on_talking()

# trigger clap animation by setting time to 0.0
func on_clap():
	animation_tree.set("parameters/ClapTrigger/seek_request", 0)
	#clap_timer.start()

# trigger stamp animation by setting time to 0.0
func on_stamp():
	animation_tree.set("parameters/StampTrigger/seek_request", 0)

func on_talking():
	animation_tree.set("parameters/talkingTrigger/seek_request",0)
	talking = true
	get_tree().create_timer(0.7).timeout.connect(_on_timeout)

func _on_timeout():
	talking = false

# adjust animation speed to match bpm
func on_bpm_changed(bpm:float):
	# catch for when bpm change is called before onready
	if not animation_tree:
		init()
	
	# beat duration for 2 beats (/4.0) for 1 beat
	# animation duration is made for 2 beats
	beat_time = (60.0 / bpm / 2.0)
	animation_tree.set("parameters/TimeScale/scale", 1.0 / beat_time )
