extends Node
class_name BeatRingUI

@export var beat_button_prefab: PackedScene
@export var beat_ring_pivot_point: Control
@export var track_settings: TrackSettingsRegistry


@export var play_pause_button: Button

@export var pointer: Sprite2D

var beat_buttons: Array = [] # 2D array [ring][beat]

# Private state – sprite scale factors
var _beat_scale_32: float = 1.0
var _beat_scale_16: float = 1.6
var _beat_scale_8: float = 1.6
var _global_beat_sprite_scale_factor: float = 0.28

func _ready() -> void:
	_init_beat_but_positions()
	EventBus.section_switched.connect(_on_switch_section)
	EventBus.beat_triggered.connect(_on_beat_triggered)
	EventBus.playing_changed.connect(_update_play_pause_button)
	EventBus.beat_state_changed.connect(set_beat_active)

func set_beat_active(ring: int, beat: int, active: bool):
	if ring < beat_buttons.size() and beat < beat_buttons[ring].size():
		var beat_button : BeatButton = beat_buttons[ring][beat]
		beat_button.set_pressed_no_signal(active)

func _process(_delta: float) -> void:
	_update_pointer()

func _update_pointer() -> void:
	if GameState.playing:
		pointer.rotation_degrees = GameState.bar_progress * 360.0 - 7.0

func _on_play_pause_toggled() -> void:
	if not play_pause_button.disabled:
		EventBus.play_pause_toggle_requested.emit()

func _update_play_pause_button(is_playing: bool) -> void:
	play_pause_button.text = "⏸️" if is_playing else "▶️"

func _on_beat_triggered(beat: int):
	_update_beat_sprites(beat)

func _on_switch_section(_old_section: SectionData, _new_section: SectionData):
	_reset_scales()

func _init_beat_but_positions() -> void:
	var beats_amount = GameState.total_beats

	beat_buttons = []
	for ring in range(4):
		beat_buttons.append([])
		for beat in range(beats_amount):
			var beat_button = _create_sprite(beat, ring, beats_amount)
			beat_buttons[ring].append(beat_button)

func _create_sprite(beat: int, ring: int, beats_amount: int) -> BeatButton:
	var s := track_settings.get_sample_track(ring)
	var tex_outline := s.beat_outline_texture
	var tex_filled  := s.beat_filled_texture

	var beat_but: BeatButton = beat_button_prefab.instantiate() as BeatButton
	beat_but.init(beat, ring, tex_outline, tex_filled)

	beat_ring_pivot_point.add_child(beat_but)

	var scale_factor = _scale_factor_for_beats_amount(beats_amount)
	beat_but.scale = Vector2.ONE * scale_factor * _global_beat_sprite_scale_factor

	# Offset position so the visual center lands on the ring point
	beat_but.pivot_offset = beat_but.size / 2.0
	beat_but.position = _sprite_position(beat, ring, beats_amount) - beat_but.size / 2.0
	beat_but.rotation = _sprite_rotation(beat, ring, beats_amount)

	return beat_but

func _scale_factor_for_beats_amount(beats_amount: int) -> float:
	if beats_amount == 32:
		return _beat_scale_32
	elif beats_amount == 16:
		return _beat_scale_16
	elif beats_amount == 8:
		return _beat_scale_8
	return 1.0

func _sprite_position(beat: int, ring: int, beats_amount: int) -> Vector2:
	var angle = PI * 2.0 * beat / beats_amount - PI / 2.0
	var distance = 0.0
	if beats_amount == 32:
		distance = (4 - ring) * 30 + 110
	elif beats_amount == 16:
		distance = (4 - ring) * 45 + 56
	elif beats_amount == 8:
		distance = (4 - ring) * 45 + 56
	return Vector2(cos(angle), sin(angle)) * distance

func _sprite_rotation(beat: int, _ring: int, beats_amount: int) -> float:
	return PI * 2.0 * beat / beats_amount


func _create_template_sprite(beat: int, ring: int, beats_amount: int) -> Sprite2D:
	var sprite = Sprite2D.new()
	sprite.position = _sprite_position(beat, ring, beats_amount)
	sprite.rotation = _sprite_rotation(beat, ring, beats_amount)
	sprite.modulate = Color(0, 0, 0, 1)
	return sprite


func _update_beat_sprites(current_beat: int) -> void:
	var beats_amount = GameState.total_beats

	for ring in range(min(4, beat_buttons.size())):
		for beat in range(min(beats_amount, beat_buttons[ring].size())):
			var active = (beat == current_beat)
			var beatButton : BeatButton = beat_buttons[ring][beat]
			
			var color = track_settings.get_sample_track(ring).track_color
			if active:
				beatButton.modulate = color
			else:
				color = color.lightened(0.75)
				beatButton.modulate = color

			#TODO tween this
			var scale_factor = _scale_factor_for_beats_amount(beats_amount)
			if beatButton.scale.x > scale_factor * _global_beat_sprite_scale_factor:
				var delta = beatButton.scale.x - scale_factor * _global_beat_sprite_scale_factor
				beatButton.scale -= Vector2.ONE * delta * 0.3

func _get_template_active(ring: int, beat: int) -> bool:
	var current_actives = %TemplateManager.get_current_actives()
	if ring >= 0 and ring < current_actives.size():
		var row = current_actives[ring]
		if beat >= 0 and beat < row.size():
			return row[beat]
	return false

# Reset all beat sprite scales (called after a section switch)
func _reset_scales() -> void:
	var beats_amount = GameState.total_beats
	for ring in range(min(4, beat_buttons.size())):
		for beat in range(min(beats_amount, beat_buttons[ring].size())):
			var sprite = beat_buttons[ring][beat] as BeatButton
			var scale_factor = _scale_factor_for_beats_amount(beats_amount)
			sprite.scale = Vector2.ONE * scale_factor * _global_beat_sprite_scale_factor
