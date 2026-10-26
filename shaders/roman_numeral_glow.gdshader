shader_type canvas_item;
render_mode unshaded, blend_premul_alpha;
uniform float effect_time = 0.0;
uniform sampler2D halo_texture : filter_linear, repeat_disable;
uniform float glow_strength = 1.65;
varying vec4 numeral_tint;

void vertex() { numeral_tint = COLOR; }

void fragment() {
	vec4 ink = texture(TEXTURE, UV);
	vec4 halo = texture(halo_texture, UV);
	float breath = 0.88 + 0.12 * sin(effect_time * 0.8);
	vec3 color = ink.rgb / max(ink.a, 0.001);
	vec3 pearl = mix(color, vec3(1.0), 0.18);
	vec3 radiance = halo.rgb * glow_strength * breath * (1.0 - ink.a * 0.75);
	// O halo soma luz sem cobrir o cenário com uma silhueta translúcida.
	COLOR = vec4(pearl * ink.a + radiance, ink.a) * vec4(numeral_tint.rgb * numeral_tint.a, numeral_tint.a);
}
