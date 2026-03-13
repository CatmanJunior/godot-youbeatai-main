extends Node

# Private state – sprite scale factors
var _beat_scale_32: float = 1.0
var _beat_scale_16: float = 1.6
var _beat_scale_8: float = 1.6
var _global_beat_sprite_scale_factor: float = 0.28
var _original_instrument_button_scales: Array[float] = []

# Called by ui_manager._ready() after colors are initialised
func initialize(ui: Node) -> void:
	_store_instrument_button_scales(ui.instrument_buttons)
	_initialize_sprite_positions(ui)

func _store_instrument_button_scales(instrument_buttons: Array) -> void:
	_original_instrument_button_scales = []
	for btn in instrument_buttons:
		_original_instrument_button_scales.append(btn.scale.x)

func _initialize_sprite_positions(ui: Node) -> void:
	var beats_amount = GameState.beats_amount

	ui.beat_sprites = []
	for ring in range(4):
		ui.beat_sprites.append([])
		for beat in range(beats_amount):
			var sprite = _create_sprite(beat, ring, beats_amount, ui)
			ui.bear_ring_pivot_point.add_child(sprite)
			ui.beat_sprites[ring].append(sprite)

	ui.template_sprites = []
	for ring in range(4):
		ui.template_sprites.append([])
		for beat in range(beats_amount):
			var sprite = _create_template_sprite(beat, ring, beats_amount, ui)
			ui.bear_ring_pivot_point.add_child(sprite)
			ui.template_sprites[ring].append(sprite)

	var colors = ui.colors
	ui.activate_green_chaos_button.self_modulate = colors[4]
	ui.activate_purple_chaos_button.self_modulate = colors[5]

	var green_back = ui.activate_green_chaos_button.find_child("BackSprite") as Sprite2D
	green_back.self_modulate = colors[4]

	var purple_back = ui.activate_purple_chaos_button.find_child("BackSprite") as Sprite2D
	purple_back.self_modulate = colors[5]

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

func _create_sprite(beat: int, ring: int, beats_amount: int, ui: Node) -> Sprite2D:
	var sprite = ui.sprite_prefab.instantiate() as Sprite2D
	sprite.position = _sprite_position(beat, ring, beats_amount)
	sprite.rotation = _sprite_rotation(beat, ring, beats_amount)
	sprite.set_sprite_index(beat)
	sprite.set_ring(ring)

	var scale_factor = _scale_factor_for_beats_amount(beats_amount)
	sprite.scale = Vector2.ONE * scale_factor * _global_beat_sprite_scale_factor

	if ring < ui.filled_beat_textures.size():
		sprite.texture = ui.filled_beat_textures[ring]

	return sprite

func _create_template_sprite(beat: int, ring: int, beats_amount: int, ui: Node) -> Sprite2D:
	var sprite = Sprite2D.new()
	sprite.position = _sprite_position(beat, ring, beats_amount)
	sprite.rotation = _sprite_rotation(beat, ring, beats_amount)
	sprite.texture = ui.dot_beat_texture
	sprite.modulate = Color(0, 0, 0, 1)
	return sprite

func update(delta: float) -> void:
	_update_beat_sprites(delta, get_parent())

func _update_beat_sprites(delta: float, ui: Node) -> void:
	# Animate instrument button scale back to its default
	for i in range(ui.instrument_buttons.size()):
		if i < _original_instrument_button_scales.size():
			if ui.instrument_buttons[i].scale.x > _original_instrument_button_scales[i]:
				ui.instrument_buttons[i].scale -= Vector2.ONE * delta * 2

	var beats_amount = GameState.beats_amount
	var current_beat = GameState.current_beat

	for ring in range(min(4, ui.beat_sprites.size())):
		for beat in range(min(beats_amount, ui.beat_sprites[ring].size())):
			var sprite = ui.beat_sprites[ring][beat] as Sprite2D
			var active = GameState.get_beat(ring, beat)

			if ring < ui.filled_beat_textures.size() and ring < ui.outline_beat_textures.size():
				sprite.texture = ui.filled_beat_textures[ring] if active else ui.outline_beat_textures[ring]

			var color = Color(1, 1, 1, 1)
			if beat == current_beat and active:
				color = color.lightened(0.75)
			sprite.modulate = color

			var scale_factor = _scale_factor_for_beats_amount(beats_amount)
			if sprite.scale.x > scale_factor * _global_beat_sprite_scale_factor:
				sprite.scale -= Vector2.ONE * delta * 0.3

	# Update template sprites
	var show_template = false
	for ring in range(min(4, ui.template_sprites.size())):
		for beat in range(min(beats_amount, ui.template_sprites[ring].size())):
			var sprite = ui.template_sprites[ring][beat] as Sprite2D
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
func reset_scales() -> void:
	var ui = get_parent()
	var beats_amount = GameState.beats_amount
	for ring in range(min(4, ui.beat_sprites.size())):
		for beat in range(min(beats_amount, ui.beat_sprites[ring].size())):
			var sprite = ui.beat_sprites[ring][beat] as Sprite2D
			var scale_factor = _scale_factor_for_beats_amount(beats_amount)
			sprite.scale = Vector2.ONE * scale_factor * _global_beat_sprite_scale_factor
