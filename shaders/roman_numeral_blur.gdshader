shader_type canvas_item;
render_mode unshaded, blend_premul_alpha;
uniform vec2 sample_step;

void fragment() {
	vec4 light = vec4(0.0);
	float total = 0.0;
	for (int i = -8; i <= 8; i++) {
		float weight = exp(-float(i * i) / 21.78);
		light += texture(TEXTURE, UV + sample_step * float(i)) * weight;
		total += weight;
	}
	COLOR = light / total;
}
