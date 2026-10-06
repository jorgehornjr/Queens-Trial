shader_type canvas_item;
render_mode unshaded, blend_add;

void fragment() {
	vec2 p = (UV - vec2(0.5)) * vec2(1.12, 0.92);
	float radius = length(p);
	float angle = atan(p.y, p.x);
	float breathe = 0.5 + 0.5 * sin(TIME * 1.7);
	float mist = exp(-pow((radius - 0.43) * 14.0, 2.0));
	float drift = 0.42 + 0.58 * pow(0.5 + 0.5 * sin(angle * 3.0 - TIME * 0.9 + radius * 12.0), 3.0);
	float filament_radius = 0.46 + sin(angle * 4.0 + TIME * 0.8) * 0.016;
	float filament = exp(-pow((radius - filament_radius) * 230.0, 2.0));
	float arc = pow(0.5 + 0.5 * cos(angle * 2.0 - TIME * 1.2), 12.0);
	float light = mist * drift * (0.11 + breathe * 0.055) + filament * arc * 0.22;
	float edges = smoothstep(0.0, 0.12, UV.x) * smoothstep(0.0, 0.12, UV.y) * smoothstep(0.0, 0.12, 1.0 - UV.x) * smoothstep(0.0, 0.12, 1.0 - UV.y);
	COLOR = vec4(mix(vec3(0.24, 0.12, 0.58), vec3(0.45, 0.38, 0.82), arc), light * edges) * COLOR;
}
