extends Node

@export var count_down_panel: Panel
@export var count_down_label: Label
@export var mic_button_location: Node2D

var is_showing_count_down: bool = false


func _ready():
    EventBus.countdown_show_requested.connect(show_count_down)
    EventBus.countdown_close_requested.connect(close_count_down)

    var mixing_manager = %MixingManager
    if mixing_manager:
        mic_button_location = mixing_manager.mic_button_location

func _process(_delta: float):
    if is_showing_count_down:
        update_count_down_label()

func show_count_down():
    if count_down_panel and mic_button_location:
        count_down_panel.position = mic_button_location.global_position - count_down_panel.size / 2.0 * count_down_panel.scale
    is_showing_count_down = true


func close_count_down():
    if count_down_panel:
        count_down_panel.position = - count_down_panel.size / 2.0 + Vector2.UP * 1000
    is_showing_count_down = false


func update_count_down_label():
    count_down_label.text = str(snapped(calculate_time_until_top(), 1))


func calculate_time_until_top() -> float:
    var cur_beat: int = GameState.current_beat
    var beats_until_top: int = GameState.total_beats - cur_beat - 1
    var four_beats_until_top: int = beats_until_top / 4
    return four_beats_until_top + 1
