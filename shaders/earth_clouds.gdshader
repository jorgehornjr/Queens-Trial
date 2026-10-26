shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_back;

uniform sampler2D cloud_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 cloud_tint : source_color = vec4(0.84, 0.92, 1.0, 1.0);
uniform float cloud_opacity : hint_range(0.0, 1.0) = 0.82;
uniform float cloud_emission : hint_range(0.0, 1.0) = 0.08;

void fragment() {
	vec4 clouds = texture(cloud_texture, UV);
	ALBEDO = cloud_tint.rgb;
	ROUGHNESS = 0.95;
	EMISSION = cloud_tint.rgb * clouds.a * cloud_emission;
	ALPHA = clouds.a * cloud_opacity;
}
