shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

uniform sampler2D glyph : filter_linear_mipmap, repeat_disable;
uniform vec4 tint : source_color = vec4(1.0, 0.84, 0.53, 1.0);
uniform float energy = 2.4;
uniform float glow_strength : hint_range(0.0, 1.0) = 1.0;
uniform float reveal : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 source = texture(glyph, UV);
	// Use the supplied white silhouette exactly; its blue backdrop is not ink.
	float ink = smoothstep(0.19, 0.93, min(source.r, min(source.g, source.b))) * source.a;
	ALBEDO = tint.rgb * energy;
	EMISSION = tint.rgb * energy;
	ALPHA = ink * reveal * glow_strength;
}
