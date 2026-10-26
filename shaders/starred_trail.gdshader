shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

uniform float reveal : hint_range(0.0, 1.0) = 0.0;
varying float arrival;

void vertex() { arrival = COLOR.a; }

void fragment() {
	float ink = pow(max(0.0, 1.0 - abs(UV.x * 2.0 - 1.0)), 1.8);
	float visible = smoothstep(arrival - 0.018, arrival + 0.04, reveal);
	if (reveal < 0.001) visible = 0.0;
	ALBEDO = vec3(0.72, 0.84, 1.0) * 1.6;
	EMISSION = vec3(0.72, 0.84, 1.0) * 1.6;
	ALPHA = ink * visible * 0.22;
}
