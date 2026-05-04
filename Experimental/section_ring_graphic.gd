extends TextureRect
class_name SectionRingGraphic

@export var fill_material: ShaderMaterial
@export var repeating: int # the amount of filled shapes
@export var fill: float # progress to the next shape

func _ready():
    fill_material = material as ShaderMaterial
    update_fill_shader() # setup first values

func set_repeating(value: int) -> void:
    repeating = value
    update_fill_shader()

func set_fill(value: float):
    fill = min(value, 1)
    update_fill_shader()

func update_fill_shader() -> void:
    var fill_value = calculate_fill()
    fill_material.set_shader_parameter("fill_amount", fill_value)

func calculate_fill() -> float:
    return (repeating * 0.125) + (fill * 0.125)
