shader_type canvas_item;
render_mode unshaded;
varying vec4 vertex_tint;

void vertex() {
	vertex_tint = COLOR;
}

void fragment() {
	vec4 book = texture(TEXTURE, UV);
	float engraving = smoothstep(0.06, 0.19, book.g - book.b * 0.9);
	float heartbeat = 0.52 + 0.48 * sin(TIME * 2.3 + UV.y * 11.0);
	float shimmer = pow(max(0.0, sin(UV.x * 17.0 + UV.y * 12.0 - TIME * 1.6)), 18.0);
	float gold = smoothstep(0.15, 0.38, book.r - book.b);
	book.rgb += vec3(0.13, 0.085, 0.026) * engraving * heartbeat;
	book.rgb += vec3(0.22, 0.15, 0.045) * shimmer * gold;
	COLOR = book * vertex_tint;
}
