shader_type canvas_item;
render_mode unshaded;

uniform sampler2D title_fields : filter_linear, repeat_disable;
uniform sampler2D turbulence : filter_linear, repeat_enable;
uniform float elapsed = 0.0;

float flow(vec2 p) {
	vec4 n = texture(turbulence, p);
	return dot(n, vec4(0.30, 0.30, 0.25, 0.15));
}

float broad_flow(vec2 p) {
	return texture(turbulence, p).r;
}

float burn_time(vec2 p) {
	return 3.20 + (p.x - 0.20) * 1.65 + (flow(p * 3.7) - 0.5) * 0.32;
}

vec3 temperature(float value) {
	vec3 col = mix(vec3(0.045, 0.003, 0.0005), vec3(0.65, 0.10, 0.007), smoothstep(0.0, 0.35, value));
	col = mix(col, vec3(1.0, 0.40, 0.03), smoothstep(0.32, 0.60, value));
	col = mix(col, vec3(1.0, 0.78, 0.31), smoothstep(0.56, 0.82, value));
	return mix(col, vec3(1.0, 0.98, 0.82), smoothstep(0.78, 1.0, value));
}

void fragment() {
	vec2 uv = UV;
	vec2 px = uv * vec2(1440.0, 800.0);
	float time = elapsed;
	vec2 coarse = px / vec2(1200.0, 950.0) + vec2(0.0, time * 0.16);
	vec2 warp = vec2(broad_flow(coarse), broad_flow(coarse + vec2(0.31, 0.72))) - 0.5;
	float lift = 1.0 - smoothstep(0.15, 0.60, uv.y);
	vec2 advected = px + warp * vec2(36.0 + lift * 40.0, 16.0 + lift * 20.0);
	vec2 moving = advected / vec2(280.0, 600.0) + vec2(time * 0.015, time * 0.47);
	vec2 curls = vec2(broad_flow(moving), broad_flow(moving + vec2(0.47, 0.13))) - 0.5;
	vec2 q = uv + (warp * vec2(50.0, 15.0) + curls * vec2(20.0, 10.0)) / vec2(1440.0, 800.0);
	float plume = texture(title_fields, q).g;
	float rise = max(-log(max(plume, 0.001)) * 200.0, 0.0);
	float arrival = smoothstep(0.05, 0.72, time - rise / 650.0);
	float fuel = 1.0 - smoothstep(-0.12, 0.27, time - burn_time(q) - rise / 260.0);
	float n = smoothstep(0.24, 0.76, flow(moving + curls * 0.035));
	vec3 emitted = vec3(0.0);
	float transmission = 1.0;
	for (int slice = 0; slice < 7; slice++) {
		float z = float(slice) / 6.0 - 0.5;
		vec2 plane = moving + vec2(z * 0.37, z * 0.81);
		vec2 twist = vec2(broad_flow(plane + 0.27), broad_flow(plane + 0.65)) - 0.5;
		float volume = texture(title_fields, q + vec2(z * 0.010, z * 0.009)).g;
		float cloud = flow(plane + twist * 0.035) * 0.72;
		cloud += flow(plane * 2.13 + twist * 0.051) * 0.20;
		cloud += flow(plane * 4.17 + twist * 0.073) * 0.08;
		cloud = smoothstep(0.24, 0.76, cloud);
		float fine = texture(turbulence, plane * vec2(2.4, 1.8) + twist * 0.04).a;
		float density = volume * (1.20 - z * z * 0.62) * arrival * fuel - (0.14 + cloud * 0.97);
		density += (fine - 0.5) * 0.20;
		float amount = 1.0 - exp(-max(density, 0.0) * 2.4);
		float thermal = clamp(density * 1.75 + volume * 0.26 + (fine - 0.5) * 0.12, 0.0, 1.0);
		emitted += transmission * amount * temperature(thermal);
		transmission *= 1.0 - amount;
	}
	float fire_alpha = 1.0 - transmission;
	vec3 fire = emitted / max(fire_alpha, 0.001);
	vec4 fields = texture(title_fields, uv);
	float distance = (fields.b - 0.5) * 96.0;
	float delta = time - burn_time(uv);
	float intact = 1.0 - smoothstep(-0.025, 0.07, delta);
	float reveal = smoothstep(0.17, 0.85, time);
	float ink = fields.r * intact * reveal;
	float edge = exp(-abs(distance) / 2.3) * reveal * intact;
	float veins = smoothstep(0.54, 0.74, flow(moving * 1.3 + curls * 0.5));
	float face_light = smoothstep(0.49, 0.67, uv.y) * 0.15 + veins * 0.065;
	vec3 face = vec3(0.009, 0.003, 0.002) + vec3(0.43, 0.038, 0.003) * face_light;
	face += vec3(0.95, 0.21, 0.007) * edge * (0.28 + n * 0.65);
	float front = exp(-abs(delta + 0.02) * 17.0);
	face = mix(face, vec3(1.0, 0.83, 0.31), front);
	vec3 color = mix(fire, face, ink);
	float alpha = max(fire_alpha, ink);

	float rim = exp(-abs(distance - 1.8) / 2.5) * intact * reveal;
	color += vec3(0.60, 0.09, 0.001) * rim * (1.0 - ink);
	alpha = max(alpha, rim * 0.80);
	float envelope = smoothstep(0.0, 0.18, time) * (1.0 - smoothstep(4.7, 5.45, time));
	envelope *= smoothstep(0.025, 0.10, uv.y);
	COLOR = vec4(color, alpha * envelope);
}
