shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_disabled, diffuse_burley, specular_schlick_ggx;
uniform sampler2D base_color : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D metallic_map : hint_default_black, filter_linear_mipmap_anisotropic;
uniform sampler2D roughness_map : hint_roughness_r, filter_linear_mipmap_anisotropic;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap_anisotropic;
uniform sampler2D opacity_map : hint_default_white, filter_linear_mipmap_anisotropic;
uniform float fragment_age = 0.0;
void fragment() {
	float mask = texture(opacity_map,UV).r;
	if (mask<0.42) { discard; }
	ALBEDO = texture(base_color,UV).rgb;
	METALLIC = texture(metallic_map,UV).r;
	ROUGHNESS = texture(roughness_map,UV).r;
	NORMAL_MAP = texture(normal_map,UV).rgb;
	ALPHA = (1.0-smoothstep(3.2,5.8,fragment_age))*mask;
}
