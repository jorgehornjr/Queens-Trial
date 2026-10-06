shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never, shadows_disabled;
uniform sampler2D source_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D distortion_texture : filter_linear_mipmap, repeat_enable;
uniform bool textured = true;
uniform bool color_to_alpha = false;
uniform bool distorted = false;
uniform vec4 particle_tint = vec4(0.0);
uniform vec2 uv_scale = vec2(1.0);
uniform vec2 uv_scroll = vec2(0.0);
uniform vec2 distortion_scale = vec2(1.0);
uniform vec2 distortion_scroll = vec2(0.0);

void fragment() {
    vec2 coord = UV * uv_scale + uv_scroll;
    if (distorted) {
        vec2 displacement = texture(distortion_texture, UV2 * distortion_scale + distortion_scroll).rg * 2.0 - 1.0;
        coord += displacement * 0.065;
    }
    vec4 tex = textured ? texture(source_texture, coord) : vec4(1.0);
    float coverage = color_to_alpha ? max(tex.r, max(tex.g, tex.b)) : tex.a;
    vec3 tint = particle_tint.rgb * COLOR.rgb;
    ALBEDO = tint * (textured && !color_to_alpha ? tex.rgb : vec3(1.0));
    EMISSION = ALBEDO * 1.1;
    ALPHA = clamp(coverage * particle_tint.a * COLOR.a, 0.0, 1.0);
}
