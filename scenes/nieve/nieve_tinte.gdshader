shader_type canvas_item;

// Tinte de nieve: desatura el terreno y lo mezcla hacia un blanco-azulado,
// conservando parte de la variacion de luminancia original.
// En canvas_item, COLOR ya incluye la textura y el modulate del nodo,
// por eso se modifica directamente en vez de volver a muestrear TEXTURE.
uniform vec3 nieve_color : source_color = vec3(0.93, 0.96, 1.0);
uniform float intensidad : hint_range(0.0, 1.0) = 0.88;

void fragment() {
	float lum = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114));
	vec3 objetivo = nieve_color * (0.80 + 0.40 * lum);
	COLOR.rgb = mix(COLOR.rgb, objetivo, intensidad);
}
