shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;

uniform vec4 tint : source_color = vec4(0.15, 1.0, 0.48, 1.0);
uniform vec3 core_tint : source_color = vec3(0.60, 0.85, 0.74);
uniform bool wall = false;
uniform float reveal : hint_range(0.0, 1.0) = 1.0;
uniform float phase = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x),
		mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

void fragment() {
	float t = TIME * 0.52 + phase;
	float light;
	float core;
	if (wall) {
		float height = 1.0 - UV.y;
		vec2 flow = vec2(UV.x * 9.0, height * 3.0 - t);
		float vapor = noise(flow) * 0.65 + noise(flow * 2.3 + 4.7) * 0.35;
		float ceiling = 0.22 + 0.72 * noise(vec2(UV.x * 7.0, t * 0.6));
		float plume = (1.0 - smoothstep(ceiling * 0.18, ceiling, height));
		float strands = pow(noise(vec2(UV.x * 26.0 + sin(height * 5.0 - t), height * 4.0 - t * 2.1)), 4.0);
		float top_fade = 1.0 - smoothstep(0.48, 1.0, height);
		core = exp(-height * 48.0) * 0.65;
		light = core + (vapor * plume * 0.30 + strands * plume * 0.9) * top_fade;
		// Sparse pinpoints rise inside the wisps, never over the marble center.
		vec2 stars = vec2(UV.x * 30.0, height * 8.0 - t * 1.5);
		float speck = pow(max(0.0, 1.0 - length((fract(stars) - 0.5) * vec2(2.0, 3.0))), 9.0);
		light += speck * step(0.82, hash(floor(stars))) * top_fade * 0.8;
	} else {
		vec2 p = abs(UV * 2.0 - 1.0);
		float edge = max(p.x, p.y);
		float d = abs(edge - 0.91);
		core = exp(-d * 210.0);
		float inner = exp(-abs(edge - 0.85) * 160.0) * 0.16;
		float halo = exp(-d * 28.0) * 0.35;
		float corner = smoothstep(0.78, 0.91, min(p.x, p.y));
		float flow = 0.78 + 0.22 * sin((UV.x + UV.y) * 16.0 - t * 4.0);
		light = (core + inner + halo) * flow + halo * corner * 0.5;
	}
	vec3 radiance = tint.rgb * 2.1 + core_tint * core * 0.7;
	ALBEDO = radiance;
	EMISSION = radiance;
	ALPHA = clamp(light * reveal * tint.a, 0.0, 0.92);
}
