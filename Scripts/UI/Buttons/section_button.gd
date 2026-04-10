extends Button
class_name SectionButton

@export var outline : TextureRect

var index: int

func _ready():
    outline.visible = false

func rotate_outline(outline_rotation_angle: float):
    outline.rotation_degrees = outline_rotation_angle

