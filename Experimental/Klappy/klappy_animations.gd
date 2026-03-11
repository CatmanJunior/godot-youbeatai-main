extends Node3D

@onready var animation_tree:AnimationTree = $model/AnimationTree
@onready var animation_player:AnimationPlayer = $model/AnimationPlayer

var first_talk = false
var talking = false
var beat_time = 0.0

func _ready():
	
	# set animation to end to prevent playing on start
	animation_tree.set("parameters/ClapTrigger/seek_request", 10000.0)
	animation_tree.set("parameters/StampTrigger/seek_request", 10000.0)
	animation_tree.set("parameters/talkingTrigger/seek_request", 10000.0)
	EventBus.utterance_ended.connect(_on_utterance_end)
	EventBus.bpm_changed.connect(on_bpm_changed)
	
	# default speed for 120 bpm
	if beat_time == 0:
		on_bpm_changed(120.0)
	
func init():
	animation_tree = $model/AnimationTree

#func _input(event):
	#if event is InputEventKey and event.pressed:
		#if event.keycode == KEY_SPACE:
			#on_clap()
			#on_stamp()
			#on_talking()


# trigger clap animation by setting time to 0.0
func on_clap():
	animation_tree.set("parameters/ClapTrigger/seek_request", 0)
	#clap_timer.start()

# trigger stamp animation by setting time to 0.0
func on_stamp():
	animation_tree.set("parameters/StampTrigger/seek_request", 0)

func _on_callback_(_i:int):
	if !first_talk:
			talking = true
			first_talk = true
			animation_tree.set("parameters/talkingTrigger/seek_request",0)

func on_talking():
	if !talking: 
		return
	animation_tree.set("parameters/talkingTrigger/seek_request",0)

func _on_utterance_end(_utterance:int):
	talking = false
	first_talk = false
	animation_tree.advance(100)

# adjust animation speed to match bpm
func on_bpm_changed(bpm:float):
	# catch for when bpm change is called before onready
	if not animation_tree:
		init()
	
	# beat duration for 2 beats (/4.0) for 1 beat
	# animation duration is made for 2 beats
	beat_time = (60.0 / bpm / 2.0)
	animation_tree.set("parameters/TimeScale/scale", 1.0 / beat_time )
