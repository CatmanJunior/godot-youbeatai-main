extends Node

@export var count_down_panel: Panel
@export var count_down_label: Label

var is_showing_count_down: bool = false

func _ready():
	EventBus.countdown_show_requested.connect(show_count_down)
	EventBus.countdown_close_requested.connect(close_count_down)

func _process(_delta: float):
	if is_showing_count_down:
		update_count_down_label()

func show_count_down():
	is_showing_count_down = true


func close_count_down():
	if count_down_panel:
		count_down_panel.position = - count_down_panel.size / 2.0 + Vector2.UP * 1000
	is_showing_count_down = false


func update_count_down_label():
	var time_until_top = BeatManager.calculate_time_until_top()
	count_down_label.text = str(snapped(time_until_top, 1))



