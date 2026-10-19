shader_type canvas_item;
render_mode unshaded, blend_premul_alpha;
uniform sampler2D combustion : filter_linear, repeat_disable;

vec3 light_at(vec2 uv) {
	vec4 flame = texture(combustion, uv);
	float bright = max(max(flame.r, flame.g), flame.b);
	return flame.rgb * smoothstep(0.30, 0.82, bright);
}

void fragment() {
	vec2 px = vec2(1.0 / 1440.0, 1.0 / 800.0);
	vec3 glow = vec3(0.0);
	for (int j = 0; j < 12; j++) {
		float angle = float(j) * 2.399963;
		vec2 direction = vec2(cos(angle), sin(angle));
		glow += light_at(UV + direction * px * 5.0) * 0.020;
		glow += light_at(UV + direction * px * 17.0) * 0.014;
		glow += light_at(UV + direction * px * 43.0) * 0.007;
	}
	vec4 base = texture(combustion, UV);
	float ga = max(max(glow.r, glow.g), glow.b);

	vec3 premult = base.rgb + glow * 0.72;
	float alpha = clamp(base.a + ga * (1.0 - base.a), 0.0, 1.0);
	COLOR = vec4(premult, alpha);
}
