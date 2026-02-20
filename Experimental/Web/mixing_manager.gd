extends Node

enum ChaosPadMode {
	SAMPLE_MIXING,
	SYNTH_MIXING,
	SONG_MIXING
}

# Chaos pad controls
@export var corners: Array[Node2D] = []  # left, top, right
@export var knob: Node2D
@export var chaos_pad_triangle_sprite: Sprite2D

# Icons
@export var main_icons: Array[Texture2D] = []  # 4 for rings
@export var alt_icons: Array[Texture2D] = []  # 4 for rings
@export var main_icon_synths: Array[Texture2D] = []  # 2 for synths
@export var alt_icon_synths: Array[Texture2D] = []  # 2 for synths
@export var main_icon_song: Texture2D
@export var alt_icon_song: Texture2D

@export var main_icon: Sprite2D
@export var alt_icon: Sprite2D

# Mixing state
var weights: Vector3 = Vector3.ZERO
var outer_triangle_size: float = 60.0
var chaos_pad_mode: ChaosPadMode = ChaosPadMode.SAMPLE_MIXING

@export var mic_button_location: Node2D
@export var mic_buttons: Array[Node2D] = []

# Sample mixing
var samples_mixing_knob_positions: Array = []  # Array of Array[Vector2]
var samples_mixing_knob_positions_clipboard: Array[Vector2] = []
var samples_mixing_active_ring: int = 0

# Synth mixing
var synth_mixing_knob_positions: Array = []  # Array of Array[Vector2]
var synth_mixing_knob_positions_clipboard: Array[Vector2] = []
var synth_mixing_active_synth: int = 0

@export var synth_mixing_line_scale_curve: Curve
@export var synth_mixing_line_color_curve: Curve

# Song mixing
var song_mixing_knob_position: Vector2

# Reference to other managers
var current_layer_index: int = 0
var colors: Array[Color] = []

func _ready():
	on_ready_mixing()

func on_ready_mixing():
	samples_mixing_knob_positions_clipboard = get_standard_knob_positions_samples()
	synth_mixing_knob_positions_clipboard = get_standard_knob_positions_synth()
	song_mixing_knob_position = chaos_pad_triangle_sprite.global_position if chaos_pad_triangle_sprite else Vector2.ZERO
	
	if chaos_pad_mode == ChaosPadMode.SAMPLE_MIXING:
		samples_mixing_change_ring(0)
	elif chaos_pad_mode == ChaosPadMode.SYNTH_MIXING:
		synth_mixing_change_synth(0)
	elif chaos_pad_mode == ChaosPadMode.SONG_MIXING:
		song_mixing_change_to_song_mixer()

# SAMPLE MIXING ============================================================

func samples_mixing_copy_knobs_for_layer():
	if current_layer_index < samples_mixing_knob_positions.size():
		samples_mixing_knob_positions_clipboard = samples_mixing_knob_positions[current_layer_index].duplicate()

func samples_mixing_paste_knobs_for_layer():
	if current_layer_index < samples_mixing_knob_positions.size():
		samples_mixing_knob_positions[current_layer_index] = samples_mixing_knob_positions_clipboard.duplicate()
		if knob and samples_mixing_active_ring < samples_mixing_knob_positions_clipboard.size():
			knob.global_position = samples_mixing_knob_positions_clipboard[samples_mixing_active_ring]

func samples_mixing_store_active_knob():
	if current_layer_index < samples_mixing_knob_positions.size() and knob:
		if samples_mixing_active_ring < samples_mixing_knob_positions[current_layer_index].size():
			samples_mixing_knob_positions[current_layer_index][samples_mixing_active_ring] = knob.global_position

func samples_mixing_retrieve_active_knob():
	if current_layer_index < samples_mixing_knob_positions.size() and knob:
		if samples_mixing_active_ring < samples_mixing_knob_positions[current_layer_index].size():
			knob.global_position = samples_mixing_knob_positions[current_layer_index][samples_mixing_active_ring]

func samples_mixing_re_apply_remembered_volumes():
	"""Re-apply remembered mixing volumes for all rings"""
	if current_layer_index >= samples_mixing_knob_positions.size():
		return
	
	for i in range(4):
		if i < samples_mixing_knob_positions[current_layer_index].size():
			var result = get_weights_for_position(samples_mixing_knob_positions[current_layer_index][i])
			samples_mixing_update_volumes_for_ring(i, result.master_volume, result.weights)

func samples_mixing_change_ring(new_ring: int):
	# Save knob position
	if chaos_pad_mode == ChaosPadMode.SAMPLE_MIXING:
		samples_mixing_store_active_knob()
	elif chaos_pad_mode == ChaosPadMode.SYNTH_MIXING:
		synth_mixing_store_active_knob()
	elif chaos_pad_mode == ChaosPadMode.SONG_MIXING:
		song_mixing_store_active_knob()
	
	# Switch ring
	samples_mixing_active_ring = new_ring
	
	# Retrieve knob position
	samples_mixing_retrieve_active_knob()
	
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

