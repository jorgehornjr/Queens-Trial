shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform float intensity = 1.0;
uniform float opacity = 0.7;
varying vec3 local_position;
float hash_noise(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float soft_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash_noise(cell), hash_noise(cell + vec2(1, 0)), f.x),
		mix(hash_noise(cell + vec2(0, 1)), hash_noise(cell + vec2(1, 1)), f.x), f.y);
}
void vertex() { local_position = VERTEX; }
void fragment() {
	float radius = length(local_position.xz);
	// Filamentos de gás com amostragem cartesiana contínua na emenda polar.
	float swirl = radius * 4.5;
	mat2 turn = mat2(vec2(cos(swirl), sin(swirl)), vec2(-sin(swirl), cos(swirl)));
	vec2 p = turn * local_position.xz * 5.0;
	float clouds = 0.65 * soft_noise(p) + 0.25 * soft_noise(p * 2.03 + 8.7)
		+ 0.10 * soft_noise(p * 4.01 + 21.3);
	float streaks = mix(0.55, 1.0, clouds);
	float inner_heat = 1.0 - smoothstep(0.24, 0.70, radius);
	vec3 heat_color = mix(vec3(0.48, 0.105, 0.014), vec3(1.0, 0.72, 0.30), inner_heat);
	ALBEDO = heat_color * streaks * intensity * (1.0 + 1.6 * inner_heat);
	ALPHA = opacity * smoothstep(0.235, 0.27, radius) * (1.0 - smoothstep(0.50, 0.76, radius)) * streaks;
}
