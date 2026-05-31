extends Node3D
class_name KlappyAnimations
## Manages Klappy's animations, triggered by events and energy level.


enum AnimationType {
	CLAP,
	STAMP,
	TALKING,
	SAD,
	HAPPY
}

@onready var animation_tree: AnimationTree = $model/AnimationTree
@onready var animation_player: AnimationPlayer = $model/AnimationPlayer

var talking = false
var beat_time = 0.0

var animtriggered = false

func _ready():
	# set animation to end to prevent playing on start
	animation_tree.set("parameters/ClapTrigger/seek_request", 10000.0)
	animation_tree.set("parameters/StampTrigger/seek_request", 10000.0)
	animation_tree.set("parameters/talkingTrigger/seek_request", 10000.0)
	animation_tree.set("parameters/sadTrigger/seek_request", 10000.0)
	animation_tree.set("parameters/happyTrigger/seek_request", 10000.0)
	
	EventBus.trigger_animation_requested.connect(_on_trigger_animation)
	EventBus.energy_points_changed.connect(on_klappy_energy)
	EventBus.bpm_changed.connect(on_bpm_changed)
	EventBus.utterance_ended.connect(_on_utterance_end)
	EventBus.utterance_canceled.connect(_on_utterance_end)
	EventBus.utterance_started.connect(_on_callback_)
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

func _on_trigger_animation(animation_type: int) -> void:
	if animation_type == KlappyAnimations.AnimationType.CLAP:
		on_clap()
	elif animation_type == KlappyAnimations.AnimationType.STAMP:
		on_stamp()
	elif animation_type == KlappyAnimations.AnimationType.TALKING:
		on_talking()
	elif animation_type == KlappyAnimations.AnimationType.SAD:
		animation_tree.set("parameters/sadTrigger/seek_request", 0)
	elif animation_type == KlappyAnimations.AnimationType.HAPPY:
		animation_tree.set("parameters/happyTrigger/seek_request", 0)

# trigger clap animation by setting time to 0.0
func on_clap():
	animation_tree.set("parameters/ClapTrigger/seek_request", 0)
	#clap_timer.start()

# trigger stamp animation by setting time to 0.0
func on_stamp():
	animation_tree.set("parameters/StampTrigger/seek_request", 0)

func _on_callback_(_i: int):
	# Start the mouth on every utterance; it loops via on_talking() until speech ends.
	talking = true
	animation_tree.set("parameters/talkingTrigger/seek_request", 0)



func on_talking():
	if !talking:
		return
	animation_tree.set("parameters/talkingTrigger/seek_request", 0)

func _on_utterance_end(_utterance: int):
	talking = false
	animation_tree.set("parameters/talkingTrigger/seek_request", 10000.0)

# adjust animation speed to match bpm
func on_bpm_changed(bpm: float):
	# catch for when bpm change is called before onready
	if not animation_tree:
		init()
	
	# beat duration for 2 beats (/4.0) for 1 beat
	# animation duration is made for 2 beats
	beat_time = (60.0 / bpm / 2.0)
	animation_tree.set("parameters/TimeScale/scale", 1.0 / beat_time)


## Adjusts klappy's face based on energy level. Triggers sad at 0 and happy at 100.
## No animation is triggered in between.
func on_klappy_energy(value):
	if value <= 0 and !animtriggered:
		animation_tree.set("parameters/sadTrigger/seek_request", 0)
		animtriggered = true
	elif value >= 100 and !animtriggered:
		animation_tree.set("parameters/happyTrigger/seek_request", 0)
		animtriggered = true
	elif value > 0 and value < 100:
		animtriggered = false
