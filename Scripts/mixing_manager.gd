extends Node

enum ChaosPadMode {
	SAMPLE_MIXING,
	SYNTH_MIXING,
	SONG_MIXING
}

# Chaos pad controls
@export var knob: Node2D
@export var chaos_pad_triangle_sprite: Sprite2D

# Icons
@export var main_icons: Array[Texture2D] = [] # 4 for rings
@export var alt_icons: Array[Texture2D] = [] # 4 for rings
@export var main_icon_synths: Array[Texture2D] = [] # 2 for synths
@export var alt_icon_synths: Array[Texture2D] = [] # 2 for synths
@export var main_icon_song: Texture2D
@export var alt_icon_song: Texture2D

@export var main_icon: Sprite2D
@export var alt_icon: Sprite2D

# Curves for visual feedback
@export var synth_mixing_line_scale_curve: Curve
@export var synth_mixing_line_color_curve: Curve

# Mixing state
var weights: Vector3 = Vector3.ZERO
var outer_triangle_size: float = 60.0
var chaos_pad_mode: ChaosPadMode = ChaosPadMode.SAMPLE_MIXING

# Active ring/synth selection
var samples_mixing_active_ring: int = 0
var synth_mixing_active_synth: int = 0

# Song mixing (global, not per-layer)
var song_mixing_knob_position: Vector2

var colors: Array[Color] = []

var default_knob_position: Vector2

# Reference to layer manager for LayerData access
var layer_manager: Node

var current_layer: LayerData

func _ready():
	# TODO: Do this in the layer_data instead
	default_knob_position = get_default_knob_position()

	# Connect to EventBus so other scripts don't need a direct reference
	EventBus.ring_selected.connect(samples_mixing_change_ring)
	EventBus.synth_selected.connect(synth_mixing_change_synth)
	EventBus.mixing_weights_changed.connect(on_update_mixing)
	EventBus.layer_changed.connect(_on_layer_changed)
	
	_on_ready_mixing()

func _on_layer_changed(layer_data: LayerData):
	"""Store current knob, switch layer, retrieve new knob"""
	store_active_knob(chaos_pad_mode)
	
	current_layer = layer_data
	
	# Retrieve knob position for new layer
	var pos = retrieve_active_knob(chaos_pad_mode)
	knob.global_position = pos
	
	_apply_stored_volumes()

func _on_ready_mixing():
	song_mixing_knob_position = chaos_pad_triangle_sprite.global_position

	# _change_ring(chaos_pad_mode, 0)

func _change_ring(mode: ChaosPadMode, new_index: int = 0):
	if mode == ChaosPadMode.SAMPLE_MIXING:
		samples_mixing_change_ring(new_index)
	elif mode == ChaosPadMode.SYNTH_MIXING:
		synth_mixing_change_synth(new_index)
	elif mode == ChaosPadMode.SONG_MIXING:
		song_mixing_change_to_song_mixer()

# SAMPLE MIXING ============================================================
func store_active_knob(mode: ChaosPadMode):
	if mode == ChaosPadMode.SAMPLE_MIXING:
		current_layer.set_sample_knob_position(samples_mixing_active_ring, knob.global_position)
	elif mode == ChaosPadMode.SYNTH_MIXING:
		current_layer.set_synth_knob_position(synth_mixing_active_synth, knob.global_position)
	elif mode == ChaosPadMode.SONG_MIXING:
		song_mixing_store_active_knob()

func retrieve_active_knob(mode: ChaosPadMode) -> Vector2:
	var pos: Vector2
	if mode == ChaosPadMode.SAMPLE_MIXING:
		pos = current_layer.get_sample_knob_position(samples_mixing_active_ring)
	elif mode == ChaosPadMode.SYNTH_MIXING:
		pos = current_layer.get_synth_knob_position(synth_mixing_active_synth)
	elif mode == ChaosPadMode.SONG_MIXING:
		pos = song_mixing_retrieve_active_knob()
	if pos == Vector2.ZERO:
		pos = default_knob_position
	return pos

func _apply_stored_volumes():
	"""Re-apply remembered mixing volumes for all rings"""
	if current_layer == null:
		return
	
	for i in range(current_layer.RINGS_PER_LAYER):
		samples_mixing_update_volumes(i, current_layer.rings[i].master_volume, current_layer.rings[i].weights)

	for i in range(current_layer.SYNTHS_PER_LAYER):
		synth_mixing_update_volumes(i, current_layer.synths[i].master_volume, current_layer.synths[i].weights)

		
func samples_mixing_change_ring(new_ring: int):
	# Save knob position
	store_active_knob(chaos_pad_mode)
	
	# Switch ring
	samples_mixing_active_ring = new_ring
	
	# Retrieve knob position
	var pos = retrieve_active_knob(chaos_pad_mode)
	
	knob.global_position = pos

	# Set chaos pad color
	samples_mixing_start_triangle_color_change(0.2)
	
	# Update icons
	if main_icon and new_ring < main_icons.size():
		main_icon.texture = main_icons[new_ring]
	if alt_icon and new_ring < alt_icons.size():
		alt_icon.texture = alt_icons[new_ring]
	
	# Set chaos pad mode
	chaos_pad_mode = ChaosPadMode.SAMPLE_MIXING

