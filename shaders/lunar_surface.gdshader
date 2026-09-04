shader_type spatial;
render_mode unshaded;

uniform sampler2D surface_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D relief_map : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool has_relief = false;
uniform vec4 surface_tint : source_color = vec4(1.0);
uniform vec3 sun_direction = vec3(-1.0, 0.0, 0.0);
uniform float exposure : hint_range(0.5, 4.0) = 1.8;
uniform float relief_strength : hint_range(0.0, 1.0) = 0.55;
uniform float highlight_strength : hint_range(0.0, 12.0) = 5.0;

void fragment() {
	vec3 color = texture(surface_map, UV).rgb * surface_tint.rgb;
	vec3 broad_color = textureLod(surface_map, UV, 4.0).rgb * surface_tint.rgb;
	vec3 geometric_normal = normalize(NORMAL);
	vec3 normal_view = geometric_normal;
	if (has_relief) {
		vec3 bump = texture(relief_map, UV).xyz * 2.0 - 1.0;
		bump.xy *= relief_strength;
		bump.z = sqrt(max(0.001, 1.0 - dot(bump.xy, bump.xy)));
		normal_view = normalize(mat3(normalize(TANGENT), normalize(BINORMAL), geometric_normal) * bump);
	}
	vec3 sun = normalize(sun_direction);
	vec3 normal_world = normalize((INV_VIEW_MATRIX * vec4(normal_view, 0.0)).xyz);
	vec3 geometric_world = normalize((INV_VIEW_MATRIX * vec4(geometric_normal, 0.0)).xyz);
	float daylight = max(dot(normal_world, sun), 0.0);
	float light_gate = smoothstep(0.02, 0.48, dot(geometric_world, sun));
	// Máscara de realces nos detalhes claros das crateras, com contraste dos mares.
	float luminance = dot(color, vec3(0.2126, 0.7152, 0.0722));
	float broad_luminance = dot(broad_color, vec3(0.2126, 0.7152, 0.0722));
	float highlands = smoothstep(0.20, 0.65, luminance);
	float crater_rays = smoothstep(0.02, 0.15, luminance - broad_luminance);
	float face_gate = smoothstep(0.05, 0.35, dot(geometric_normal, normalize(VIEW)));
	float highlights = highlands * (0.05 + crater_rays * crater_rays) * light_gate * face_gate;
	ALBEDO = color * (vec3(0.014, 0.018, 0.028) + vec3(daylight * exposure));
	ALBEDO += vec3(highlights * highlight_strength);
}
