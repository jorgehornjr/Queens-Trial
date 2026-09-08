shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D base_color : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D metallic_map : hint_default_black, filter_linear_mipmap_anisotropic;
uniform sampler2D roughness_map : hint_roughness_r, filter_linear_mipmap_anisotropic;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap_anisotropic;
uniform sampler2D opacity_map : hint_default_white, filter_linear_mipmap_anisotropic;

void fragment() {
	vec4 color_sample = texture(base_color, UV);
	ALBEDO = color_sample.rgb;
	METALLIC = texture(metallic_map, UV).r;
	ROUGHNESS = texture(roughness_map, UV).r;
	NORMAL_MAP = texture(normal_map, UV).rgb;
	NORMAL_MAP_DEPTH = 1.0;
	ALPHA = texture(opacity_map, UV).r;
	ALPHA_SCISSOR_THRESHOLD = 0.42;
}
