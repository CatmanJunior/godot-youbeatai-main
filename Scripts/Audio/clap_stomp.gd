extends Node
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

func _ready() -> void:
	EventBus.clap_triggered.connect(on_clap)
	EventBus.stomp_triggered.connect(on_stomp)


func on_clap():
	_handle_beat_interaction(1)

func on_stomp():
	_handle_beat_interaction(0)


func _handle_beat_interaction(ring: int) -> void:
	var active = GameState.current_section.get_beat(ring, GameState.current_beat)
	if time_after_play < 0.2:
		return

	

	if active:
		progress_bar_value += 2.0
		EventBus.progress_bar_particles_requested.emit()
	
	if ring < GameState.colors.size():
		EventBus.particles_requested.emit(Vector2.ZERO, GameState.colors[ring])
	else:
		progress_bar_value -= 1.0

	if active:
		if ring == 0:
			stomped_on_beat_amount += 1
		else:
			clapped_on_beat_amount += 1
	else:
		if ring == 0:
			stomped_amount += 1
		else:
			clapped_amount += 1

	if GameState.add_beats_enabled:
		EventBus.beat_set_requested.emit(ring, GameState.current_beat, true)

func _on_beat():
	# Emit signals for next beat
	var next_beat = (GameState.current_beat + 1) % GameState.current_section.beats_amount
	var clap_active = GameState.current_section.get_beat(1, next_beat)
	if clap_active:
		EventBus.clap_triggered.emit()
	
	var stomp_active = GameState.current_section.get_beat(0, next_beat)
	if stomp_active:
		EventBus.stomp_triggered.emit()

