shader_type canvas_item;
render_mode unshaded;

uniform float fuerza : hint_range(0.0, 1.0) = 0.6;
uniform float inicio : hint_range(0.0, 1.0) = 0.22;
uniform float fin : hint_range(0.0, 1.0) = 0.85;

void fragment() {
	vec2 p = UV - vec2(0.5);
	float d = length(p) * 1.41421356;
	float v = smoothstep(inicio, fin, d);
	COLOR = vec4(0.0, 0.0, 0.0, v * fuerza);
}
