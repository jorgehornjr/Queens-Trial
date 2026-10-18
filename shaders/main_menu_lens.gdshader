shader_type canvas_item;
render_mode unshaded, blend_add;

uniform vec2 light_uv = vec2(0.75, 0.3);
uniform float strength = 0.0;
uniform float aspect = 1.77778;

void fragment() {
	vec2 point = (SCREEN_UV - light_uv) * vec2(aspect, 1.0);
	float radius = length(point);
	float core = exp(-radius * radius * 12000.0);
	float bloom = exp(-radius * radius * 380.0) * 0.34;
	float haze = exp(-radius * radius * 28.0) * 0.055;
	float streak = exp(-abs(point.y) * 850.0) * exp(-abs(point.x) * 6.0) * 0.23;
	vec3 warm = vec3(1.0, 0.78, 0.45);
	vec3 light = vec3(core) + warm * (bloom + haze + streak);
	COLOR = vec4(light * strength, 1.0);
}
