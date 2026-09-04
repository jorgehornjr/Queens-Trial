shader_type spatial;
render_mode blend_mix, depth_draw_never, ambient_light_disabled;

uniform sampler2D cloud_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;

void fragment() {
	vec4 clouds = texture(cloud_map, UV);
	float luminance = dot(clouds.rgb, vec3(0.2126, 0.7152, 0.0722));
	// Transparência progressiva das nuvens nos ângulos rasantes.
	float limb = smoothstep(0.03, 0.22, max(dot(normalize(NORMAL), normalize(VIEW)), 0.0));
	ALBEDO = clouds.rgb;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	ALPHA = clouds.a * 0.56 * smoothstep(0.015, 0.15, luminance) * limb;
}
