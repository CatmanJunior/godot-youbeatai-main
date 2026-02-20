extends Node

# Beat state storage (4 rings x beats_amount beats)
var beat_actives: Array = []

# Clap and stomp detection
var stomped: bool = false
var clapped: bool = false
var clapped_amount: int = 0
var clapped_on_beat_amount: int = 0
var stomped_amount: int = 0
var stomped_on_beat_amount: int = 0

# Progress bar value
var progress_bar_value: float = 0.0
var time_after_play: float = 0.0

# Settings
var metronome_sfx_enabled: bool = false
var add_beats_enabled: bool = false

# References
var current_beat: int = 0
var beats_amount: int = 16
var colors: Array[Color] = []

# Metronome
@export var metronome_sfx: AudioStream

# Signals
signal should_clap
signal should_stomp

# References to other managers
var audio_player_manager: Node
var particle_manager: Node
var layer_manager: Node
var microphone_capture: Node

func _ready():
	audio_player_manager = %AudioPlayerManager
	layer_manager = %LayerManager


	# Initialize beat_actives array [4 rings][beats_amount beats]
	for ring in range(4):
		var ring_beats = []
		for beat in range(beats_amount):
			ring_beats.append(false)
		beat_actives.append(ring_beats)

func check_if_clapping_or_stomping():
	"""Check microphone input for clapping or stomping"""
	if not microphone_capture:
		return
	
	var volume = microphone_capture.volume if microphone_capture.has("volume") else 0.0
	var frequency = microphone_capture.frequency if microphone_capture.has("frequency") else 0.0
	
	# Check for clap (high frequency)
	var is_clapping = microphone_capture.is_clapping if microphone_capture.has("is_clapping") else false
	if is_clapping or Input.is_key_pressed(KEY_N):
		if not clapped:
			on_clap()
			clapped = true
	
	# Check for stomp (low frequency)
	var is_stamping = microphone_capture.is_stamping if microphone_capture.has("is_stamping") else false
	if is_stamping or Input.is_key_pressed(KEY_M):
		if not stomped:
			on_stomp()
			stomped = true

func on_clap():
	"""Handle clap detection"""
	if time_after_play < 0.2:
		return
	
	var ring = 1
	var active = beat_actives[ring][current_beat] if ring < beat_actives.size() and current_beat < beat_actives[ring].size() else false
	
	if active:
		# Hit on beat - reward player
		progress_bar_value += 2.0
		if particle_manager:
			particle_manager.emit_progress_bar_particles()
			if ring < colors.size():
				particle_manager.emit_beat_particles(Vector2.ZERO, colors[ring])
		clapped_on_beat_amount += 1
	else:
		# Missed beat - penalize player
		progress_bar_value -= 1.0
	
	clapped_amount += 1
	
	# Add beat if enabled
	if add_beats_enabled:
		toggle_beat(ring, current_beat)

func on_stomp():
	"""Handle stomp detection"""
	if time_after_play < 0.2:
		return
	
	var ring = 0
	var active = beat_actives[ring][current_beat] if ring < beat_actives.size() and current_beat < beat_actives[ring].size() else false
	
	if active:
		# Hit on beat - reward player
		progress_bar_value += 2.0
		if particle_manager:
			particle_manager.emit_progress_bar_particles()
			if ring < colors.size():
				particle_manager.emit_beat_particles(Vector2.ZERO, colors[ring])
		stomped_on_beat_amount += 1
	else:
		# Missed beat - penalize player
		progress_bar_value -= 1.0
	
	stomped_amount += 1
	
	# Add beat if enabled
	if add_beats_enabled:
		toggle_beat(ring, current_beat)

func on_beat():
	"""Called when a beat occurs"""
	# Play metronome if enabled
	if metronome_sfx_enabled:
		var beats_per_quarter = beats_amount / 4
		if current_beat % beats_per_quarter == 0:
			play_metronome_sfx()
	
	# Play audio for active beats
	if audio_player_manager:
		for ring in range(4):
			if ring < beat_actives.size() and current_beat < beat_actives[ring].size():
				if beat_actives[ring][current_beat]:
					audio_player_manager.play_ring(ring, beat_actives)
	
	# Reset clap/stomp state
	clapped = false
	stomped = false
	
	# Update progress bar value
	if current_beat == 0:
		if progress_bar_value < 50.0:
			progress_bar_value += 2.0
		elif progress_bar_value < 75.0:
			progress_bar_value += 1.0
		elif progress_bar_value < 90.0:
			progress_bar_value += 0.5
		elif progress_bar_value <= 999:
			progress_bar_value -= 0.5
	
	# Emit signals for next beat
	var next_beat = (current_beat + 1) % beats_amount
	
	var clap_active = beat_actives[1][next_beat] if next_beat < beat_actives[1].size() else false
	if clap_active:
		should_clap.emit()
	
	var stomp_active = beat_actives[0][next_beat] if next_beat < beat_actives[0].size() else false
	if stomp_active:
		should_stomp.emit()
	
	# Random pitch variation for ring 3
	if audio_player_manager and audio_player_manager.audio_players.size() > 3:
		var strength = 0.2
		var scale = 1.0 + (randf() - 0.5) * strength
		audio_player_manager.audio_players[3].pitch_scale = scale
		if audio_player_manager.audio_players_alt.size() > 3:
			audio_player_manager.audio_players_alt[3].pitch_scale = scale
		if audio_player_manager.audio_players_rec.size() > 3:
			audio_player_manager.audio_players_rec[3].pitch_scale = scale

func toggle_beat(ring: int, beat: int):
	"""Toggle a beat on or off"""
	print("Toggling beat - Ring: ", ring, " Beat: ", beat) # Debug print
	if ring >= 0 and ring < beat_actives.size() and beat >= 0 and beat < beat_actives[ring].size():
		beat_actives[ring][beat] = not beat_actives[ring][beat]

func set_beat(ring: int, beat: int, active: bool):
	"""Set a beat to active or inactive"""
	if ring >= 0 and ring < beat_actives.size() and beat >= 0 and beat < beat_actives[ring].size():
		beat_actives[ring][beat] = active

func get_beat(ring: int, beat: int) -> bool:
	"""Get whether a beat is active"""
	if ring >= 0 and ring < beat_actives.size() and beat >= 0 and beat < beat_actives[ring].size():
		return beat_actives[ring][beat]
	return false

func clear_all_beats():
	"""Clear all beats"""
	for ring in range(beat_actives.size()):
		for beat in range(beat_actives[ring].size()):
			beat_actives[ring][beat] = false

func play_metronome_sfx():
	"""Play metronome sound effect"""
	if audio_player_manager and metronome_sfx:
		audio_player_manager.play_sfx(metronome_sfx)
