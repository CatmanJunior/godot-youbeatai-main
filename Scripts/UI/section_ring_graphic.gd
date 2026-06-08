extends TextureRect
class_name SectionRingGraphic

@export var fill_material: ShaderMaterial
@export var repeating: int # the amount of filled shapes
@export var fill: float # progress to the next shape

@export var pulse_on_change: bool = false
@export var pulse_color: Color
var default_color: Color

func _ready():
    default_color = self_modulate
    fill_material = material as ShaderMaterial
    update_fill_shader() # setup first values

func set_repeating(value: int) -> void:
    var changed:= value != repeating
    repeating = value
    update_fill_shader()

    if pulse_on_change and changed:
        var tween = create_tween()
        tween.tween_property(self, "self_modulate", pulse_color, 0.2)
        tween.tween_property(self, "self_modulate", default_color, 0.3)
        return


func set_fill(value: float):
    fill = min(value, 1)
    update_fill_shader()

func update_fill_shader() -> void:
    var fill_value = calculate_fill()
    fill_material.set_shader_parameter("fill_amount", fill_value)

func calculate_fill() -> float:
    return (repeating * 0.125) + (fill * 0.125)
