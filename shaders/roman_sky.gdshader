shader_type canvas_item;
render_mode unshaded;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1)), f.x), f.y);
}
void fragment() {
	vec2 p = UV * vec2(6.0, 4.0);
	float mist = noise(p) * 0.5 + noise(p * 2.1) * 0.25 + noise(p * 4.3) * 0.125;
	float edge = smoothstep(0.22, 0.9, length((UV - 0.5) * vec2(1.35, 1.0)));
	vec3 color = mix(vec3(0.012, 0.025, 0.055), vec3(0.075, 0.09, 0.19), mist * edge);
	color += vec3(0.06, 0.025, 0.12) * mist * smoothstep(0.4, 0.0, distance(UV, vec2(0.2, 0.7)));
	COLOR = vec4(color, 1.0);
}
