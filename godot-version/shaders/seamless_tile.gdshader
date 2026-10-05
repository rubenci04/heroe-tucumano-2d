shader_type canvas_item;
// Repite una imagen que NO es sin costura (sin espejarla): el sprite muestra solo las primeras
// (1 - overlap) columnas de la textura y sus primeras `overlap` columnas se funden con las últimas,
// de modo que el final de un módulo continúa exactamente en el comienzo del siguiente.
uniform float overlap : hint_range(0.0, 0.5) = 0.12; // fracción del ancho total de la textura

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	if (UV.x < overlap) {
		vec4 wrapped = texture(TEXTURE, vec2(UV.x + (1.0 - overlap), UV.y));
		base = mix(wrapped, base, smoothstep(0.0, overlap, UV.x));
	}
	COLOR = base;
}
