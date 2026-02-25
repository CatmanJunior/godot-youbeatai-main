extends Sprite2D

@export var ring: int = 0
@export var button: Button

#emit signal with ring index as argument

signal on_pressed(ring: int)


var beatManager: Node
var gameManager: Node

var color_is_changing: bool = false


func _ready():
	button.button_up.connect(_on_press)
	
	beatManager = %BeatManager
	gameManager = %GameManager



func _on_press():
	if %UiManager.button_is_clap.button_pressed:
		if ring == 0:
			_button_sound()
			beatManager.on_stomp()
		elif ring == 1:
			_button_sound()
			beatManager.on_clap()
		else:
			_button_behaviour()
	else:
		_button_behaviour()

	on_pressed.emit(ring)


func _button_sound():
	%AudioPlayerManager.audio_players[ring].play()
	%AudioPlayerManager.audio_players_alt[ring].play()
	%AudioPlayerManager.audio_players_rec[ring].play()


func _button_behaviour():
	_button_sound()

	#TODO: Emit beat particles at position with color based on ring
	var button_add_beats : CheckButton = %UiManager.button_add_beats
	if button_add_beats.pressed:
		%BeatManager.set_beat(ring, %BpmManager.current_beat, true)
		# var beat_sprites: Array = %UiManager.beat_sprites
		# var position = beat_sprites[ring][%BpmManager.current_beat].global_position
		# # %UiManager.emit_beat_particles(position, gameManager.colors[ring])

	if %MixingManager.samples_mixing_active_ring != ring:
		_start_color_change(ring, 0.3)


func _start_color_change(p_ring: int, duration: float):
	color_is_changing = true

	var old_color = %UiManager.colors[p_ring]
	var new_color = old_color.lightened(1.0)

	# brighten
	var elapsed = 0.0
	while elapsed < duration:
		var t = elapsed / duration
		var ct = %MixingManager.synth_mixing_line_color_curve.sample(t) if %MixingManager.synth_mixing_line_color_curve else t
		var lerped_color = old_color.lerp(new_color, ct)
		%UiManager.colors_override[p_ring] = lerped_color

		# yield one frame
		await get_tree().process_frame
		elapsed += get_process_delta_time()

	# ensure final color is set
	%UiManager.colors_override[p_ring] = new_color

	# darken
	elapsed = 0.0
	while elapsed < duration:
		var t = elapsed / duration
		var ct = %MixingManager.synth_mixing_line_color_curve.sample(t) if %MixingManager.synth_mixing_line_color_curve else t
		var lerped_color = new_color.lerp(old_color, ct)
		%UiManager.colors_override[p_ring] = lerped_color

		# yield one frame
		await get_tree().process_frame
		elapsed += get_process_delta_time()

	# ensure final color is set
	%UiManager.colors_override[p_ring] = old_color

	color_is_changing = false
