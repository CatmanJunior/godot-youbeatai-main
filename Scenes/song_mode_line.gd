extends MeshInstance2D
@export var manager : Manager


func _process(delta: float) -> void:
	visible = manager.SongModeActive
