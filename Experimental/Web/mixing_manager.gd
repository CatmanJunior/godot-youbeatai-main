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

# Mic buttons
@export var mic_button_location: Node2D
@export var mic_buttons: Array[Node2D] = []

# Curves for visual feedback
@export var synth_mixing_line_scale_curve: Curve
@export var synth_mixing_line_color_curve: Curve

# Mixing state
var weights: Vector3 = Vector3.ZERO
var outer_triangle_size: float = 60.0
var chaos_pad_mode: ChaosPadMode = ChaosPadMode.SAMPLE_MIXING

# Sample mixing
var samples_mixing_knob_positions: Array = [] # Array of Array[Vector2]
var samples_mixing_knob_positions_clipboard: Array[Vector2] = []
var samples_mixing_active_ring: int = 0

# Synth mixing
var synth_mixing_knob_positions: Array = [] # Array of Array[Vector2]
var synth_mixing_knob_positions_clipboard: Array[Vector2] = []
var synth_mixing_active_synth: int = 0

# Song mixing
var song_mixing_knob_position: Vector2

var current_layer_index: int = 0
var colors: Array[Color] = []

func _ready():
	# Connect to EventBus so other scripts don't need a direct reference
	EventBus.ring_selected.connect(samples_mixing_change_ring)
	EventBus.synth_selected.connect(synth_mixing_change_synth)
	EventBus.mixing_weights_changed.connect(on_update_mixing)
	EventBus.layer_changed.connect(_on_layer_changed)
	EventBus.layer_added.connect(_on_layer_added)
	EventBus.layer_removed.connect(_on_layer_removed)
	
	_on_ready_mixing()

func _on_layer_changed(layer_index: int, _new_layer_beats: Array):
	"""Store current knob, switch layer, retrieve new knob"""
	store_active_knob(chaos_pad_mode)
	
	current_layer_index = layer_index
	
	# Retrieve knob position for new layer
	retrieve_active_knob(chaos_pad_mode)

func _on_layer_added(_layer_index: int, _emoji: String):
	"""Insert default knob positions for a new layer"""
	samples_mixing_knob_positions.insert(_layer_index, range(4).map(get_default_knob_position))
	synth_mixing_knob_positions.insert(_layer_index, range(2).map(get_default_knob_position))

func _on_layer_removed(layer_index: int):
	"""Remove knob positions when a layer is deleted"""
	if layer_index < samples_mixing_knob_positions.size():
		samples_mixing_knob_positions.remove_at(layer_index)
	if layer_index < synth_mixing_knob_positions.size():
		synth_mixing_knob_positions.remove_at(layer_index)

func _prepare_clipboard():
	samples_mixing_knob_positions_clipboard = range(4).map(get_default_knob_position)
	synth_mixing_knob_positions_clipboard =  range(2).map(get_default_knob_position)



func _on_ready_mixing():
	_prepare_clipboard()

	song_mixing_knob_position = chaos_pad_triangle_sprite.global_position if chaos_pad_triangle_sprite else Vector2.ZERO
	
	_change_ring(chaos_pad_mode, 0)

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
		samples_mixing_store_active_knob()
	elif mode == ChaosPadMode.SYNTH_MIXING:
		synth_mixing_store_active_knob()
	elif mode == ChaosPadMode.SONG_MIXING:
		song_mixing_store_active_knob()

func samples_mixing_copy_knobs_for_layer():
	samples_mixing_knob_positions_clipboard = samples_mixing_knob_positions[current_layer_index].duplicate()

func samples_mixing_paste_knobs_for_layer():
	samples_mixing_knob_positions[current_layer_index] = samples_mixing_knob_positions_clipboard.duplicate()
	knob.global_position = samples_mixing_knob_positions_clipboard[samples_mixing_active_ring]

func samples_mixing_store_active_knob():
	if current_layer_index < samples_mixing_knob_positions.size() and knob:
		if samples_mixing_active_ring < samples_mixing_knob_positions[current_layer_index].size():
			samples_mixing_knob_positions[current_layer_index][samples_mixing_active_ring] = knob.global_position


#TODO Fix this
func samples_mixing_re_apply_remembered_volumes():
	"""Re-apply remembered mixing volumes for all rings"""
	if current_layer_index >= samples_mixing_knob_positions.size():
		return
	
	# for i in range(4):
	# 	if i < samples_mixing_knob_positions[current_layer_index].size():
			# var result = get_weights_for_position(samples_mixing_knob_positions[current_layer_index][i])
			# samples_mixing_update_volumes_for_ring(i, result.master_volume, result.weights)

func samples_mixing_change_ring(new_ring: int):
	# Save knob position
	store_active_knob(chaos_pad_mode)
	
	# Switch ring
	samples_mixing_active_ring = new_ring
	
	# Retrieve knob position
	retrieve_active_knob(chaos_pad_mode)
	
	# Set chaos pad color
	samples_mixing_start_triangle_color_change(0.2)
	
	# Update icons
	if main_icon and new_ring < main_icons.size():
		main_icon.texture = main_icons[new_ring]
	if alt_icon and new_ring < alt_icons.size():
		alt_icon.texture = alt_icons[new_ring]
	
	# Set mic button location
	for i in range(mic_buttons.size()):
		mic_buttons[i].global_position = Vector2(-500, 500)
	if new_ring < mic_buttons.size() and mic_button_location:
		mic_buttons[new_ring].global_position = mic_button_location.global_position
	
	# Set chaos pad mode
	chaos_pad_mode = ChaosPadMode.SAMPLE_MIXING

