extends Node

## Tracks per-emitter timing state to avoid nine separate scalar variables.
class ParticleState:
	var time: float = 0.0
	var curtime: float = 0.0
	var emitting: bool = false
	var position: Vector2 = Vector2.ZERO
	var color: Color = Color.WHITE

	func start(duration: float, pos: Vector2 = Vector2.ZERO, col: Color = Color.WHITE) -> void:
		curtime = 0.0
		time = duration
		position = pos
		color = col
		emitting = true

	func tick(node: CPUParticles2D, delta: float) -> void:
		if emitting and curtime < time:
			if node:
				node.emitting = true
			curtime += delta
		else:
			if node:
				node.emitting = false
			emitting = false

# Particle systems
@export var beat_particles: CPUParticles2D
@export var pbar_particles: CPUParticles2D
@export var achievement_particles: CPUParticles2D

var _beat_state := ParticleState.new()
var _pbar_state := ParticleState.new()
var _achievement_state := ParticleState.new()

func _ready():
	# Connect to EventBus so other scripts don't need a direct reference
	EventBus.particles_requested.connect(emit_beat_particles)
	EventBus.progress_bar_particles_requested.connect(emit_progress_bar_particles)
	EventBus.achievement_particles_requested.connect(emit_achievement_particles)

func handle_particles(delta: float):
	"""Update all particle systems"""
	if beat_particles and _beat_state.emitting:
		beat_particles.color = _beat_state.color
		beat_particles.position = _beat_state.position
	_beat_state.tick(beat_particles, delta)
	_pbar_state.tick(pbar_particles, delta)
	_achievement_state.tick(achievement_particles, delta)

func emit_beat_particles(position: Vector2, color: Color):
	"""Emit particles at a beat position with a specific color"""
	_beat_state.start(0.05, position, color.lightened(0.25))

func emit_progress_bar_particles():
	"""Emit progress bar particles"""
	return  # temp fix as in C# code
	# Uncomment when ready:
	# _pbar_state.start(0.4)

func emit_achievement_particles():
	"""Emit achievement particles"""
	return  # temp fix as in C# code
	# Uncomment when ready:
	# _achievement_state.start(0.5)
