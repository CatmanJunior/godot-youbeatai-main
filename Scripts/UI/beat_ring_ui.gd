extends Node
class_name BeatRingUI

@export_category("Scale Tweens")
@export var scale_tween_duration: float = 0.2
@export var scale_tween_factor: float = 1.4

@export_category("References")
@export var beat_ring_pivot_point: Control
@export var pointer: Sprite2D
@export var play_pause_button: Button

@export var beat_button_prefab: PackedScene
@export var track_settings: TrackUISettingsRegistry


const BEAT_SCALE_32: float = 1.0
const BEAT_SCALE_16: float = 1.6
const BEAT_SCALE_8: float = 1.6
const GLOBAL_SPRITE_SCALE_FACTOR: float = 0.28

var _beat_buttons: Array = [] # 2D array [ring][beat]
var _track_controls: Array = [] # Array of Control nodes, one per track, that hold the beat buttons for that track

# -- Godot lifecycle --
func _ready() -> void:
	_init_beat_button_positions()
	EventBus.section_switched.connect(_on_switch_section)
	EventBus.beat_triggered.connect(_on_beat_triggered)
	EventBus.playing_changed.connect(_update_play_pause_button)
	EventBus.beat_state_changed.connect(_set_beat_active)
	EventBus.template_set.connect(_on_template_set)
	EventBus.track_sprites_visibility_requested.connect(_set_track_sprites_visible)
	play_pause_button.pressed.connect(_on_play_pause_button_toggled)

func _process(_delta: float) -> void:
	_update_pointer_rotation()


# -- Event handlers --
## Update all beat sprites to match the new template actives
func _on_template_set(actives: Array) -> void:
	_update_beats_active(actives)

func _on_switch_section(new_section: SectionData):
	_reset_scales()

	_update_beats_active(new_section.get_beat_actives())

func _on_beat_triggered(beat: int):
	_update_beat_sprites(beat)

func _on_play_pause_button_toggled() -> void:
	if not play_pause_button.disabled:
		EventBus.play_pause_toggle_requested.emit()


# -- Utility functions --
func _update_beats_active(actives: Array) -> void:
	for track in range(actives.size()):
		for beat in range(actives[track].size()):
			var active = actives[track][beat]
			_set_beat_active(track, beat, active)

func _set_beat_active(track: int, beat: int, active: bool):
	var beat_button = _get_beat_button(track, beat)
	if beat_button:
		beat_button.set_pressed_no_signal(active)

func _get_beat_button(track: int, beat: int) -> BeatButton:
	if track < _beat_buttons.size() and beat < _beat_buttons[track].size():
		return _beat_buttons[track][beat]
	push_error("Beat button not found for track " + str(track) + " beat " + str(beat))
	return null


## Rotate the pointer based on the current bar progress
func _update_pointer_rotation() -> void:
	if GameState.playing:
		pointer.rotation_degrees = GameState.bar_progress * 360.0 - 7.0

func _update_play_pause_button(is_playing: bool) -> void:
	play_pause_button.text = "⏸️" if is_playing else "▶️"

func _init_beat_button_positions() -> void:
	var beats_amount = SongState.total_beats

	_beat_buttons = []
	for track_index in range(SectionData.SAMPLE_TRACKS_PER_SECTION):
		#create a control node for each track to hold the beat buttons, so we can easily show/hide them when requested
		var track_control = Control.new()
		track_control.name = "Track" + str(track_index) + "_Beats"
		beat_ring_pivot_point.add_child(track_control)
		_track_controls.append(track_control)

		_beat_buttons.append([])
		for beat in range(beats_amount):
			var beat_button = _create_sprite(beat, track_index, beats_amount, track_control)
			_beat_buttons[track_index].append(beat_button)

