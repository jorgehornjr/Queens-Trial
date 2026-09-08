shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;

uniform vec4 neon_color : source_color = vec4(0.82, 0.58, 0.21, 1.0);
uniform float phase = 0.0;

float segment(vec2 p, vec2 a, vec2 b) {
	vec2 d = b - a;
	return length(p - a - d * clamp(dot(p-a, d) / dot(d,d), 0.0, 1.0));
}

void fragment() {
	// Three hollow chevrons; each pulse fades fully before the next lights up.
	vec2 p = vec2((UV.x - 0.5) * 2.0, UV.y * 3.65);
	float light = 0.0;
	float core = 0.0;
	for (int i = 0; i < 3; i++) {
		vec2 q = p - vec2(0.0, 0.34 + float(i) * 1.12);
		vec2 a = vec2(-0.69, 0.0);
		vec2 b = vec2(0.0, 0.57);
		vec2 c = vec2(0.69, 0.0);
		vec2 d = vec2(0.84, 0.17);
		vec2 e = vec2(0.0, 0.88);
		vec2 f = vec2(-0.84, 0.17);
		float dist = min(min(segment(q,a,b),segment(q,b,c)), min(segment(q,c,d),segment(q,d,e)));
		dist = min(dist, min(segment(q,e,f),segment(q,f,a)));
		float cycle = mod(TIME * 1.65 + phase * 3.0 - float(i) + 3.0, 3.0);
		float pulse = smoothstep(0.0, 0.18, cycle) * (1.0 - smoothstep(0.38, 0.98, cycle));
		float tube = 1.0 - smoothstep(0.011, 0.029, dist);
		float glow = exp(-dist * 18.0) * 0.56 + exp(-dist * 6.5) * 0.12;
		light += (tube + glow) * pulse;
		core += tube * pulse;
	}
	vec3 radiance = neon_color.rgb * 2.2 + vec3(1.0, 0.86, 0.52) * core * 1.3;
	ALBEDO = radiance;
	EMISSION = radiance;
	ALPHA = clamp(light, 0.0, 1.0) * neon_color.a;
}
