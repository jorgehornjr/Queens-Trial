shader_type spatial;
render_mode blend_add, unshaded, cull_front, depth_draw_never;

uniform vec4 atmosphere_color : source_color = vec4(0.16, 0.62, 1.0, 0.72);
uniform float rim_power : hint_range(0.5, 8.0) = 2.45;
uniform float glow_strength : hint_range(0.0, 6.0) = 2.2;

void fragment() {
	float fresnel = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), rim_power);
	ALBEDO = atmosphere_color.rgb;
	EMISSION = atmosphere_color.rgb * fresnel * glow_strength;
	ALPHA = fresnel * atmosphere_color.a;
}
