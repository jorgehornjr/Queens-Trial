shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;

uniform vec4 tint : source_color = vec4(0.18, 0.72, 1.0, 1.0);
uniform float motif : hint_range(0.0, 3.0, 1.0) = 0.0;
uniform float reveal : hint_range(0.0, 1.0) = 1.0;
uniform float intensity : hint_range(0.0, 8.0) = 2.0;
uniform float phase = 0.0;

float band(float value, float center, float width) {
	return 1.0 - smoothstep(width, width + 0.018, abs(value - center));
}

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 345.45));
	p += dot(p, p + 34.345);
	return fract(p.x * p.y);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float radius = length(p);
	float angle = atan(p.y, p.x);
	float time = TIME + phase;
	float shape = 0.0;
	float hot = 0.0;

	if (motif < 0.5) {
		// Destination seal: concentric astrolabe rings, orbiting gaps and a soft core.
		float outer = band(radius, 0.82, 0.025);
		float middle = band(radius, 0.62, 0.014) * step(0.20, fract(angle * 1.273 + time * 0.13));
		float inner = band(radius, 0.36 + sin(angle * 6.0 + time) * 0.018, 0.012);
		float spokes = pow(max(0.0, cos(angle * 8.0 + time * 0.22)), 42.0) * smoothstep(0.30, 0.70, radius) * (1.0 - smoothstep(0.74, 0.82, radius));
		float orbit = band(length(p - vec2(cos(time), sin(time)) * 0.62), 0.055, 0.035);
		shape = outer + middle * 0.8 + inner * 0.7 + spokes * 0.85 + orbit;
		hot = outer * (0.65 + 0.35 * sin(time * 3.0)) + orbit;
		shape += (1.0 - smoothstep(0.0, 0.48, radius)) * 0.10;
	} else if (motif < 1.5) {
		// Tutorial tile: corner brackets and a travelling guidance wave.
		vec2 edge = abs(p);
		float frame = max(band(edge.x, 0.86, 0.018) * step(0.42, edge.y), band(edge.y, 0.86, 0.018) * step(0.42, edge.x));
		float corners = max(band(edge.x + edge.y, 1.36, 0.025), band(edge.x - edge.y, 0.0, 0.016) * step(0.70, edge.x));
		float scan = exp(-pow((UV.y - fract(time * 0.28 + phase * 0.17)) * 15.0, 2.0)) * (1.0 - smoothstep(0.68, 0.92, edge.x));
		float constellation = step(0.91, hash21(floor(UV * 9.0) + phase)) * (1.0 - smoothstep(0.0, 0.075, length(fract(UV * 9.0) - 0.5)));
		shape = frame + corners * 0.22 + scan * 0.52 + constellation * 0.65;
		hot = scan + frame * 0.35;
	} else if (motif < 2.5) {
		// Attack tile: restrained danger border with moving arcane fractures.
		vec2 edge = abs(p);
		float frame = max(band(edge.x, 0.88, 0.026), band(edge.y, 0.88, 0.026));
		float inset = max(band(edge.x, 0.72, 0.010), band(edge.y, 0.72, 0.010)) * 0.34;
		float slash_a = band(p.y + p.x * 0.58 + sin(p.x * 11.0 + phase) * 0.055, 0.08, 0.018);
		float slash_b = band(p.y - p.x * 0.82 + sin(p.y * 9.0 - phase) * 0.04, -0.28, 0.012);
		float travelling = exp(-pow((UV.y - fract(time * 0.48 - phase * 0.09)) * 22.0, 2.0));
		float inside = 1.0 - smoothstep(0.84, 0.90, max(edge.x, edge.y));
		shape = frame + inset + (slash_a * 0.58 + slash_b * 0.38) * inside + travelling * inside * 0.18;
		hot = travelling * inside + frame * (0.35 + 0.25 * sin(time * 5.0 - phase));
	} else {
		// Direction strip: luminous chevrons etched into the border.
		float along = fract(UV.y * 3.0 - time * 0.72 + phase);
		float chevron = band(abs(UV.x - 0.5) + (along - 0.48) * 0.78, 0.24, 0.045);
		chevron *= step(0.16, along) * step(along, 0.74);
		float rails = band(abs(UV.x - 0.5), 0.40, 0.018) * 0.28;
		float wake = exp(-pow((along - 0.46) * 5.0, 2.0));
		shape = chevron + rails + wake * 0.12;
		hot = chevron * wake;
	}

	float dissolve_noise = (hash21(floor(UV * 36.0) + phase) - 0.5) * 0.10;
	float dissolve = smoothstep(0.0, 0.08, reveal) * (1.0 - smoothstep(reveal, reveal + 0.16, UV.x + dissolve_noise));
	float pulse = 0.82 + 0.18 * sin(time * 2.6 + phase);
	vec3 color = tint.rgb * (intensity * pulse + hot * 4.5);
	EMISSION = color;
	ALBEDO = tint.rgb;
	ALPHA = clamp(shape * tint.a * dissolve, 0.0, 1.0);
}
