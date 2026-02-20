extends Sprite2D

# Beat location
var ring: int = 0
var sprite_index: int = 0

# References
var area: Area2D
var collider: CollisionShape2D

# Manager references
var beat_manager: Node
var mixing_manager: Node
var particle_manager: Node
var audio_player_manager: Node
var game_manager: Node

func _ready():
	# Get child nodes immediately
	area = get_child(0) as Area2D
	if area:
		collider = area.get_child(0) as CollisionShape2D
	
	# Set up collision shape
	if collider and collider.shape is CircleShape2D:
		var sprite_size = texture.get_size()
		(collider.shape as CircleShape2D).radius = sprite_size.x * 0.5
	
	# Connect input signal
	if area:
		area.input_event.connect(_on_area_input)
	
	# Wait for managers to be ready
	await get_tree().process_frame # Wait one frame for everything to initialize
	_setup_managers()

func _setup_managers():
	"""Setup manager references after a delay"""
	game_manager = get_node_or_null("/root/scene/Managers/GameManager")
	beat_manager = get_node_or_null("/root/scene/Managers/GameManager/BeatManager")
	mixing_manager = get_node_or_null("/root/scene/Managers/GameManager/MixingManager")
	particle_manager = get_node_or_null("/root/scene/Managers/GameManager/ParticleManager")
	audio_player_manager = get_node_or_null("/root/scene/Managers/GameManager/AudioPlayerManager")

func _on_area_input(viewport: Node, input_event: InputEvent, shape_idx: int):
	"""Handle input events on the beat sprite"""
	# Don't respond if not visible or settings are open
	if not visible:
		return
	
	# if game_manager.settings_panel.visible:
	# 		return
	
	# Check for left mouse button release
	if input_event is InputEventMouseButton:
		var mouse_event = input_event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.is_released():
			_on_click()

func _on_click():
	"""Handle beat sprite click"""
	# Toggle beat state

	beat_manager.toggle_beat(ring, sprite_index)
	var is_active = beat_manager.get_beat(ring, sprite_index)
	
	# Play audio if beat is now active
	if is_active:
		if audio_player_manager:
			audio_player_manager.play_ring(ring)
	
	# Emit particles at beat position
	if particle_manager and game_manager:
		var beat_sprites = game_manager.get_node_or_null("BeatSprites")
		if beat_sprites:
			var colors = game_manager.colors if game_manager.has("colors") else []
			if ring < colors.size():
				particle_manager.emit_beat_particles(position, colors[ring])
	
	# Change mixing ring
	mixing_manager.samples_mixing_change_ring(ring)


func set_sprite_index(beat: int) -> void:
	sprite_index = beat

func set_ring(ring_index: int) -> void:
	ring = ring_index
