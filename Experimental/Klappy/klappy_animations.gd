extends Node3D

@onready var animation_tree = $AnimationTree
@onready var stamp_timer = $Stamp
@onready var clap_timer = $Clap

var beat_time = 0.0

func _ready():
	# set animation to end to prevent playing on start
	animation_tree.set("parameters/ClapTrigger/seek_request", 10000.0)
	animation_tree.set("parameters/StampTrigger/seek_request", 10000.0)
	
	# default speed for 120 bpm
	if beat_time == 0:
		on_bpm_changed(120.0)
	
	var on_clap_timer := func(): 
		animation_tree.set("parameters/ClapTrigger/seek_request", 0)
	clap_timer.timeout.connect( on_clap_timer )
	
	var on_stamp_timer := func():
		animation_tree.set("parameters/StampTrigger/seek_request", 0)
	stamp_timer.timeout.connect(on_stamp_timer)

func init():
	animation_tree = $AnimationTree
	stamp_timer = $Stamp
	clap_timer = $Clap

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			on_clap()
			on_stamp()

# trigger clap animation by setting time to 0.0
func on_clap():
	clap_timer.start()

# trigger stamp animation by setting time to 0.0
func on_stamp():
	stamp_timer.start()

# adjust animation speed to match bpm
func on_bpm_changed(bpm:float):
	# catch for when bpm change is called before onready
	if not clap_timer:
		init()
	
	beat_time = bpm / 60.0
	var beat_time_half = (1.0 / beat_time) * 0.25	
	clap_timer.wait_time = beat_time_half
	stamp_timer.wait_time = beat_time_half
	animation_tree.set("parameters/StampSpeed/scale", beat_time )
	animation_tree.set("parameters/ClapSpeed/scale", beat_time )
