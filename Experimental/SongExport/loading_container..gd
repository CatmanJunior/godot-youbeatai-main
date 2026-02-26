extends Control

class_name LoadingContainer

@export var progress: ColorRect

func _ready():
	close() # default close

func open():
	set_progress(0)
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP

func set_progress(value):
	progress.visible = value > 0
	progress.material.set_shader_parameter( "value", value )

func close():
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
