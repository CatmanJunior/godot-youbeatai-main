extends Node

@export var count_down_panel: Panel
@export var count_down_label: Label

var is_showing_count_down: bool = false
var _last_tick: int = -1

func _ready():
	EventBus.countdown_show_requested.connect(show_count_down)
	EventBus.countdown_close_requested.connect(close_count_down)

func _process(_delta: float):
	if is_showing_count_down:
		update_count_down_label()

func show_count_down():
	is_showing_count_down = true
	_last_tick = 5
	count_down_panel.visible = true


func close_count_down():
	count_down_panel.visible = false
	is_showing_count_down = false
	_last_tick = 5

func update_count_down_label():
	var time_until_top = BeatManager.calculate_time_until_top()
	var seconds: int = int(ceil(time_until_top))
	if seconds < _last_tick and seconds > 0:
		count_down_label.text = str(snapped(time_until_top, 1))
		_last_tick = seconds
		EventBus.countdown_tick.emit(seconds)
