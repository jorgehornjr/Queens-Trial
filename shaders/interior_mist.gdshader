shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;

uniform vec4 tint : source_color = vec4(0.12, 1.0, 0.4, 1.0);
uniform float reveal : hint_range(0.0, 1.0) = 1.0;
uniform float phase = 0.0;
uniform float layer_strength = 0.13;
uniform sampler2D cloud_field : filter_linear_mipmap, repeat_enable;

void fragment() {
	float t = TIME * 0.17 + phase;
	vec2 p = UV * 2.0 - 1.0;
	vec2 fade = 1.0 - smoothstep(vec2(0.45), vec2(0.94), abs(p));
	float mask = fade.x * fade.y;
	vec2 drift = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8)) * UV * 0.8 + vec2(t * 0.09, -t * 0.12);
	vec2 warp = vec2(texture(cloud_field, drift + t * 0.04).r, texture(cloud_field, drift + 0.43).r);
	float vapor = texture(cloud_field, drift + warp * 0.20).r * 0.68;
	vapor += texture(cloud_field, drift * 1.83 - warp * 0.12 + 0.71).r * 0.32;
	float wisp = smoothstep(0.26, 0.73, vapor);
	// Low radiance and soft opacity: no luminous core inside the marble tile.
	ALBEDO = tint.rgb * 0.82;
	EMISSION = ALBEDO;
	ALPHA = wisp * mask * layer_strength * tint.a * reveal;
}
