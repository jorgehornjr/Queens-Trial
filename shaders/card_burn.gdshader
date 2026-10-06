shader_type canvas_item;

uniform float burn_progress : hint_range(0.0, 1.0) = 0.0;
uniform float burn_seed = 0.0;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
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

float burn_arrival(vec2 uv) {
	vec2 offset = vec2(burn_seed * 6.73, burn_seed * 3.91);
	float broad = noise21(uv * vec2(5.0, 7.0) + offset);
	float torn = noise21(uv * vec2(16.0, 23.0) + offset * 2.1);
	float fibers = noise21(uv * vec2(48.0, 63.0) + offset * 4.7);
	float ignition = 0.20 + 0.62 * (1.0 - uv.y);
	ignition += (broad - 0.5) * 0.24 + (torn - 0.5) * 0.18 + (fibers - 0.5) * 0.07;
	return clamp(ignition, 0.045, 0.955);
}

void fragment() {
	vec4 artwork = texture(TEXTURE, UV) * COLOR;
	float fiber = hash21(floor(UV * vec2(390.0, 552.0)) + burn_seed * 17.0);
	float live_edge = burn_progress - burn_arrival(UV) + (fiber - 0.5) * 0.016;
	float activity = smoothstep(0.0, 0.10, burn_progress);
	float intact = 1.0 - smoothstep(-0.006, 0.023, live_edge);
	float charred = smoothstep(-0.13, -0.033, live_edge) * activity;
	float coal = smoothstep(-0.071, -0.011, live_edge) * activity;
	float ember = smoothstep(-0.030, -0.006, live_edge) * (1.0 - smoothstep(0.003, 0.027, live_edge)) * activity;
	vec3 ink = mix(artwork.rgb, vec3(0.105, 0.054, 0.035), charred * 0.88);
	ink = mix(ink, vec3(0.43, 0.105, 0.025), coal * 0.72);
	ink = mix(ink, vec3(1.0, 0.52, 0.17), ember * 0.83);
	COLOR = vec4(ink, artwork.a * intact);
}
