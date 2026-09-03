shader_type sky;

uniform sampler2D panorama : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D nebula_mask : filter_linear_mipmap, repeat_enable;
// Panorama colorido usado como máscara de intensidade do fluxo.
uniform sampler2D flow_reference : filter_linear_mipmap, repeat_enable;
uniform float effect_time = 0.0;
uniform bool motion_enabled = true;
uniform float motion_strength : hint_range(0.0, 0.02) = 0.007;
uniform float motion_speed : hint_range(0.0, 3.0) = 1.0;
uniform float core_glow_strength : hint_range(0.0, 3.0) = 1.2;
uniform bool sparkles_enabled = true;
uniform float sparkle_intensity : hint_range(0.0, 20.0) = 10.0;
uniform float sparkle_density : hint_range(0.0, 1.0) = 0.42;

float luminance(vec3 color) {
	return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

vec2 panorama_uv(vec2 uv) {
	// Repetição longitudinal sem descontinuidade das derivadas.
	return vec2(uv.x, clamp(uv.y, 0.0001, 0.9999));
}

vec2 panorama_gradient(vec2 gradient) {
	// Correção da derivada na emenda 1→0 de SKY_COORDS para evitar artefatos de mipmap.
	return vec2(gradient.x - round(gradient.x), gradient.y);
}

vec3 point_detail(vec3 sharp, vec3 blurred) {
	// Separação aproximada entre estrelas neutras e filamentos coloridos em movimento.
	float peak = max(max(sharp.r, sharp.g), sharp.b);
	float neutral = min(min(sharp.r, sharp.g), sharp.b) / max(peak, 0.0001);
	return max(sharp - blurred, vec3(0.0)) * smoothstep(0.25, 0.75, neutral);
}

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec3 occasional_glint(vec2 uv) {
	// Derivadas calculadas antes das ramificações divergentes por célula.
	float radius = max(0.00032, fwidth(uv.y) * 1.5);
	vec2 grid = vec2(128.0, 64.0);
	vec2 cell = floor(uv * grid);
	float seed = hash21(cell);
	vec3 glint = vec3(0.0);
	if (seed > 1.0 - sparkle_density) {
		float period = mix(3.8, 7.0, hash21(cell + 8.7));
		float duration = mix(1.6, 2.8, hash21(cell + 15.2));
		float age = mod(effect_time + hash21(cell + 3.1) * period, period);
		if (age < duration) {
			float pulse = sin(PI * age / duration);
			pulse *= pulse;
			vec2 center = vec2(hash21(cell + 1.3), hash21(cell + 7.9)) * 0.6 + 0.2;
			vec2 delta = (fract(uv * grid) - center) / grid;
			delta.x *= max(0.1, 2.0 * sin(uv.y * PI));
			vec2 d = delta / radius;
			float point = exp(-dot(d, d) * 1.5);
			float rays = exp(-abs(d.x) * 0.65 - abs(d.y) * 6.0)
				+ 0.35 * exp(-abs(d.y) * 1.0 - abs(d.x) * 6.0);
			float poles = smoothstep(0.015, 0.09, uv.y) * smoothstep(0.015, 0.09, 1.0 - uv.y);
			vec3 tint = mix(vec3(0.58, 0.78, 1.0), vec3(1.0, 0.91, 0.78), hash21(cell + 23.0));
			glint = tint * (point + rays * 0.22) * pulse * sparkle_intensity * poles;
		}
	}
	return glint;
}

void sky() {
	vec2 uv = SKY_COORDS;
	vec3 base = textureGrad(panorama, uv,
		panorama_gradient(dFdx(uv)), panorama_gradient(dFdy(uv))).rgb;
	vec3 color = base;
	if (!AT_CUBEMAP_PASS && motion_enabled) {
		float mask = smoothstep(0.08, 0.65, textureLod(nebula_mask, uv, 2.0).r);
		float field = smoothstep(0.0, 0.12, luminance(textureLod(flow_reference, uv, 3.0).rgb));
		float t = effect_time * motion_speed;
		vec2 flow = vec2(
			sin(dot(EYEDIR, vec3(4.1, 2.7, 3.2)) + t * 0.075),
			cos(dot(EYEDIR, vec3(2.3, 4.6, -3.1)) + t * 0.057)
		);
		flow += 0.28 * vec2(
			cos(dot(EYEDIR, vec3(8.2, -3.0, 5.1)) - t * 0.043),
			sin(dot(EYEDIR, vec3(-5.4, 7.3, 2.0)) + t * 0.035)
		);
		float poles = smoothstep(0.0, 0.12, uv.y) * smoothstep(0.0, 0.12, 1.0 - uv.y);
		vec2 warped_uv = panorama_uv(uv + flow * motion_strength * mask * poles * (0.7 + 0.3 * field));
		vec3 warped = textureGrad(panorama, warped_uv,
			panorama_gradient(dFdx(warped_uv)), panorama_gradient(dFdy(warped_uv))).rgb;
		vec3 base_stars = point_detail(base, textureLod(panorama, uv, 2.0).rgb);
		vec3 moving_stars = point_detail(warped, textureLod(panorama, warped_uv, 2.0).rgb);
		color = mix(base - base_stars, warped - moving_stars, mask * 0.88) + base_stars;
	}
	// Energia adicional restrita aos núcleos HDR.
	float core = smoothstep(0.65, 3.5, luminance(color));
	color *= 1.0 + core * core_glow_strength;
	if (AT_CUBEMAP_PASS) {
		// IBL estável, sem os lampejos e filamentos da passagem visual.
		color = min(color, vec3(8.0));
	} else if (sparkles_enabled) {
		color += occasional_glint(uv);
	}
	COLOR = max(color, vec3(0.0));
}
