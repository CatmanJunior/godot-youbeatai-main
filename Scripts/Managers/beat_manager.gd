extends Node

func _ready():	
	# Connect to EventBus
	EventBus.beat_sprite_clicked.connect(_on_beat_sprite_clicked)
	EventBus.beat_triggered.connect(_on_beat_triggered)
	EventBus.beat_set_requested.connect(set_beat)
	EventBus.template_set.connect(_on_template_set)

func _on_beat_sprite_clicked(p_ring: int, beat: int):
	"""Handle beat sprite click via EventBus"""
	toggle_beat(p_ring, beat)
	var is_active = get_beat(p_ring, beat)
	if is_active:
		EventBus.play_sample_track_requested.emit(p_ring)
	if p_ring < GameState.colors.size():
		EventBus.particles_requested.emit(Vector2.ZERO, GameState.colors[p_ring])
	EventBus.track_selected.emit(p_ring)

func _on_beat_triggered(current_beat: int):
	"""Called when a beat occurs"""
	# Play audio for active beats via EventBus
	for track_index in range(GameState.current_section.SAMPLE_TRACKS_PER_SECTION):
		if GameState.current_section.get_beat(track_index, current_beat):
			EventBus.play_sample_track_requested.emit(track_index)
	if current_beat == 0:
		for track_index in range(GameState.current_section.SYNTH_TRACKS_PER_SECTION):
			EventBus.play_track_requested.emit(track_index + GameState.current_section.SAMPLE_TRACKS_PER_SECTION)

func _on_template_set(actives: Array):
	"""Apply template beat actives"""
	if GameState.current_section:
		GameState.current_section.set_beat_actives(actives)

func toggle_beat(ring: int, beat: int):
	"""Toggle a beat on or off"""
	GameState.current_section.toggle_beat(ring, beat)
	
	var is_active = GameState.current_section.get_beat(ring, beat)
	EventBus.beat_state_changed.emit(ring, beat, is_active)

func set_beat(ring: int, beat: int, active: bool):
	"""Set a beat to active or inactive"""
	GameState.current_section.set_beat(ring, beat, active)
	EventBus.beat_state_changed.emit(ring, beat, active)

func get_beat(ring: int, beat: int) -> bool:
	"""Get whether a beat is active"""
	return GameState.current_section.get_beat(ring, beat)
