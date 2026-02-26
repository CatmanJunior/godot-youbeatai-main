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

func _ready():
	# Initialize beat_actives array [4 rings][beats_amount beats]
	for ring in range(4):
		var ring_beats = []
		for beat in range(beats_amount):
			ring_beats.append(false)
		beat_actives.append(ring_beats)
	
	# Connect to EventBus
	EventBus.beat_sprite_clicked.connect(_on_beat_sprite_clicked)
	EventBus.beat_triggered.connect(_on_beat_triggered)
	EventBus.beat_set_requested.connect(set_beat)
	EventBus.template_set.connect(_on_template_set)
	EventBus.clap_triggered.connect(on_clap)
	EventBus.stomp_triggered.connect(on_stomp)
	EventBus.layer_changed.connect(_on_layer_changed)

func _on_layer_changed(_new_layer_index: int, new_layer_beats: Array):
	"""Handle layer change via EventBus"""
	# Update beat_actives to match the new layer's beats
	beat_actives = new_layer_beats

func _on_beat_sprite_clicked(p_ring: int, beat: int):
	"""Handle beat sprite click via EventBus"""
	toggle_beat(p_ring, beat)
	var is_active = get_beat(p_ring, beat)
	if is_active:
		EventBus.play_ring_requested.emit(p_ring)
	if p_ring < colors.size():
		EventBus.particles_requested.emit(Vector2.ZERO, colors[p_ring])
	EventBus.beat_state_changed.emit(p_ring, beat, is_active)
	EventBus.ring_selected.emit(p_ring)

func _on_beat_triggered(beat: int):
	"""Called each beat via EventBus"""
	current_beat = beat
	on_beat()

func _on_template_set(actives: Array):
	"""Apply template beat actives"""
	beat_actives = actives

func check_if_clapping_or_stomping():
	"""Check microphone input for clapping or stomping.
	Now handled externally — microphone_capture emits EventBus signals."""
	pass

func on_clap():
	"""Handle clap detection"""
	if time_after_play < 0.2:
		return
	
	var ring = 1
	var active = beat_actives[ring][current_beat] if ring < beat_actives.size() and current_beat < beat_actives[ring].size() else false
	
	if active:
		# Hit on beat - reward player
		progress_bar_value += 2.0
		EventBus.progress_bar_particles_requested.emit()
		if ring < colors.size():
			EventBus.particles_requested.emit(Vector2.ZERO, colors[ring])
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
		EventBus.progress_bar_particles_requested.emit()
		if ring < colors.size():
			EventBus.particles_requested.emit(Vector2.ZERO, colors[ring])
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
	
	# Play audio for active beats via EventBus
	for ring in range(4):
		if ring < beat_actives.size() and current_beat < beat_actives[ring].size():
			if beat_actives[ring][current_beat]:
				EventBus.play_ring_requested.emit(ring)
	
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
		EventBus.should_clap.emit()
	
	var stomp_active = beat_actives[0][next_beat] if next_beat < beat_actives[0].size() else false
	if stomp_active:
		EventBus.should_stomp.emit()

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
	if metronome_sfx:
		EventBus.play_sfx_requested.emit(metronome_sfx)
