shader_type canvas_item;
render_mode unshaded;

uniform float effect_time = 0.0;
uniform float glow_strength = 1.25;
varying vec4 vertex_tint;

void vertex() { vertex_tint = COLOR; }

void fragment() {
	float ink = texture(TEXTURE, UV).a;
	vec2 step_size = TEXTURE_PIXEL_SIZE * 7.0;
	float halo = ink * 0.16;
	for (int i = 0; i < 12; i++) {
		float angle = float(i) * 6.2831853 / 12.0;
		vec2 direction = vec2(cos(angle), sin(angle));
		halo += texture(TEXTURE, UV + direction * step_size).a * 0.043;
		halo += texture(TEXTURE, UV + direction * step_size * 2.2).a * 0.021;
		halo += texture(TEXTURE, UV + direction * step_size * 3.5).a * 0.006;
	}
	float breathing = 0.94 + 0.06 * sin(effect_time * 0.8);
	float alpha = clamp(ink * 0.94 + halo * glow_strength * breathing * (1.0 - ink), 0.0, 1.0);
	vec3 pearl = mix(vec3(0.70, 0.85, 1.0), vec3(1.0), ink);
	COLOR = vec4(pearl, alpha) * vertex_tint;
}
