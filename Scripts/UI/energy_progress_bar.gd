extends ProgressBar
## Keeps the energy progress bar in sync with EnergyManager via EventBus.

func _ready() -> void:
	value = GameState.energy_points
	EventBus.energy_points_changed.connect(_on_energy_points_changed)


func _on_energy_points_changed(points: float) -> void:
	value = points
