extends Node
class_name BeatRingUI

@export var sprite_prefab: PackedScene
@export var beat_ring_pivot_point: Control
@export var filled_beat_textures: Array[Texture2D]
@export var outline_beat_textures: Array[Texture2D]
@export var dot_beat_texture: Texture2D


var beat_sprites: Array = [] # 2D array [ring][beat]
var template_sprites: Array = [] # 2D array [ring][beat]

# Private state – sprite scale factors
var _beat_scale_32: float = 1.0
var _beat_scale_16: float = 1.6
var _beat_scale_8: float = 1.6
var _global_beat_sprite_scale_factor: float = 0.28

func _ready() -> void:
	_initialize_sprite_positions()
	EventBus.section_switched.connect(_on_switch_section)

func _on_switch_section(_old_section: SectionData, _new_section: SectionData):
	_reset_scales()

func _initialize_sprite_positions() -> void:
	var beats_amount = GameState.total_beats

	beat_sprites = []
	for ring in range(4):
		beat_sprites.append([])
		for beat in range(beats_amount):
			var sprite = _create_sprite(beat, ring, beats_amount)
			beat_ring_pivot_point.add_child(sprite)
			beat_sprites[ring].append(sprite)

	template_sprites = []
	for ring in range(4):
		template_sprites.append([])
		for beat in range(beats_amount):
			var sprite = _create_template_sprite(beat, ring, beats_amount)
			beat_ring_pivot_point.add_child(sprite)
			template_sprites[ring].append(sprite)

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

func _create_sprite(beat: int, ring: int, beats_amount: int) -> Sprite2D:
	var sprite = sprite_prefab.instantiate() as Sprite2D
	sprite.position = _sprite_position(beat, ring, beats_amount)
	sprite.rotation = _sprite_rotation(beat, ring, beats_amount)
	sprite.set_sprite_index(beat)
	sprite.set_ring(ring)

	var scale_factor = _scale_factor_for_beats_amount(beats_amount)
	sprite.scale = Vector2.ONE * scale_factor * _global_beat_sprite_scale_factor

	if ring < filled_beat_textures.size():
		sprite.texture = filled_beat_textures[ring]

	return sprite

func _create_template_sprite(beat: int, ring: int, beats_amount: int) -> Sprite2D:
	var sprite = Sprite2D.new()
	sprite.position = _sprite_position(beat, ring, beats_amount)
	sprite.rotation = _sprite_rotation(beat, ring, beats_amount)
	sprite.texture = dot_beat_texture
	sprite.modulate = Color(0, 0, 0, 1)
	return sprite

func _process(delta: float) -> void:
	_update_beat_sprites(delta)

func _update_beat_sprites(delta: float) -> void:
	var beats_amount = GameState.total_beats
	var current_beat = GameState.current_beat

	for ring in range(min(4, beat_sprites.size())):
		for beat in range(min(beats_amount, beat_sprites[ring].size())):
			var sprite = beat_sprites[ring][beat] as Sprite2D
			var active = GameState.get_beat(ring, beat)

			if ring < filled_beat_textures.size() and ring < outline_beat_textures.size():
				sprite.texture = filled_beat_textures[ring] if active else outline_beat_textures[ring]

			var color = Color(1, 1, 1, 1)
			if beat == current_beat and active:
				color = color.lightened(0.75)
			sprite.modulate = color

			var scale_factor = _scale_factor_for_beats_amount(beats_amount)
			if sprite.scale.x > scale_factor * _global_beat_sprite_scale_factor:
				sprite.scale -= Vector2.ONE * delta * 0.3

	# Update template sprites
	var show_template = false
	for ring in range(min(4, template_sprites.size())):
		for beat in range(min(beats_amount, template_sprites[ring].size())):
			var sprite = template_sprites[ring][beat] as Sprite2D
			var template_active = _get_template_active(ring, beat)
			sprite.modulate = Color(0, 0, 0, 0)
			if template_active and show_template:
				sprite.modulate = Color(0, 0, 0, 1)

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
	for ring in range(min(4, beat_sprites.size())):
		for beat in range(min(beats_amount, beat_sprites[ring].size())):
			var sprite = beat_sprites[ring][beat] as Sprite2D
			var scale_factor = _scale_factor_for_beats_amount(beats_amount)
			sprite.scale = Vector2.ONE * scale_factor * _global_beat_sprite_scale_factor
