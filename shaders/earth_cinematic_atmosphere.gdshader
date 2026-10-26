shader_type spatial;
render_mode unshaded, blend_add, cull_back, depth_draw_never, fog_disabled;

uniform vec3 sun_direction = vec3(-0.97, 0.12, -0.2);
varying vec3 world_normal;

void vertex() {
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	float rim = pow(1.0 - max(dot(normalize(NORMAL), normalize(VIEW)), 0.0), 5.0);
	float daylight = smoothstep(-0.18, 0.5, dot(normalize(world_normal), normalize(sun_direction)));
	vec3 tint = mix(vec3(0.08, 0.22, 0.55), vec3(0.35, 0.57, 0.9), daylight);
	ALBEDO = vec3(0.0);
	EMISSION = tint * 1.4;
	ALPHA = rim * mix(0.018, 0.30, daylight);
}
