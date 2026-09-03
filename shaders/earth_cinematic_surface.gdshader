shader_type spatial;
render_mode ambient_light_disabled, diffuse_burley, specular_schlick_ggx;

uniform sampler2D surface_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D relief_map : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D roughness_map : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D city_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 sun_direction = vec3(-0.97, 0.12, -0.2);
uniform float city_energy = 1.0;
varying vec3 world_normal;

void vertex() {
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	vec3 surface = texture(surface_map, UV).rgb;
	float sunlight = dot(normalize(world_normal), normalize(sun_direction));
	float night = 1.0 - smoothstep(-0.12, 0.15, sunlight);
	ALBEDO = surface * 0.82;
	NORMAL_MAP = texture(relief_map, UV).rgb;
	NORMAL_MAP_DEPTH = 0.8;
	ROUGHNESS = clamp(texture(roughness_map, UV).g, 0.22, 1.0);
	METALLIC = 0.0;
	SPECULAR = 0.5;
	// Luzes noturnas limitadas pelo terminador no espaço global.
	EMISSION = texture(city_map, UV).rgb * city_energy * night
		+ surface * vec3(0.002, 0.004, 0.008);
}
