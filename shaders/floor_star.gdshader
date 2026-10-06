shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

uniform sampler2D glyph : filter_linear_mipmap, repeat_disable;
uniform vec4 tint : source_color = vec4(0.78, 0.87, 1.0, 1.0);
uniform float energy = 1.85;
uniform float reveal : hint_range(0.0, 1.0) = 1.0;
varying float arrival;

void vertex() { arrival = COLOR.a; }

void fragment() {
	float ink = texture(glyph, UV).a;
	float visible = smoothstep(arrival - 0.025, arrival + 0.025, reveal);
	if (reveal < 0.001) visible = 0.0;
	ALBEDO = tint.rgb * energy;
	EMISSION = tint.rgb * energy;
	ALPHA = ink * visible * tint.a;
}
