shader_type spatial;
render_mode unshaded;

uniform sampler2D surface_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D relief_map : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool has_relief = false;
uniform vec4 surface_tint : source_color = vec4(1.0);
uniform vec3 sun_direction = vec3(-1.0, 0.0, 0.0);
uniform float exposure = 1.25;
uniform float relief_strength = 0.55;
uniform bool solar_emitter = false;

void fragment() {
	vec3 color = texture(surface_map, UV).rgb * surface_tint.rgb;
	vec3 normal_view = normalize(NORMAL);
	if (has_relief) {
		vec3 bump = texture(relief_map, UV).xyz * 2.0 - 1.0;
		bump.xy *= relief_strength;
		bump.z = sqrt(max(0.001, 1.0 - dot(bump.xy, bump.xy)));
		normal_view = normalize(mat3(normalize(TANGENT), normalize(BINORMAL), normalize(NORMAL)) * bump);
	}
	vec3 normal_world = normalize((INV_VIEW_MATRIX * vec4(normal_view, 0.0)).xyz);
	float daylight = max(dot(normal_world, normalize(sun_direction)), 0.0);
	// Luz de preenchimento discreta; terminador definido pela direção do Sol.
	ALBEDO = solar_emitter ? color * 3.3 : color * (vec3(0.014, 0.018, 0.028) + vec3(1.0, 0.96, 0.90) * daylight * exposure);
}