func samples_mixing_start_triangle_color_change(duration: float):
	if not chaos_pad_triangle_sprite or samples_mixing_active_ring >= colors.size():
		return
	
	var tween = create_tween()
	tween.tween_property(chaos_pad_triangle_sprite, "self_modulate", colors[samples_mixing_active_ring], duration)

func samples_mixing_update_volumes(ring: int, master_volume: float, given_weights: Vector3):
	print("Updating volumes for ring %s with master volume %s and weights %s" % [ring, master_volume, given_weights])

	var weights_to_use = given_weights if given_weights != Vector3.ZERO else weights

	# Calculate individual volumes for main, alt, and rec based on weights and master volume
	var new_volume = weights_to_use * master_volume

	
	EventBus.set_ring_volume_requested.emit(ring, new_volume)

# SYNTH MIXING =============================================================
func synth_mixing_apply_stored_volumes():
	"""Re-apply remembered mixing volumes for both synths"""
	if current_layer == null:
		return
	
	for i in range(current_layer.SYNTHS_PER_LAYER):
		var weights_to_use = current_layer.synths[i].weights if current_layer.synths[i].weights != Vector3.ZERO else weights
		var master_volume = current_layer.synths[i].master_volume
		synth_mixing_update_volumes(i, master_volume, weights_to_use)

func synth_mixing_update_volumes(synth: int, master_volume: float, given_weights: Vector3):
	print("Updating volumes for synth %s with master volume %s and weights %s" % [synth, master_volume, given_weights])
	#TODO this needs the be moved to the audio stuff not here, abstract the shit out of it
	if synth == 0:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("GreenVoice"), linear_to_db(given_weights.y * master_volume))
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Green"), linear_to_db(given_weights.z * master_volume))
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Green_alt"), linear_to_db(given_weights.x * master_volume))
	elif synth == 1:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("PurpleVoice"), linear_to_db(given_weights.y * master_volume))
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Purple"), linear_to_db(given_weights.z * master_volume))
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Purple_alt"), linear_to_db(given_weights.x * master_volume))

func synth_mixing_change_synth(synth: int):
	# Save knob position
	store_active_knob(chaos_pad_mode)
	
	# Switch synth
	synth_mixing_active_synth = synth
	
	# Retrieve knob position
	retrieve_active_knob(ChaosPadMode.SYNTH_MIXING)
	
	# Set chaos pad color
	synth_mixing_start_triangle_color_change(0.2)
	
	# Update icons
	if main_icon and synth < main_icon_synths.size():
		main_icon.texture = main_icon_synths[synth]
	if alt_icon and synth < alt_icon_synths.size():
		alt_icon.texture = alt_icon_synths[synth]
	
	# Set chaos pad mode
	chaos_pad_mode = ChaosPadMode.SYNTH_MIXING

func synth_mixing_start_triangle_color_change(duration: float):
	if not chaos_pad_triangle_sprite or synth_mixing_active_synth + 4 >= colors.size():
		return
	
	var color_index = 4 + synth_mixing_active_synth
	var tween = create_tween()
	tween.tween_property(chaos_pad_triangle_sprite, "self_modulate", colors[color_index], duration)


# SONG MIXING ==============================================================

func song_mixing_store_active_knob():
	song_mixing_knob_position = knob.global_position

func song_mixing_retrieve_active_knob():
	knob.global_position = song_mixing_knob_position

func song_mixing_change_to_song_mixer():
	# Save knob position
	store_active_knob(chaos_pad_mode)

	# Retrieve knob position
	retrieve_active_knob(ChaosPadMode.SONG_MIXING)
	
	# Set chaos pad color
	song_mixing_start_triangle_color_change(0.2)
	
	# Update icons
	if main_icon and main_icon_song:
		main_icon.texture = main_icon_song
	if alt_icon and alt_icon_song:
		alt_icon.texture = alt_icon_song
	
	# Set chaos pad mode
	chaos_pad_mode = ChaosPadMode.SONG_MIXING

func song_mixing_start_triangle_color_change(duration: float):
	if not chaos_pad_triangle_sprite or colors.size() <= 6:
		return
	
	var tween = create_tween()
	tween.tween_property(chaos_pad_triangle_sprite, "self_modulate", colors[6], duration)

func song_mixing_update_volumes_for_song(master_volume: float):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SongVoice"), linear_to_db((weights.y + weights.x) * master_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SongSynth"), linear_to_db(weights.z * master_volume))

# UTILITY ==================================================================

func get_default_knob_position() -> Vector2:
	var centered_pos = chaos_pad_triangle_sprite.global_position if chaos_pad_triangle_sprite else Vector2.ZERO
	return centered_pos

func on_update_mixing(master_volume: float, mixingWeights: Vector3):
	"""Called every frame to update mixing state"""
	if not knob:
		return
		
	if chaos_pad_mode == ChaosPadMode.SAMPLE_MIXING:
		samples_mixing_update_volumes(samples_mixing_active_ring, master_volume, mixingWeights)
	elif chaos_pad_mode == ChaosPadMode.SYNTH_MIXING:
		synth_mixing_update_volumes(synth_mixing_active_synth, master_volume, mixingWeights)
	elif chaos_pad_mode == ChaosPadMode.SONG_MIXING:
		song_mixing_update_volumes_for_song(master_volume)
