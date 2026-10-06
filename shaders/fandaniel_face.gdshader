shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never, shadows_disabled;

uniform sampler2D shape_map : filter_linear_mipmap, repeat_disable;
uniform sampler2D edge_map : filter_linear_mipmap, repeat_disable;
uniform sampler2D glow_map : filter_linear_mipmap, repeat_disable;
uniform float reveal : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    // The game's glyph textures contain one half and mirror at the face center.
    vec2 coord = vec2((1.0 - abs(UV.x * 2.0 - 1.0)), UV.y);
    float shape = texture(shape_map, coord).r;
    float edge = texture(edge_map, coord).r;
    float glow = texture(glow_map, coord).r;
    float pulse = 0.96 + 0.04 * sin(TIME * 1.2);
    vec3 red = mix(vec3(0.35, 0.002, 0.001), vec3(1.0, 0.085, 0.02), edge);
    ALBEDO = red;
    EMISSION = red * (0.7 + 2.2 * edge) * pulse + vec3(0.8, 0.006, 0.001) * glow * 0.45;
    ALPHA = clamp(shape * 0.95 + glow * 0.30, 0.0, 1.0) * reveal;
}
