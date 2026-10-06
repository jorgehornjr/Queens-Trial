shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D base_color : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D metallic_map : hint_default_black, filter_linear_mipmap_anisotropic;
uniform sampler2D roughness_map : hint_roughness_r, filter_linear_mipmap_anisotropic;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap_anisotropic;
uniform sampler2D opacity_map : hint_default_white, filter_linear_mipmap_anisotropic;
uniform float ritual_reveal : hint_range(0.0, 1.0) = 1.0;

float ritual_hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
float ritual_noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f*f*(3.0-2.0*f);
	return mix(mix(ritual_hash(i), ritual_hash(i+vec2(1,0)), f.x),
		mix(ritual_hash(i+vec2(0,1)), ritual_hash(i+vec2(1,1)), f.x), f.y);
}

void fragment() {
	float pattern = ritual_noise(UV * 9.0) * 0.65 + UV.y * 0.35;
	if (ritual_reveal < 0.999 && (ritual_reveal <= 0.001 || pattern > ritual_reveal)) { discard; }
	vec4 color_sample = texture(base_color, UV);
	ALBEDO = color_sample.rgb;
	METALLIC = texture(metallic_map, UV).r;
	ROUGHNESS = texture(roughness_map, UV).r;
	NORMAL_MAP = texture(normal_map, UV).rgb;
	NORMAL_MAP_DEPTH = 1.0;
	ALPHA = texture(opacity_map, UV).r;
	ALPHA_SCISSOR_THRESHOLD = 0.42;
	if (ritual_reveal < 0.999) {
		EMISSION = vec3(0.38, 0.62, 1.0) * (1.0 - smoothstep(0.0, 0.08, ritual_reveal - pattern)) * 3.0;
	}
}
