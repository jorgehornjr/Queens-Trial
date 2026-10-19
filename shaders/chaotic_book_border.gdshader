shader_type canvas_item;
render_mode unshaded;
uniform sampler2D turbulence : filter_linear, repeat_enable;
uniform float elapsed = 0.0;
uniform float strength = 1.0;

float field(vec2 p) {
	vec4 n = texture(turbulence, p);
	return dot(n, vec4(0.30, 0.30, 0.25, 0.15));
}
vec3 heat(float density) {
	vec3 color = mix(vec3(0.13, 0.004, 0.001), vec3(0.95, 0.12, 0.008), smoothstep(0.0, 0.45, density));
	color = mix(color, vec3(1.0, 0.59, 0.08), smoothstep(0.35, 0.8, density));
	return mix(color, vec3(1.0, 0.91, 0.53), smoothstep(0.80, 1.0, density));
}
void fragment() {
	vec2 p = UV * vec2(1728.0, 1195.0) - vec2(64.0);
	vec2 q = abs(p - vec2(800.0, 533.5)) - vec2(748.0, 495.0);
	float distance = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0);
	vec2 moving = p / vec2(160.0, 240.0) + vec2(elapsed * 0.025, elapsed * 0.43);
	vec2 curl = vec2(field(moving), field(moving + vec2(0.51, 0.29))) - 0.5;
	float envelope = exp(-max(distance + curl.x * 32.0, 0.0) / 28.0);
	float patches = 0.65 + field(p / vec2(270.0, 330.0) + vec2(elapsed * 0.07, -elapsed * 0.14)) * 0.4;
	float transmission = 1.0;
	vec3 light = vec3(0.0);
	for (int slice = 0; slice < 5; slice++) {
		vec2 plane = moving + vec2(float(slice) * 0.37, float(slice) * 0.19);
		float cloud = field(plane + curl * 0.18) * 0.75 + field(plane * 2.17) * 0.25;
		float fine = texture(turbulence, plane * 3.7 + curl * 0.12).a;
		float density = max(envelope * patches - cloud * 0.96 - 0.12 + (fine - 0.5) * 0.12, 0.0);
		float amount = 1.0 - exp(-density * 2.4);
		light += transmission * amount * heat(clamp(density * 1.8 + envelope * 0.12, 0.0, 1.0));
		transmission *= 1.0 - amount;
	}
	float alpha = (1.0 - transmission) * smoothstep(-16.0, -2.0, distance);
	alpha *= 1.0 - smoothstep(44.0, 63.0, distance);
	COLOR = vec4(light / max(1.0 - transmission, 0.001), alpha * strength);
}