func samples_mixing_update_volumes_for_ring(ring: int, master_volume: float, given_weights: Vector3 = Vector3.ZERO):
	var weights_to_use = given_weights if given_weights != Vector3.ZERO else weights
	
	var main_volume = weights_to_use.x * master_volume
	var rec_volume = weights_to_use.y * master_volume
	var alt_volume = weights_to_use.z * master_volume
	
	# Get the audio player manager to set volumes
	var audio_manager = get_node_or_null("../AudioPlayerManager")
	if audio_manager:
		for player_array in ["audio_players", "audio_players_alt", "audio_players_rec"]:
			if audio_manager.has(player_array) and ring < audio_manager[player_array].size():
				var volume = main_volume if player_array == "audio_players" else (alt_volume if player_array == "audio_players_alt" else rec_volume)
				audio_manager[player_array][ring].volume_db = linear_to_db(volume)

# SYNTH MIXING =============================================================

func synth_mixing_copy_knobs_for_layer():
	if current_layer_index < synth_mixing_knob_positions.size():
		synth_mixing_knob_positions_clipboard = synth_mixing_knob_positions[current_layer_index].duplicate()

func synth_mixing_paste_knobs_for_layer():
	if current_layer_index < synth_mixing_knob_positions.size():
		synth_mixing_knob_positions[current_layer_index] = synth_mixing_knob_positions_clipboard.duplicate()
		if knob and synth_mixing_active_synth < synth_mixing_knob_positions_clipboard.size():
			knob.global_position = synth_mixing_knob_positions_clipboard[synth_mixing_active_synth]

func synth_mixing_store_active_knob():
	if current_layer_index < synth_mixing_knob_positions.size() and knob:
		if synth_mixing_active_synth < synth_mixing_knob_positions[current_layer_index].size():
			synth_mixing_knob_positions[current_layer_index][synth_mixing_active_synth] = knob.global_position

func synth_mixing_retrieve_active_knob():
	if current_layer_index < synth_mixing_knob_positions.size() and knob:
		if synth_mixing_active_synth < synth_mixing_knob_positions[current_layer_index].size():
			knob.global_position = synth_mixing_knob_positions[current_layer_index][synth_mixing_active_synth]

func synth_mixing_re_apply_remembered_volumes():
	"""Re-apply remembered mixing volumes for both synths"""
	if current_layer_index >= synth_mixing_knob_positions.size():
		return
	
	for i in range(2):
		if i < synth_mixing_knob_positions[current_layer_index].size():
			var result = get_weights_for_position(synth_mixing_knob_positions[current_layer_index][i])
			synth_mixing_update_volumes_for_synth(i, result.master_volume, result.weights)

func synth_mixing_change_synth(synth: int):
	# Save knob position
	if chaos_pad_mode == ChaosPadMode.SAMPLE_MIXING:
		samples_mixing_store_active_knob()
	elif chaos_pad_mode == ChaosPadMode.SYNTH_MIXING:
		synth_mixing_store_active_knob()
	elif chaos_pad_mode == ChaosPadMode.SONG_MIXING:
		song_mixing_store_active_knob()
	
	# Switch synth
	synth_mixing_active_synth = synth
	
	# Retrieve knob position
	synth_mixing_retrieve_active_knob()
	
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
	if knob:
		song_mixing_knob_position = knob.global_position

func song_mixing_retrieve_active_knob():
	if knob:
		knob.global_position = song_mixing_knob_position

func song_mixing_change_to_song_mixer():
	# Save knob position
	if chaos_pad_mode == ChaosPadMode.SAMPLE_MIXING:
		samples_mixing_store_active_knob()
	elif chaos_pad_mode == ChaosPadMode.SYNTH_MIXING:
		synth_mixing_store_active_knob()
	elif chaos_pad_mode == ChaosPadMode.SONG_MIXING:
		song_mixing_store_active_knob()
	
	# Retrieve knob position
	song_mixing_retrieve_active_knob()
	
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

func get_standard_knob_positions_samples() -> Array[Vector2]:
	var centered_pos = chaos_pad_triangle_sprite.global_position if chaos_pad_triangle_sprite else Vector2.ZERO
	return [centered_pos, centered_pos, centered_pos, centered_pos]

func get_standard_knob_positions_synth() -> Array[Vector2]:
	var centered_pos = chaos_pad_triangle_sprite.global_position if chaos_pad_triangle_sprite else Vector2.ZERO
	return [centered_pos, centered_pos]

func get_weights_for_position(position: Vector2) -> Dictionary:
	"""Calculate weights based on knob position in triangle"""
	# Simplified version - calculate barycentric coordinates
	var master_volume = 1.0
	var calc_weights = Vector3(0.33, 0.33, 0.33)  # Default equal weights
	
	# TODO: Implement proper barycentric coordinate calculation
	# This would involve using the triangle corners to determine weights
	
	return {
		"master_volume": master_volume,
		"weights": calc_weights
	}

func on_update_mixing(delta: float):
	"""Called every frame to update mixing state"""
	if not knob:
		return
	
	var result = get_weights_for_position(knob.global_position)
	weights = result.weights
	var master_volume = result.master_volume
	
	if chaos_pad_mode == ChaosPadMode.SAMPLE_MIXING:
		samples_mixing_update_volumes_for_ring(samples_mixing_active_ring, master_volume)
	elif chaos_pad_mode == ChaosPadMode.SYNTH_MIXING:
		synth_mixing_update_volumes_for_synth(synth_mixing_active_synth, master_volume)
	elif chaos_pad_mode == ChaosPadMode.SONG_MIXING:
		song_mixing_update_volumes_for_song(master_volume)
