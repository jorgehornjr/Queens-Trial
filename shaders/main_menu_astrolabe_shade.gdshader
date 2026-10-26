shader_type canvas_item;
render_mode unshaded;
varying vec4 tint;
void vertex() { tint = COLOR; }

void fragment() {
	vec2 p = (UV - vec2(0.5, 0.52)) * vec2(2.0, 2.2);
	float center = exp(-dot(p * vec2(1.0, 1.12), p * vec2(1.0, 1.12)) * 2.8);
	float edge = (1.0 - smoothstep(0.65, 1.0, abs(p.x))) * (1.0 - smoothstep(0.68, 1.0, abs(p.y)));
	vec2 px = UV * vec2(1200.0, 400.0);
	vec2 primary = (px - vec2(600.0, 134.0)) / vec2(228.0, 57.0);
	vec2 left = (px - vec2(300.0, 244.0)) / vec2(200.0, 52.0);
	vec2 right = (px - vec2(900.0, 244.0)) / vec2(200.0, 52.0);
	float shade = max(exp(-dot(primary, primary) * 1.4), max(exp(-dot(left, left) * 1.4), exp(-dot(right, right) * 1.4)));
	COLOR = vec4(vec3(0.008, 0.017, 0.035), max(center * edge * 0.70, shade * 0.92)) * tint;
}
