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
var active_track: int = 0

# Song mixing (global, not per-layer)
var song_mixing_knob_position: Vector2

var colors: Array[Color] = []

var default_knob_position: Vector2

# Reference to layer manager for SectionData access
var layer_manager: Node

func _ready():
	# TODO: Do this in the layer_data instead
	default_knob_position = get_default_knob_position()

	# Connect to EventBus so other scripts don't need a direct reference
	EventBus.track_selected.connect(_on_track_selected)
	EventBus.mixing_weights_changed.connect(on_update_mixing)
	EventBus.section_changed.connect(_on_section_changed)
	
	_on_ready_mixing()

func _on_track_selected(track: int):
	_change_active_track(track)

func _on_section_changed(old_section_data: SectionData, _new_section_data: SectionData):
	"""Store current knob, switch section, retrieve new knob"""
	if old_section_data != null:
		_store_active_knob(chaos_pad_mode, old_section_data)
	
	# Retrieve knob position for new layer
	var pos = _retrieve_active_knob(chaos_pad_mode)
	knob.global_position = pos

	_apply_stored_volumes(old_section_data)

func _on_ready_mixing():
	song_mixing_knob_position = chaos_pad_triangle_sprite.global_position

	# _change_active_track(chaos_pad_mode, 0)

func _change_active_track(mode: ChaosPadMode, new_index: int = 0):
	if mode != ChaosPadMode.SONG_MIXING:
		mixing_change_track(new_index)
	else:
		song_mixing_change_to_song_mixer()

func _store_active_knob(mode: ChaosPadMode, new_section_data: SectionData):
	if mode == ChaosPadMode.SAMPLE_MIXING or mode == ChaosPadMode.SYNTH_MIXING:
		new_section_data.set_track_knob_position(active_track, knob.global_position)
	elif mode == ChaosPadMode.SONG_MIXING:
		song_mixing_store_active_knob()

func _retrieve_active_knob(mode: ChaosPadMode) -> Vector2:
	var pos: Vector2
	
	if mode == ChaosPadMode.SAMPLE_MIXING or mode == ChaosPadMode.SYNTH_MIXING:
		pos = GameState.current_section.get_track_knob_position(active_track)

	elif mode == ChaosPadMode.SONG_MIXING:
		pos = song_mixing_retrieve_active_knob()
	if pos == Vector2.ZERO:
		pos = default_knob_position
	return pos

func _apply_stored_volumes(old_section_data: SectionData):
	"""Re-apply remembered mixing volumes for all tracks"""
	if old_section_data == null:
		return
	for track_index in range(SectionData.TRACKS_PER_SECTION):
		var old_track = old_section_data.tracks[track_index]
		GameState.current_section.tracks[track_index].master_volume = old_track.master_volume
		GameState.current_section.tracks[track_index].weights = old_track.weights
		
func mixing_change_track(new_track_index: int):
	_store_active_knob(chaos_pad_mode, GameState.current_section)

	active_track = new_track_index
	
	var pos = _retrieve_active_knob(chaos_pad_mode)
	
	knob.global_position = pos

	track_mixing_start_triangle_color_change(0.2)
	
	# Update icons
	if main_icon and new_track_index < main_icons.size():
		main_icon.texture = main_icons[new_track_index]
	if alt_icon and new_track_index < alt_icons.size():
		alt_icon.texture = alt_icons[new_track_index]
	
	# Set chaos pad mode
	if new_track_index < SectionData.SAMPLE_TRACKS_PER_SECTION:
		chaos_pad_mode = ChaosPadMode.SAMPLE_MIXING
	else:
		chaos_pad_mode = ChaosPadMode.SYNTH_MIXING

func track_mixing_update_volumes(track_index: int, master_volume: float, given_weights: Vector3):
	"""Generalized volume update for any track type, currently unused but could be helpful if we add more track types"""
	print("Updating volumes for track %s with master volume %s and weights %s" % [track_index, master_volume, given_weights])

	var weights_to_use = given_weights if given_weights != Vector3.ZERO else weights

	var new_volume = weights_to_use * master_volume

	# For synths, also update the bus volume
	EventBus.set_track_volume_requested.emit(track_index, new_volume)

	#TODO: MOVE THIS TO AUDIO_PLAYER_MANAGER AND MAKE IT PER-TRACK INSTEAD OF PER-BUS
	# AudioServer.set_bus_volume_db(AudioServer.get_bus_index(synth_bus), linear_to_db(weights_to_use.z * master_volume))

func track_mixing_apply_stored_volumes():
	"""Re-apply remembered mixing volumes for both synths"""
	if GameState.current_section == null:
		return
	
	for i in range(SectionData.SYNTH_TRACKS_PER_SECTION):
		var weights_to_use = GameState.current_section.synth_tracks[i].weights if GameState.current_section.synth_tracks[i].weights != Vector3.ZERO else weights
		var master_volume = GameState.current_section.synth_tracks[i].master_volume
		track_mixing_update_volumes(i, master_volume, weights_to_use)


func track_mixing_start_triangle_color_change(duration: float):
	var color_index = active_track
	var tween = create_tween()
	tween.tween_property(chaos_pad_triangle_sprite, "self_modulate", colors[color_index], duration)


# SONG MIXING ==============================================================

func song_mixing_store_active_knob():
	song_mixing_knob_position = knob.global_position

func song_mixing_retrieve_active_knob():
	knob.global_position = song_mixing_knob_position

func song_mixing_change_to_song_mixer():
	# Save knob position
	_store_active_knob(chaos_pad_mode, GameState.current_section)

	# Retrieve knob position
	_retrieve_active_knob(ChaosPadMode.SONG_MIXING)
	
	# Set chaos pad color
	track_mixing_start_triangle_color_change(0.2)
	
	# Update icons
	if main_icon and main_icon_song:
		main_icon.texture = main_icon_song
	if alt_icon and alt_icon_song:
		alt_icon.texture = alt_icon_song
	
	# Set chaos pad mode
	chaos_pad_mode = ChaosPadMode.SONG_MIXING

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
		
	if chaos_pad_mode != ChaosPadMode.SONG_MIXING:
		track_mixing_update_volumes(active_track, master_volume, mixingWeights)
	else:
		song_mixing_update_volumes_for_song(master_volume)
