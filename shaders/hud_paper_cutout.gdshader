shader_type canvas_item;
render_mode unshaded;

float ink_alpha(vec4 sample_color) {
	return sample_color.a * (1.0 - smoothstep(0.95, 0.995, min(sample_color.r, min(sample_color.g, sample_color.b))));
}
void fragment() {
	vec4 source = texture(TEXTURE, UV);
	COLOR = vec4(source.rgb, ink_alpha(source));
}
