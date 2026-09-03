shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

uniform sampler2D ring_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 sun_direction = vec3(-1.0, 0.0, 0.0);
uniform vec3 planet_center;
uniform float planet_radius = 1.0;
uniform float opacity = 0.5;
varying vec3 world_position;
void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec4 tex = texture(ring_map, UV);
	vec3 normal_world = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 toward_sun = normalize(sun_direction);
	vec3 rel = world_position - planet_center;
	float along = dot(rel, toward_sun);
	float perpendicular = length(rel - along * toward_sun);
	float lit = along > 0.0 ? 1.0 : smoothstep(planet_radius * 0.97, planet_radius * 1.03, perpendicular);
	ALBEDO = tex.rgb * (0.06 + lit * (0.30 + 0.85 * abs(dot(normal_world, toward_sun))));
	ALPHA = tex.a * opacity;
}
