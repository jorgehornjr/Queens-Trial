shader_type canvas_item;

uniform float reveal_progress : hint_range(0.0, 1.0) = 0.0;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise21(vec2 p) {
	vec2 cell = floor(p);
	vec2 local = fract(p);
	local = local * local * (3.0 - 2.0 * local);
	float a = hash21(cell);
	float b = hash21(cell + vec2(1.0, 0.0));
	float c = hash21(cell + vec2(0.0, 1.0));
	float d = hash21(cell + vec2(1.0, 1.0));
	return mix(mix(a, b, local.x), mix(c, d, local.x), local.y);
}

void fragment() {
	vec4 ink = texture(TEXTURE, UV) * COLOR;
	if (reveal_progress < 0.999) {
		float islands = 0.57 * noise21(SCREEN_UV * vec2(19.0, 11.0));
		islands += 0.28 * noise21(SCREEN_UV * vec2(51.0, 29.0));
		islands += 0.15 * hash21(floor(SCREEN_UV * vec2(166.0, 96.0)));
		float arrival = 0.12 + islands * 0.76;
		float visible_ink = smoothstep(arrival - 0.055, arrival + 0.055, reveal_progress);
		float fresh_edge = 1.0 - smoothstep(0.0, 0.095, abs(reveal_progress - arrival));
		ink.rgb = mix(ink.rgb, vec3(0.43, 0.22, 0.12), fresh_edge * visible_ink * 0.22);
		ink.a *= visible_ink;
	}
	COLOR = ink;
}