func _create_sprite(beat: int, track_index: int, beats_amount: int, p_track_control : Control) -> BeatButton:
	var s := track_settings.get_sample_track(track_index)
	var tex_outline := s.beat_outline_texture
	var tex_filled := s.beat_filled_texture

	var beat_but: BeatButton = beat_button_prefab.instantiate() as BeatButton
	beat_but.init(beat, track_index, tex_outline, tex_filled)

	p_track_control.add_child(beat_but)

	var scale_factor = _scale_factor_for_beats_amount(beats_amount)
	beat_but.scale = Vector2.ONE * scale_factor * GLOBAL_SPRITE_SCALE_FACTOR

	# Offset position so the visual center lands on the ring point
	beat_but.pivot_offset = beat_but.size / 2.0
	beat_but.position = _sprite_position(beat, track_index, beats_amount) - beat_but.size / 2.0
	beat_but.rotation = _sprite_rotation(beat, track_index, beats_amount)

	return beat_but

func _scale_factor_for_beats_amount(beats_amount: int) -> float:
	if beats_amount == 32:
		return BEAT_SCALE_32
	elif beats_amount == 16:
		return BEAT_SCALE_16
	elif beats_amount == 8:
		return BEAT_SCALE_8
	return 1.0

func _sprite_position(beat: int, track_index: int, beats_amount: int) -> Vector2:
	var angle = PI * 2.0 * beat / beats_amount - PI / 2.0
	var distance = 0.0
	if beats_amount == 32:
		distance = (4 - track_index) * 30 + 110
	elif beats_amount == 16:
		distance = (4 - track_index) * 45 + 56
	elif beats_amount == 8:
		distance = (4 - track_index) * 45 + 56
	return Vector2(cos(angle), sin(angle)) * distance

func _sprite_rotation(beat: int, _track_index: int, beats_amount: int) -> float:
	return PI * 2.0 * beat / beats_amount

func _create_template_sprite(beat: int, track_index: int, beats_amount: int) -> Sprite2D:
	var sprite = Sprite2D.new()
	sprite.position = _sprite_position(beat, track_index, beats_amount)
	sprite.rotation = _sprite_rotation(beat, track_index, beats_amount)
	sprite.modulate = Color(0, 0, 0, 1)
	return sprite

func _update_beat_sprites(current_beat: int) -> void:
	var beats_amount = SongState.total_beats

	for track in range(_beat_buttons.size()):
		for beat in range(_beat_buttons[track].size()):
			var on_beat = (beat == current_beat)
			var active = SongState.is_beat_active(track, beat)

			var beatButton: BeatButton = _get_beat_button(track, beat)
			var color = track_settings.get_sample_track(track).track_color

			#scale up the beat button if it's the current beat and active, and scale back down if it's not
			if on_beat:
				_tween_beat_button_scale(beatButton, active, beats_amount)
			else:
				color = color.lightened(0.75)
				_tween_beat_button_scale(beatButton, false, beats_amount)

			beatButton.modulate = color

func _tween_beat_button_scale(beatButton: BeatButton, active: bool, beats_amount: int) -> void:
		var scale_factor: float = _scale_factor_for_beats_amount(beats_amount)
		var tween: Tween = get_tree().create_tween()
		var target_scale: Vector2 = Vector2.ONE * scale_factor * GLOBAL_SPRITE_SCALE_FACTOR
		if active:
			target_scale *= scale_tween_factor
		
		tween.tween_property(beatButton, "scale", target_scale, scale_tween_duration)

# Reset all beat sprite scales (called after a section switch)
func _reset_scales() -> void:
	var beats_amount = SongState.total_beats
	for track in range(_beat_buttons.size()):
		for beat in range(_beat_buttons[track].size()):
			var sprite: BeatButton = _get_beat_button(track, beat)
			if sprite:
				var scale_factor: float = _scale_factor_for_beats_amount(beats_amount)
				sprite.scale = Vector2.ONE * scale_factor * GLOBAL_SPRITE_SCALE_FACTOR


## Set the sprites for a specific track visible 
func _set_track_sprites_visible(track: int, visible: bool) -> void:
	if track >= 0 and track < _track_controls.size():
		_track_controls[track].visible = visible