shader_type canvas_item;
render_mode unshaded, blend_add;

uniform sampler2D glyph_mask : filter_linear;
uniform float elapsed = -1.0;
uniform vec2 text_bounds = vec2(0.3, 0.7);
uniform vec2 mask_size = vec2(880.0, 210.0);
varying float opacity;
varying float warmth;
#include "res://shaders/edict_dust_common.gdshaderinc"

void vertex() {
	vec2 source_uv = INSTANCE_CUSTOM.xy;
	float seed = INSTANCE_CUSTOM.z;
	float born = dust_birth(source_uv, text_bounds, mask_size);
	float age = max(0.0, elapsed - born);
	float life = 0.85 + seed * 0.30;
	float ink = texture(glyph_mask, source_uv).a;
	opacity = ink * smoothstep(0.0, 0.035, age) * (1.0 - smoothstep(life * 0.35, life, age));
	warmth = seed;
	VERTEX *= mix(0.45, 1.15, INSTANCE_CUSTOM.w) * (1.0 - min(age / life, 1.0) * 0.55);
	float wind = (150.0 + seed * 145.0) * age + 190.0 * age * age;
	float curl = sin(age * 7.0 + source_uv.y * 16.0 + seed * 2.0) - sin(source_uv.y * 16.0 + seed * 2.0);
	VERTEX += vec2(wind, curl * age * 40.0 - age * 35.0 + (INSTANCE_CUSTOM.w - 0.5) * age * 100.0);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float soft_grain = exp(-dot(p, p) * 4.5) * (1.0 - smoothstep(0.6, 1.0, length(p)));
	COLOR = vec4(mix(vec3(0.58, 0.29, 0.045), vec3(1.0, 0.78, 0.25), warmth), soft_grain * opacity * 0.9);
}
