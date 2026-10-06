shader_type canvas_item;
render_mode unshaded;
varying vec4 vertex_tint;

void vertex() { vertex_tint = COLOR; }

float grain(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
	float b = fract(sin(dot(cell + vec2(1.0, 0.0), vec2(127.1, 311.7))) * 43758.5453);
	float c = fract(sin(dot(cell + vec2(0.0, 1.0), vec2(127.1, 311.7))) * 43758.5453);
	float d = fract(sin(dot(cell + vec2(1.0), vec2(127.1, 311.7))) * 43758.5453);
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec4 ink = texture(TEXTURE, UV);
	float paper = grain(UV * vec2(630.0, 280.0));
	// Preserve every contour and letter of the user's original logo.
	ink.rgb *= 0.94 + paper * 0.06;
	ink.a *= 0.86 + paper * 0.14;
	COLOR = ink * vertex_tint;
}
