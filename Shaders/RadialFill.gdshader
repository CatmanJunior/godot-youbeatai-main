shader_type canvas_item;

uniform float fill_amount : hint_range(0.0, 1.0) = 1.0; // Fill fraction from 0 to 1
uniform float start_angle : hint_range(0.0, 360.0) = 0.0; // Start angle in degrees
uniform vec2 center = vec2(0.5, 0.5); // Center of the radial fill (normalized UV)
uniform float clockwise = 1.0; // 1.0 for clockwise, -1.0 for counter-clockwise

varying vec4 vertex_color; 

void vertex() {
	vertex_color = COLOR;
}

void fragment() {
    vec2 uv = UV - center;
    float angle = atan(uv.y, uv.x); // Angle in radians (-PI to PI)

    // Convert angle to 0..1 range, where 0 is the positive X direction.
    float normalized_angle = (angle + PI) / (2.0 * PI);

    // Reverse direction when counter-clockwise is selected.
    normalized_angle = clockwise > 0.0 ? normalized_angle : 1.0 - normalized_angle;

    float start = fract(start_angle / 360.0);
    float end = start + fill_amount;
    bool inside = end <= 1.0
        ? (normalized_angle >= start && normalized_angle <= end)
        : (normalized_angle >= start || normalized_angle <= fract(end));

    if (!inside) {
        discard;
    }

    COLOR = texture(TEXTURE, UV) * vertex_color;
}