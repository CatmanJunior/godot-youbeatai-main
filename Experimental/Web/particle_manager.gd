extends Node

# Particle systems
@export var beat_particles: CPUParticles2D
@export var pbar_particles: CPUParticles2D
@export var achievement_particles: CPUParticles2D

# Beat particles state
var beat_particles_position: Vector2
var beat_particles_time: float = 0.0
var beat_particles_curtime: float = 0.0
var beat_particles_color: Color = Color.WHITE
var beat_particles_emitting: bool = false

# Progress bar particles state
var pbar_particles_time: float = 0.0
var pbar_particles_curtime: float = 0.0
var pbar_particles_emitting: bool = false

# Achievement particles state
var achievement_particles_time: float = 0.0
var achievement_particles_curtime: float = 0.0
var achievement_particles_emitting: bool = false

func handle_particles(delta: float):
	"""Update all particle systems"""
	_handle_beat_particles(delta)
	_handle_pbar_particles(delta)
	_handle_achievement_particles(delta)

func _handle_beat_particles(delta: float):
	"""Handle beat particles emission"""
	if beat_particles_emitting and beat_particles_curtime < beat_particles_time:
		if beat_particles:
			beat_particles.color = beat_particles_color
			beat_particles.position = beat_particles_position
			beat_particles.emitting = true
		beat_particles_curtime += delta
	else:
		if beat_particles:
			beat_particles.emitting = false
		beat_particles_emitting = false

func _handle_pbar_particles(delta: float):
	"""Handle progress bar particles emission"""
	if pbar_particles_emitting and pbar_particles_curtime < pbar_particles_time:
		if pbar_particles:
			pbar_particles.emitting = true
		pbar_particles_curtime += delta
	else:
		if pbar_particles:
			pbar_particles.emitting = false
		pbar_particles_emitting = false

func _handle_achievement_particles(delta: float):
	"""Handle achievement particles emission"""
	if achievement_particles_emitting and achievement_particles_curtime < achievement_particles_time:
		if achievement_particles:
			achievement_particles.emitting = true
		achievement_particles_curtime += delta
	else:
		if achievement_particles:
			achievement_particles.emitting = false
		achievement_particles_emitting = false

func emit_beat_particles(position: Vector2, color: Color):
	"""Emit particles at a beat position with a specific color"""
	beat_particles_curtime = 0.0
	beat_particles_time = 0.05
	beat_particles_position = position
	beat_particles_color = color.lightened(0.25)
	beat_particles_emitting = true

func emit_progress_bar_particles():
	"""Emit progress bar particles"""
	return  # temp fix as in C# code
	# Uncomment when ready:
	# pbar_particles_curtime = 0.0
	# pbar_particles_time = 0.4
	# pbar_particles_emitting = true

func emit_achievement_particles():
	"""Emit achievement particles"""
	return  # temp fix as in C# code
	# Uncomment when ready:
	# achievement_particles_curtime = 0.0
	# achievement_particles_time = 0.5
	# achievement_particles_emitting = true
