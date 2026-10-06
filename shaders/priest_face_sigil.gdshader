shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never, shadows_disabled;

uniform sampler2D sigil : source_color, filter_linear_mipmap, repeat_disable;
uniform bool halo = false;
uniform float energy = 1.0;

void fragment() {
    float shape = texture(sigil, UV).a;
    vec2 pixel = vec2(1.0 / 512.0, 1.0 / 768.0);
    float near_shape = 0.0;
    float haze = 0.0;
    for (int i = 0; i < 12; i++) {
        float angle = float(i) * 6.2831853 / 12.0;
        vec2 dir = vec2(cos(angle), sin(angle));
        near_shape += texture(sigil, UV + dir * pixel * 2.5).a / 12.0;
        haze += texture(sigil, UV + dir * pixel * 10.0).a / 12.0;
    }
    float pulse = 0.96 + 0.04 * sin(TIME * 1.8);
    if (halo) {
        ALBEDO = vec3(0.72, 0.004, 0.001);
        EMISSION = vec3(2.2, 0.015, 0.002) * energy * pulse;
        ALPHA = clamp(near_shape * 0.22 + haze * 0.13, 0.0, 0.35);
    } else {
        float edge = clamp((1.0 - near_shape) * 2.0, 0.0, 1.0);
        vec3 crimson = mix(vec3(0.38, 0.002, 0.003), vec3(1.0, 0.075, 0.008), edge);
        ALBEDO = crimson;
        EMISSION = crimson * mix(0.72, 2.1, edge) * energy * pulse;
        ALPHA = shape * 0.97;
    }
}
