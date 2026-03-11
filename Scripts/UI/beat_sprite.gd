extends Sprite2D

# Beat location
var ring: int = 0
var sprite_index: int = 0

# References
var area: Area2D
var collider: CollisionShape2D

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
	"""Handle beat sprite click — emit event, let managers handle the rest"""
	EventBus.beat_sprite_clicked.emit(ring, sprite_index)


func set_sprite_index(beat: int) -> void:
	sprite_index = beat

func set_ring(ring_index: int) -> void:
	ring = ring_index
