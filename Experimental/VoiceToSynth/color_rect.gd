extends ColorRect

@export var timer: Timer

var last_time: float = 0

func _ready():
	_on_bpm_change(120)

func _on_reset():
	color = Color.WHITE

func _on_beat():
	color = Color.RED
	timer.start()
	last_time = Time.get_unix_time_from_system()

func _on_bpm_change(bpm):
	timer.wait_time = (60.0 / bpm) / 2.0