func samples_mixing_start_triangle_color_change(duration: float):
	if not chaos_pad_triangle_sprite or samples_mixing_active_ring >= colors.size():
		return
	
	var tween = create_tween()
	tween.tween_property(chaos_pad_triangle_sprite, "self_modulate", colors[samples_mixing_active_ring], duration)

func samples_mixing_update_volumes(master_volume: float, given_weights: Vector3):
	print("Updating volumes for ring %s with master volume %s and weights %s" % [samples_mixing_active_ring, master_volume, given_weights])
	var ring = samples_mixing_active_ring
	var weights_to_use = given_weights if given_weights != Vector3.ZERO else weights

	# Calculate individual volumes for main, alt, and rec based on weights and master volume
	var new_volume = weights_to_use * master_volume

	
	EventBus.set_ring_volume_requested.emit(ring, new_volume) 

# SYNTH MIXING =============================================================

func synth_mixing_copy_knobs_for_layer():
	if current_layer_index < synth_mixing_knob_positions.size():
		synth_mixing_knob_positions_clipboard = synth_mixing_knob_positions[current_layer_index].duplicate()

func synth_mixing_paste_knobs_for_layer():
	synth_mixing_knob_positions[current_layer_index] = synth_mixing_knob_positions_clipboard.duplicate()
	knob.global_position = synth_mixing_knob_positions_clipboard[synth_mixing_active_synth]

func synth_mixing_store_active_knob():
	if synth_mixing_active_synth < synth_mixing_knob_positions[current_layer_index].size():
		synth_mixing_knob_positions[current_layer_index][synth_mixing_active_synth] = knob.global_position

func synth_mixing_retrieve_active_knob():
	knob.global_position = synth_mixing_knob_positions[current_layer_index][synth_mixing_active_synth]

func samples_mixing_retrieve_active_knob():
	knob.global_position = samples_mixing_knob_positions[current_layer_index][samples_mixing_active_ring]

func retrieve_active_knob(mode: ChaosPadMode):
	if mode == ChaosPadMode.SAMPLE_MIXING:
		samples_mixing_retrieve_active_knob()
	elif mode == ChaosPadMode.SYNTH_MIXING:
		synth_mixing_retrieve_active_knob()
	elif mode == ChaosPadMode.SONG_MIXING:
		song_mixing_retrieve_active_knob()


#TODO Fix this
func synth_mixing_re_apply_remembered_volumes():
	"""Re-apply remembered mixing volumes for both synths"""
	if current_layer_index >= synth_mixing_knob_positions.size():
		return
	
	# for i in range(2):
	# 	if i < synth_mixing_knob_positions[current_layer_index].size():
	# 		var result = get_weights_for_position(synth_mixing_knob_positions[current_layer_index][i])
	# 		synth_mixing_update_volumes_for_synth(i, result.master_volume, result.weights)

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
	
	# Set mic button location
	for i in range(mic_buttons.size()):
		mic_buttons[i].global_position = Vector2(-500, 500)
	var mic_index = 4 + synth
	if mic_index < mic_buttons.size() and mic_button_location:
		mic_buttons[mic_index].global_position = mic_button_location.global_position
	
	# Set chaos pad mode
	chaos_pad_mode = ChaosPadMode.SYNTH_MIXING

func synth_mixing_start_triangle_color_change(duration: float):
	if not chaos_pad_triangle_sprite or synth_mixing_active_synth + 4 >= colors.size():
		return
	
	var color_index = 4 + synth_mixing_active_synth
	var tween = create_tween()
	tween.tween_property(chaos_pad_triangle_sprite, "self_modulate", colors[color_index], duration)

func synth_mixing_update_volumes_for_synth(synth: int, master_volume: float, given_weights: Vector3 = Vector3.ZERO):
	var weights_to_use = given_weights if given_weights != Vector3.ZERO else weights
	
	if synth == 0:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("GreenVoice"), linear_to_db(weights_to_use.y * master_volume))
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Green"), linear_to_db(weights_to_use.z * master_volume))
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Green_alt"), linear_to_db(weights_to_use.x * master_volume))
	elif synth == 1:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("PurpleVoice"), linear_to_db(weights_to_use.y * master_volume))
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Purple"), linear_to_db(weights_to_use.z * master_volume))
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Purple_alt"), linear_to_db(weights_to_use.x * master_volume))

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
	
	# Set mic button location
	for i in range(mic_buttons.size()):
		mic_buttons[i].global_position = Vector2(-500, 500)
	if mic_buttons.size() > 6 and mic_button_location:
		mic_buttons[6].global_position = mic_button_location.global_position
	
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

func get_default_knob_position() -> Array[Vector2]:
	var centered_pos = chaos_pad_triangle_sprite.global_position if chaos_pad_triangle_sprite else Vector2.ZERO
	return centered_pos

func on_update_mixing(master_volume: float, mixingWeights: Vector3):
	"""Called every frame to update mixing state"""
	if not knob:
		return
		
	if chaos_pad_mode == ChaosPadMode.SAMPLE_MIXING:
		samples_mixing_update_volumes(master_volume, mixingWeights)
	elif chaos_pad_mode == ChaosPadMode.SYNTH_MIXING:
		synth_mixing_update_volumes_for_synth(synth_mixing_active_synth, master_volume, mixingWeights)
	elif chaos_pad_mode == ChaosPadMode.SONG_MIXING:
		song_mixing_update_volumes_for_song(master_volume)
