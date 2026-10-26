shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;

uniform float reveal : hint_range(0.0, 1.0) = 1.0;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float phase = 0.0;
uniform float aspect = 4.0;

void fragment() {
	float x = UV.x * 2.0 - 1.0;
	float y = UV.y * aspect;
	float t = TIME * 2.4 + phase;
	float bend = sin(y * 16.0 - t) * 0.035 + sin(y * 37.0 + t * 1.3) * 0.016;
	float d = abs(x - bend);
	float core = exp(-d * 125.0);
	float plasma = exp(-d * 20.0) * 0.65;
	float mist = exp(-d * 4.8) * (0.16 + 0.06 * sin(y * 12.0 - t));
	float filament = exp(-abs(x - sin(y * 11.0 - t * 0.8) * 0.22) * 85.0) * 0.25;
	float front = 1.0 - smoothstep(progress - 0.05, progress + 0.03, UV.y);
	float shock = exp(-abs(UV.y - progress) * 95.0) * exp(-abs(x) * 2.8);
	float caps = smoothstep(0.0, 0.04, UV.y) * (1.0 - smoothstep(0.94, 1.0, UV.y));
	float light = ((core + plasma + mist + filament) * front + shock * 0.8) * caps;
	vec3 radiance = mix(vec3(0.72, 0.34, 0.055), vec3(1.65, 1.08, 0.38), core);
	ALBEDO = radiance * 2.0;
	EMISSION = radiance * 2.0;
	ALPHA = clamp(light * reveal, 0.0, 1.0);
}
