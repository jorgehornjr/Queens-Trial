shader_type spatial;
render_mode unshaded, cull_front, depth_draw_never, depth_test_disabled, fog_disabled;

uniform sampler3D cloud_noise : filter_linear, repeat_enable;
uniform sampler2D scene_depth : hint_depth_texture, filter_nearest, repeat_disable;
uniform vec3 half_size = vec3(34.0, 6.0, 34.0);
uniform float density = 0.30;
uniform float radiance = 2.2;
uniform float motion_speed = 0.035;
uniform float time_offset = 0.0;
varying vec3 world_vertex;
varying flat vec3 volume_center;

void vertex() {
	world_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	volume_center = MODEL_MATRIX[3].xyz;
}

vec2 intersect_box(vec3 origin, vec3 direction) {
	vec3 reciprocal = 1.0 / (sign(direction + vec3(1e-7)) * max(abs(direction), vec3(1e-6)));
	vec3 a = (-half_size - origin) * reciprocal;
	vec3 b = (half_size - origin) * reciprocal;
	vec3 near_hit = min(a,b), far_hit = max(a,b);
	return vec2(max(max(near_hit.x,near_hit.y),near_hit.z), min(min(far_hit.x,far_hit.y),far_hit.z));
}

void fragment() {
	// Integração frontal de um campo contínuo de densidade.
	vec3 origin = CAMERA_POSITION_WORLD - volume_center;
	vec3 direction = normalize(world_vertex - CAMERA_POSITION_WORLD);
	vec2 hit = intersect_box(origin, direction);
	float start = max(hit.x, 0.0);
	float end = hit.y;
	float depth = textureLod(scene_depth, SCREEN_UV, 0.0).r;
	vec4 opaque_world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	float opaque_distance = dot(opaque_world.xyz / opaque_world.w - CAMERA_POSITION_WORLD, direction);
	end = min(end, opaque_distance);
	if (end <= start) { discard; }
	float step_length = (end - start) / 48.0;
	float transmittance = 1.0;
	vec3 accumulated = vec3(0.0);
	float time = (TIME + time_offset) * motion_speed;
	for (int i = 0; i < 48; i++) {
		vec3 p = origin + direction * (start + (float(i) + 0.5) * step_length);
		vec3 q = p * vec3(0.026,0.037,0.026) + vec3(time * 0.12, -time * 0.10, time * 0.08);
		float warp = textureLod(cloud_noise, q * 0.65 + vec3(0.13,0.47,0.72), 0.0).r;
		float cloud = textureLod(cloud_noise, q + vec3(warp * 0.32,warp * 0.18,-warp * 0.28), 0.0).r;
		float detail = textureLod(cloud_noise, q * 2.15 + vec3(warp * 0.22,0.53,0.17), 0.0).r;
		float rim = exp(-pow((max(abs(p.x),abs(p.z)) - 24.0 + (cloud-0.5)*6.0)/4.2, 2.0));
		float height = exp(-pow((p.y - 1.4 + (warp-0.5)*4.0)/3.1, 2.0));
		// Extinção suave da densidade nas seis faces do volume.
		vec3 boundary = half_size - abs(p);
		float edge_fade = smoothstep(0.0, 2.0, min(min(boundary.x,boundary.y),boundary.z));
		float filaments = pow(clamp(1.0-abs(detail-0.54)*2.0,0.0,1.0), 16.0);
		float sigma = density * rim * height * edge_fade * pow(smoothstep(0.40,0.80,cloud),1.4);
		float opacity = 1.0-exp(-sigma * step_length);
		vec3 color = mix(vec3(0.18,0.018,0.48),vec3(0.04,0.42,1.1),smoothstep(0.30,0.72,cloud));
		accumulated += transmittance * opacity * color * radiance * (0.35+filaments*2.7);
		transmittance *= 1.0-opacity;
		if (transmittance < 0.015) { break; }
	}
	float opacity = 1.0-transmittance;
	ALBEDO = accumulated / max(opacity,0.0001);
	ALPHA = opacity;
}
