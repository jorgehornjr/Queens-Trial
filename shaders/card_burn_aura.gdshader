shader_type canvas_item;

uniform float burn_progress : hint_range(0.0, 1.0) = 0.0;
uniform float aftermath : hint_range(0.0, 1.0) = 0.0;
uniform float burn_seed = 0.0;
uniform vec2 card_size_px = vec2(300.0, 427.0);
uniform vec2 padding_px = vec2(40.0, 76.0);

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
	vec2 card_uv = (UV * (card_size_px + padding_px * 2.0) - padding_px) / card_size_px;
	float delta = burn_progress - burn_arrival(card_uv);
	float active = smoothstep(0.015, 0.13, burn_progress) * (1.0 - smoothstep(0.91, 1.0, burn_progress));
	float sides = smoothstep(-0.12, 0.02, card_uv.x) * (1.0 - smoothstep(0.98, 1.12, card_uv.x));
	float height_fade = smoothstep(-0.17, -0.07, card_uv.y) * (1.0 - smoothstep(1.07, 1.17, card_uv.y));
	float tongues = noise21(vec2(card_uv.x * 17.0 + TIME * 0.22, card_uv.y * 8.0 - TIME * 1.25) + burn_seed * 3.0);
	tongues = mix(tongues, noise21(vec2(card_uv.x * 41.0 - TIME * 0.34, card_uv.y * 18.0 - TIME * 1.92)), 0.32);
	float flame_band = smoothstep(-0.16, -0.022, delta) * (1.0 - smoothstep(0.008, 0.065, delta));
	float flame = flame_band * smoothstep(0.51, 0.81, tongues) * sides * height_fade * active;
	float halo = flame_band * sides * height_fade * active * 0.047;
	float smoke_noise = noise21(vec2(card_uv.x * 9.0 + TIME * 0.13, card_uv.y * 10.0 + TIME * 0.44) + burn_seed * 5.0);
	float smoke_band = smoothstep(-0.42, -0.12, delta) * (1.0 - smoothstep(-0.01, 0.10, delta));
	float smoke = smoke_band * smoothstep(0.43, 0.79, smoke_noise) * sides * height_fade * active * 0.17;
	float residue_noise = noise21(vec2(card_uv.x * 8.0 + TIME * 0.18, card_uv.y * 8.0 + TIME * 0.32) + burn_seed * 4.0);
	float lift = card_uv.y + aftermath * 0.21 - 0.04;
	float plume_left = exp(-pow((card_uv.x - 0.25 - sin(TIME * 0.64) * 0.035) / 0.14, 2.0) - pow(lift / 0.27, 2.0));
	float plume_middle = exp(-pow((card_uv.x - 0.53 + sin(TIME * 0.51) * 0.047) / 0.17, 2.0) - pow((lift + 0.04) / 0.30, 2.0));
	float plume_right = exp(-pow((card_uv.x - 0.79 - sin(TIME * 0.72) * 0.029) / 0.12, 2.0) - pow((lift - 0.02) / 0.24, 2.0));
	float residue_shape = max(max(plume_left, plume_middle), plume_right);
	smoke += smoothstep(0.72, 0.98, burn_progress) * (1.0 - aftermath) * residue_shape * smoothstep(0.33, 0.74, residue_noise) * sides * height_fade * 0.51;
	float sparks = 0.0;
	for (int i = 0; i < 7; i++) {
		float index = float(i);
		float speed = 0.38 + hash21(vec2(index, burn_seed)) * 0.31;
		float life = fract(TIME * speed + hash21(vec2(index * 3.17, burn_seed + 1.0)));
		float x = hash21(vec2(index * 7.13, burn_seed + 3.0));
		float y = 1.02 - burn_progress * 0.93 - life * 0.27;
		vec2 offset = (card_uv - vec2(x, y)) * card_size_px;
		float streak = exp(-pow(offset.x / 1.8, 2.0) - pow(offset.y / 5.5, 2.0));
		sparks += streak * (1.0 - life) * active * 0.52;
	}
	float fire_alpha = clamp(flame * 0.38 + halo + sparks, 0.0, 0.60);
	float smoke_alpha = clamp(smoke, 0.0, 0.27);
	vec3 fire_color = mix(vec3(0.72, 0.14, 0.025), vec3(1.0, 0.63, 0.20), clamp(flame + sparks, 0.0, 1.0));
	vec3 color = (fire_color * fire_alpha + vec3(0.48, 0.43, 0.40) * smoke_alpha) / max(fire_alpha + smoke_alpha, 0.0001);
	COLOR = vec4(color, clamp(fire_alpha + smoke_alpha, 0.0, 0.68));
}
